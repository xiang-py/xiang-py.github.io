[CmdletBinding()]
param(
  [ValidateRange(64, 2000)]
  [int]$MaxWidth = 480,

  [ValidateRange(1, 100)]
  [int]$Quality = 82,

  [ValidateRange(64, 2000)]
  [int]$AnimatedMaxWidth = 320,

  [ValidateRange(1, 100)]
  [int]$AnimatedQuality = 72,

  [ValidateRange(1, 10)]
  [int]$AnimatedFrameStep = 2,

  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$bibliographyFile = Join-Path $repoRoot "_bibliography\papers.bib"
$previewRoot = (Resolve-Path (Join-Path $repoRoot "assets\img\publication_preview")).Path
$sourceExtensions = @(".jpg", ".jpeg", ".png", ".gif", ".tif", ".tiff")

function Resolve-WebpTools {
  $cwebpCommand = Get-Command "cwebp" -ErrorAction SilentlyContinue
  $img2webpCommand = Get-Command "img2webp" -ErrorAction SilentlyContinue
  $cwebpPath = if ($cwebpCommand) { $cwebpCommand.Source } else { $null }
  $img2webpPath = if ($img2webpCommand) { $img2webpCommand.Source } else { $null }

  if (-not $img2webpPath -and $env:CONDA_PREFIX) {
    $packageRoot = Join-Path $env:CONDA_PREFIX "pkgs"
    $toolPackage = Get-ChildItem -LiteralPath $packageRoot -Directory -Filter "libwebp-*" -ErrorAction SilentlyContinue |
      Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "Library\bin\img2webp.exe") } |
      Sort-Object Name -Descending |
      Select-Object -First 1

    if ($toolPackage) {
      $toolDirectory = Join-Path $toolPackage.FullName "Library\bin"
      $img2webpPath = Join-Path $toolDirectory "img2webp.exe"
      $cwebpPath = Join-Path $toolDirectory "cwebp.exe"
      $dependencyDirectories = @($toolDirectory, (Join-Path $env:CONDA_PREFIX "Library\bin"))

      if ($toolPackage.Name -match '^libwebp-(\d+\.\d+\.\d+)-') {
        $version = $Matches[1]
        $basePackage = Get-ChildItem -LiteralPath $packageRoot -Directory -Filter "libwebp-base-$version-*" -ErrorAction SilentlyContinue |
          Sort-Object Name -Descending |
          Select-Object -First 1
        if ($basePackage) {
          $dependencyDirectories = @((Join-Path $basePackage.FullName "Library\bin")) + $dependencyDirectories
        }
      }

      $env:PATH = ($dependencyDirectories -join [IO.Path]::PathSeparator) + [IO.Path]::PathSeparator + $env:PATH
    }
  }

  if (-not $cwebpPath -or -not (Test-Path -LiteralPath $cwebpPath -PathType Leaf)) {
    throw "cwebp was not found. Install WebP tools or add cwebp to PATH."
  }
  if (-not $img2webpPath -or -not (Test-Path -LiteralPath $img2webpPath -PathType Leaf)) {
    throw "img2webp was not found. Install WebP tools with animation support or add img2webp to PATH."
  }

  & $cwebpPath -version 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "cwebp could not start. Check that its runtime dependencies are available."
  }
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  & $img2webpPath -version 2>$null | Out-Null
  $img2webpExitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorActionPreference
  if ($img2webpExitCode -ne 0) {
    throw "img2webp could not start. Check that its runtime dependencies are available."
  }

  return [PSCustomObject]@{
    Cwebp = $cwebpPath
    Img2webp = $img2webpPath
  }
}

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
    [int]$MaximumWidth
  )

  $targetWidth = [Math]::Min($MaximumWidth, $Image.Width)
  $targetHeight = [Math]::Max(1, [int][Math]::Round($Image.Height * $targetWidth / $Image.Width))
  $bitmap = [System.Drawing.Bitmap]::new(
    $targetWidth,
    $targetHeight,
    [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb
  )
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

  try {
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($Image, 0, 0, $targetWidth, $targetHeight)
  }
  finally {
    $graphics.Dispose()
  }

  return $bitmap
}

