# 论文预览图维护说明

论文信息保存在 `_bibliography/papers.bib`，预览图原图保存在本目录。网页应使用脚本生成的 `-thumb.webp` 文件，原图仅作为后续重新生成缩略图的来源。

## 生成缩略图

在仓库根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate-publication-thumbnails.ps1
```

脚本会读取 `papers.bib` 中所有 `preview` 字段，将静态图片缩小到最大 480px 宽并转换为 WebP。GIF 默认缩小到最大 320px，并通过合并相邻帧降低到约 5 FPS；动画总时长和循环方式保持不变。

静态图默认质量为 `82`，动画默认质量为 `72`。强制重新生成全部文件：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate-publication-thumbnails.ps1 -Force
```

更改尺寸或质量时需要同时使用 `-Force`，例如：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate-publication-thumbnails.ps1 -MaxWidth 480 -Quality 78 -AnimatedMaxWidth 320 -AnimatedQuality 68 -Force
```

脚本需要 `cwebp` 和 `img2webp`。当前 Anaconda 环境中的 WebP tools 可以直接使用；其他电脑需要安装 WebP tools 并将它们加入 `PATH`。

## 添加新的预览图

1. 将 JPG、PNG 或 GIF 原图放入本目录。
2. 暂时在论文的 `preview` 字段填写原图文件名。
3. 运行生成脚本。
4. 将 `preview` 改成生成的 `原文件名-thumb.webp`。
5. 提交原图、WebP 缩略图、脚本和 `papers.bib`。

示例：

```bibtex
preview = {example-thumb.webp},
```

不要删除原图，否则以后无法从高质量来源重新生成缩略图。
