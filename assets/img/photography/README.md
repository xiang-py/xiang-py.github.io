# 摄影图片维护说明

摄影页面的数据保存在 `_data/photography.yml`，原图保存在本目录。网页显示 WebP 缩略图，点击照片后仍会打开原图。

## 添加照片

1. 将原图放入本目录下合适的子文件夹，例如：

   ```text
   assets/img/photography/Shanghai/2026-07-shanghai-01.jpg
   ```

2. 在 `_data/photography.yml` 的对应相册中加入图片路径：

   ```yaml
   - image: /assets/img/photography/Shanghai/2026-07-shanghai-01.jpg
     alt: Shanghai street at sunset
     caption: 可选的照片说明
   ```

3. 在仓库根目录运行缩略图生成脚本：

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/generate-photography-thumbnails.ps1
   ```

脚本会读取 `_data/photography.yml`，为其中引用的照片生成两档缩略图：

```text
assets/img/photography/thumbnails/800/...
assets/img/photography/thumbnails/1400/...
```

脚本会自动处理照片的 EXIF 旋转方向，不会修改原图，并会跳过已经是最新状态的缩略图。

## 运行要求

脚本需要 Windows PowerShell 和 `cwebp`。可以先检查 `cwebp` 是否可用：

```powershell
cwebp -version
```

如果提示找不到命令，需要安装 WebP tools，并将 `cwebp` 所在目录加入系统 `PATH`。

## 常用参数

默认 WebP 质量为 `82`。如果替换了原图，普通运行会自动重新生成对应缩略图。

强制重新生成全部缩略图：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate-photography-thumbnails.ps1 -Force
```

使用其他 WebP 质量并强制重新生成，例如质量 `78`：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate-photography-thumbnails.ps1 -Quality 78 -Force
```

正常的增量运行结束时，会看到类似结果：

```text
Generated: 0; skipped: 96; thumbnail size: 13.36 MiB
```

## 发布更新

确认页面显示正常后，将原图、YAML 和缩略图一起提交：

```powershell
git add _data/photography.yml assets/img/photography scripts/generate-photography-thumbnails.ps1
git commit -m "Update photography gallery"
git push origin main
```

不要在 `_data/photography.yml` 中填写 `thumbnails` 路径，也不需要手动修改生成的 WebP 文件。页面会根据原图路径自动找到对应缩略图。

## 其他设置

- 使用简短、清晰的文件名，例如 `2026-07-shanghai-01.jpg`。
- 每个相册共用标题、日期、地点和简介；每张照片可以设置独立的 `alt` 和 `caption`。
- 修改 `_data/photography.yml` 顶部的 `photos_per_page` 可以调整每页照片数量。