function Get-GifFrameDelays {
  param(
    [System.Drawing.Image]$Image,
    [int]$FrameCount
  )

  $delays = for ($index = 0; $index -lt $FrameCount; $index++) { 100 }
  if ($Image.PropertyIdList -contains 20736) {
    $property = $Image.GetPropertyItem(20736)
    for ($index = 0; $index -lt $FrameCount; $index++) {
      $offset = $index * 4
      if ($offset + 4 -le $property.Value.Length) {
        $delay = [BitConverter]::ToInt32($property.Value, $offset) * 10
        $delays[$index] = [Math]::Max(10, $delay)
      }
    }
  }

  return $delays
}

function Get-GifLoopCount {
  param([System.Drawing.Image]$Image)

  if ($Image.PropertyIdList -contains 20737) {
    return [BitConverter]::ToUInt16($Image.GetPropertyItem(20737).Value, 0)
  }

  return 0
}

function Convert-StaticPreview {
  param(
    [System.Drawing.Image]$Image,
    [string]$OutputPath,
    [string]$CwebpPath
  )

  Set-ExifOrientation -Image $Image -Orientation (Get-ExifOrientation -Image $Image)
  $temporaryPng = Join-Path ([IO.Path]::GetTempPath()) ("publication-preview-" + [Guid]::NewGuid() + ".png")
  $bitmap = New-ResizedBitmap -Image $Image -MaximumWidth $MaxWidth

  try {
    $bitmap.Save($temporaryPng, [System.Drawing.Imaging.ImageFormat]::Png)
    & $CwebpPath -quiet -q $Quality -m 6 -mt $temporaryPng -o $OutputPath
    if ($LASTEXITCODE -ne 0) {
      throw "cwebp failed while creating $OutputPath."
    }
  }
  finally {
    $bitmap.Dispose()
    Remove-Item -LiteralPath $temporaryPng -Force -ErrorAction SilentlyContinue
  }
}

function Convert-AnimatedPreview {
  param(
    [System.Drawing.Image]$Image,
    [System.Drawing.Imaging.FrameDimension]$FrameDimension,
    [int]$FrameCount,
    [string]$OutputPath,
    [string]$Img2webpPath
  )

  $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("publication-preview-" + [Guid]::NewGuid())
  New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
  $framePaths = [System.Collections.Generic.List[string]]::new()
  $outputDelays = [System.Collections.Generic.List[int]]::new()
  $frameDelays = Get-GifFrameDelays -Image $Image -FrameCount $FrameCount

  try {
    for ($index = 0; $index -lt $FrameCount; $index += $AnimatedFrameStep) {
      [void]$Image.SelectActiveFrame($FrameDimension, $index)
      $framePath = Join-Path $temporaryDirectory ("frame-{0:D4}.png" -f $index)
      $bitmap = New-ResizedBitmap -Image $Image -MaximumWidth $AnimatedMaxWidth
      try {
        $bitmap.Save($framePath, [System.Drawing.Imaging.ImageFormat]::Png)
      }
      finally {
        $bitmap.Dispose()
      }
      $framePaths.Add($framePath)

      $combinedDelay = 0
      for ($delayIndex = $index; $delayIndex -lt [Math]::Min($index + $AnimatedFrameStep, $FrameCount); $delayIndex++) {
        $combinedDelay += $frameDelays[$delayIndex]
      }
      $outputDelays.Add($combinedDelay)
    }

    $arguments = [System.Collections.Generic.List[string]]::new()
    $arguments.Add("-min_size")
    $arguments.Add("-loop")
    $arguments.Add((Get-GifLoopCount -Image $Image).ToString())
    for ($index = 0; $index -lt $framePaths.Count; $index++) {
      $arguments.Add("-d")
      $arguments.Add($outputDelays[$index].ToString())
      $arguments.Add("-lossy")
      $arguments.Add("-q")
      $arguments.Add($AnimatedQuality.ToString())
      $arguments.Add("-m")
      $arguments.Add("6")
      $arguments.Add($framePaths[$index])
    }
    $arguments.Add("-o")
    $arguments.Add($OutputPath)

    & $Img2webpPath $arguments.ToArray()
    if ($LASTEXITCODE -ne 0) {
      throw "img2webp failed while creating $OutputPath."
    }
  }
  finally {
    Get-ChildItem -LiteralPath $temporaryDirectory -File -ErrorAction SilentlyContinue |
      Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temporaryDirectory -Force -ErrorAction SilentlyContinue
  }
}

