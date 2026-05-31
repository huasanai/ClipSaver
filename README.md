# ClipSaver

## 中文说明

ClipSaver 是一个原生 macOS 菜单栏工具，用来监听系统剪贴板，并把符合条件的内容自动保存到你指定的本地文件夹。

它的目标很小：复制文字、截图、Finder 文件/文件夹时，不需要手动粘贴，就能得到一份可持久化的文件或路径记录。

### 系统要求

- macOS 14+
- Xcode 16.3 或兼容的 Swift 工具链
- 已验证 Swift 6.1

### 如何打开

```bash
open dist/ClipSaver.app
```

手动打开后会显示 `ClipSaver 设置` 窗口，同时右上角菜单栏会出现 `ClipSaver`。

如果 macOS 提示无法打开未认证 App，可以右键 `ClipSaver.app`，选择“打开”。

### 设置项

- **监听**：开启或暂停自动保存。
- **保存类型**：分别控制文本、图片、Finder 文件/文件夹路径。
- **保存路径**：点击“选择文件夹”指定保存目录；点击“打开保存文件夹”可直接打开当前目录。
- **文件命名**：
  - 系统自动命名：`{type}_{timestamp}`
  - 使用命名格式：支持 `{type}`、`{timestamp}`、`{date}`、`{time}`、`{uuid}`
  - 每次保存前询问：每次复制后弹窗确认文件名，也可以在弹窗里选择之后不再询问
- **快捷键**：默认 `⇧⌘S`，可在设置中重新录制。
- **开机自动启动**：从 `.app` bundle 运行时可用。

### 保存规则

- 文本保存为 `text_<timestamp>.md`。
- PNG/TIFF 图片保存为 `image_<timestamp>.png` 或 `image_<timestamp>.tiff`。
- Finder 文件/文件夹不会复制本体，只会保存绝对路径到 `files_<timestamp>.md`。
- 已存在的目标文件不会被覆盖。
- 默认保存路径是 `~/Documents/ClipSaver`。
- 如果只勾选“文本”，截图和 Finder 文件不会进入目录。

### 开发

```bash
swift test
swift run ClipSaverApp
```

### 构建 App

```bash
./scripts/build-app.sh
open dist/ClipSaver.app
```

### 分发说明

当前版本面向本地直接使用和开源演示。它没有做 App Store 沙盒、签名公证、自动更新，也没有剪贴板历史数据库或云同步。

---

## English

ClipSaver is a native macOS menu bar utility that watches clipboard changes and automatically saves selected clipboard content to a local folder.

It is intentionally small: when you copy text, screenshots, or Finder files/folders, ClipSaver can persist them without requiring a manual paste action.

### Requirements

- macOS 14+
- Xcode 16.3 or a compatible Swift toolchain
- Swift 6.1 verified

### Open The App

```bash
open dist/ClipSaver.app
```

Opening the app manually shows the `ClipSaver Settings` window. ClipSaver also stays in the menu bar with a visible `ClipSaver` title.

If macOS blocks the app because it is not notarized, right-click `ClipSaver.app` and choose `Open`.

### Settings

- **Monitoring**: enable or pause automatic saving.
- **Save types**: independently control text, images, and Finder file/folder paths.
- **Save folder**: use the folder picker to choose where files are saved, or open the current save folder directly.
- **Filename mode**:
  - automatic naming: `{type}_{timestamp}`
  - custom format: supports `{type}`, `{timestamp}`, `{date}`, `{time}`, `{uuid}`
  - ask before each save: confirm or edit the filename every time, with an option to stop asking
- **Shortcut**: default `Command + Shift + S`, configurable in settings.
- **Launch at login**: available when running from the built `.app` bundle.

### Behavior

- Text is saved as `text_<timestamp>.md`.
- PNG/TIFF images are saved as `image_<timestamp>.png` or `image_<timestamp>.tiff`.
- Finder files and folders are saved as absolute path references in `files_<timestamp>.md`; original files are not copied.
- Existing files are skipped, never overwritten.
- The default save directory is `~/Documents/ClipSaver`.
- If only text is enabled, screenshots and Finder files will not be saved.

### Development

```bash
swift test
swift run ClipSaverApp
```

### Build App Bundle

```bash
./scripts/build-app.sh
open dist/ClipSaver.app
```

### Distribution

This MVP is for direct local use and open-source demonstration. It is not sandboxed, notarized, or prepared for Mac App Store submission. It also does not include clipboard history storage or cloud sync.
