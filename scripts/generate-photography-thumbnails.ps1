[CmdletBinding()]
param(
  [ValidateRange(1, 100)]
  [int]$Quality = 82,

  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$dataFile = Join-Path $repoRoot "_data\photography.yml"
$sourceRoot = (Resolve-Path (Join-Path $repoRoot "assets\img\photography")).Path
$thumbnailRoot = Join-Path $sourceRoot "thumbnails"
$targetWidths = @(800, 1400)

$cwebpCommand = Get-Command "cwebp" -ErrorAction SilentlyContinue
if (-not $cwebpCommand) {
  throw "cwebp was not found. Install WebP tools or add cwebp to PATH."
}
$cwebp = $cwebpCommand.Source

function Get-ExifOrientation {
  param([System.Drawing.Image]$Image)

  if ($Image.PropertyIdList -notcontains 274) {
    return 1
  }

  $property = $Image.GetPropertyItem(274)
  return [BitConverter]::ToUInt16($property.Value, 0)
}

function Set-ExifOrientation {
  param(
    [System.Drawing.Image]$Image,
    [int]$Orientation
  )

  switch ($Orientation) {
    2 { $Image.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
    3 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
    4 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
    5 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
    6 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
    7 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
    8 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
  }
}

function New-ResizedBitmap {
  param(
    [System.Drawing.Image]$Image,
    [int]$TargetWidth
  )

  $targetHeight = [Math]::Max(1, [int][Math]::Round($Image.Height * $TargetWidth / $Image.Width))
  $bitmap = [System.Drawing.Bitmap]::new(
    $TargetWidth,
    $targetHeight,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
  )
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

  try {
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($Image, 0, 0, $TargetWidth, $targetHeight)
  }
  finally {
    $graphics.Dispose()
  }

  return $bitmap
}

$photoUrls = Select-String -LiteralPath $dataFile -Pattern '^\s*-\s+image:\s*(.+?)\s*$' |
  ForEach-Object { $_.Matches[0].Groups[1].Value.Trim().Trim('"').Trim("'") } |
  Sort-Object -Unique

if (-not $photoUrls) {
  throw "No photography image paths were found in $dataFile."
}

$generated = 0
$skipped = 0

foreach ($photoUrl in $photoUrls) {
  if (-not $photoUrl.StartsWith("/assets/img/photography/", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Photography path is outside the expected directory: $photoUrl"
  }

  $relativeUrl = $photoUrl.TrimStart("/")
  $relativePath = $relativeUrl.Replace('/', [IO.Path]::DirectorySeparatorChar)
  $sourcePath = [IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath))

  if (-not $sourcePath.StartsWith($sourceRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Resolved photography path is outside the source directory: $sourcePath"
  }
  if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Photography image does not exist: $sourcePath"
  }

  $relativeSourcePath = $sourcePath.Substring($sourceRoot.Length).TrimStart('\', '/')
  $relativeDirectory = [IO.Path]::GetDirectoryName($relativeSourcePath)
  $stem = [IO.Path]::GetFileNameWithoutExtension($sourcePath)
  $sourceItem = Get-Item -LiteralPath $sourcePath

  $pendingWidths = foreach ($width in $targetWidths) {
    $outputDirectory = Join-Path $thumbnailRoot $width
    if ($relativeDirectory) {
      $outputDirectory = Join-Path $outputDirectory $relativeDirectory
    }
    $outputPath = Join-Path $outputDirectory "$stem.webp"
    $outputItem = Get-Item -LiteralPath $outputPath -ErrorAction SilentlyContinue

    if (-not $Force -and $outputItem -and $outputItem.LastWriteTimeUtc -ge $sourceItem.LastWriteTimeUtc) {
      $skipped++
      continue
    }

    [PSCustomObject]@{
      Width = $width
      Directory = $outputDirectory
      Path = $outputPath
    }
  }

  if (-not $pendingWidths) {
    continue
  }

  $image = [System.Drawing.Image]::FromFile($sourcePath)
  try {
    Set-ExifOrientation -Image $image -Orientation (Get-ExifOrientation -Image $image)

    foreach ($target in $pendingWidths) {
      New-Item -ItemType Directory -Path $target.Directory -Force | Out-Null
      $temporaryPng = Join-Path ([IO.Path]::GetTempPath()) ("photography-" + [Guid]::NewGuid() + ".png")
      $bitmap = New-ResizedBitmap -Image $image -TargetWidth $target.Width

      try {
        $bitmap.Save($temporaryPng, [System.Drawing.Imaging.ImageFormat]::Png)
        & $cwebp -quiet -q $Quality -m 6 -mt $temporaryPng -o $target.Path
        if ($LASTEXITCODE -ne 0) {
          throw "cwebp failed for $sourcePath at width $($target.Width)."
        }
      }
      finally {
        $bitmap.Dispose()
        Remove-Item -LiteralPath $temporaryPng -Force -ErrorAction SilentlyContinue
      }

      $generated++
      Write-Host "Generated $($target.Width)px: $($target.Path.Substring($repoRoot.Length + 1))"
    }
  }
  finally {
    $image.Dispose()
  }
}

$thumbnailBytes = if (Test-Path -LiteralPath $thumbnailRoot) {
  (Get-ChildItem -LiteralPath $thumbnailRoot -Recurse -File | Measure-Object Length -Sum).Sum
}
else {
  0
}

Write-Host ""
Write-Host "Generated: $generated; skipped: $skipped; thumbnail size: $([Math]::Round($thumbnailBytes / 1MB, 2)) MiB"