function Resolve-PreviewSource {
  param([string]$PreviewValue)

  $currentPath = [IO.Path]::GetFullPath((Join-Path $previewRoot $PreviewValue))
  if ($currentPath.StartsWith($previewRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -eq $false) {
    throw "Preview path is outside assets/img/publication_preview: $PreviewValue"
  }

  $currentStem = [IO.Path]::GetFileNameWithoutExtension($currentPath)
  if ([IO.Path]::GetExtension($currentPath).Equals(".webp", [StringComparison]::OrdinalIgnoreCase) -and $currentStem.EndsWith("-thumb", [StringComparison]::OrdinalIgnoreCase)) {
    $sourceStem = $currentStem.Substring(0, $currentStem.Length - 6)
    $sourceDirectory = [IO.Path]::GetDirectoryName($currentPath)
    $matches = @(Get-ChildItem -LiteralPath $sourceDirectory -File | Where-Object {
      $_.BaseName.Equals($sourceStem, [StringComparison]::OrdinalIgnoreCase) -and
      $sourceExtensions -contains $_.Extension.ToLowerInvariant()
    })
    if ($matches.Count -ne 1) {
      throw "Expected one original image for $PreviewValue, found $($matches.Count)."
    }
    return $matches[0].FullName
  }

  if (-not (Test-Path -LiteralPath $currentPath -PathType Leaf)) {
    throw "Publication preview does not exist: $currentPath"
  }
  return $currentPath
}

$tools = Resolve-WebpTools
$previewValues = Select-String -LiteralPath $bibliographyFile -Pattern '^\s*preview\s*=\s*\{([^}]+)\}' |
  ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() } |
  Sort-Object -Unique

if (-not $previewValues) {
  throw "No publication preview fields were found in $bibliographyFile."
}

$generated = 0
$skipped = 0
$totalFrames = 0

foreach ($previewValue in $previewValues) {
  $sourcePath = Resolve-PreviewSource -PreviewValue $previewValue
  $sourceItem = Get-Item -LiteralPath $sourcePath
  $outputPath = Join-Path $sourceItem.DirectoryName ($sourceItem.BaseName + "-thumb.webp")
  $outputItem = Get-Item -LiteralPath $outputPath -ErrorAction SilentlyContinue

  if (-not $Force -and $outputItem -and $outputItem.LastWriteTimeUtc -ge $sourceItem.LastWriteTimeUtc) {
    $skipped++
    continue
  }

  $image = [System.Drawing.Image]::FromFile($sourcePath)
  try {
    $frameDimension = [System.Drawing.Imaging.FrameDimension]::new($image.FrameDimensionsList[0])
    $frameCount = $image.GetFrameCount($frameDimension)
    if ($frameCount -gt 1) {
      Convert-AnimatedPreview -Image $image -FrameDimension $frameDimension -FrameCount $frameCount -OutputPath $outputPath -Img2webpPath $tools.Img2webp
      $totalFrames += [Math]::Ceiling($frameCount / $AnimatedFrameStep)
    }
    else {
      Convert-StaticPreview -Image $image -OutputPath $outputPath -CwebpPath $tools.Cwebp
    }
  }
  finally {
    $image.Dispose()
  }

  $generated++
  Write-Host "Generated: $($sourceItem.Name) -> $([IO.Path]::GetFileName($outputPath))"
}

$thumbnailFiles = Get-ChildItem -LiteralPath $previewRoot -File -Filter "*-thumb.webp"
$thumbnailBytes = ($thumbnailFiles | Measure-Object Length -Sum).Sum

Write-Host ""
Write-Host "Generated: $generated; skipped: $skipped; animated frames: $totalFrames; thumbnail size: $([Math]::Round($thumbnailBytes / 1MB, 2)) MiB"
Write-Host "Use the generated *-thumb.webp filenames in the BibTeX preview fields."
