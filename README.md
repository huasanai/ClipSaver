# ClipSaver

> 原生 macOS 菜单栏小工具：监听系统剪贴板，把你复制的内容自动存成本地文件。

English version → [README.en.md](README.en.md)

---

## 这是什么

平时复制了一段文字、截了张图、在 Finder 里拷了个文件，想留个底，往往还得手动新建文件再粘贴一遍。ClipSaver 把这一步省掉了。

实现逻辑很简单：它常驻在菜单栏，**轮询监听系统剪贴板**，发现内容变化时，按你设定的规则把内容写到一个本地文件夹里——文字存成 `.md`，图片存成 `.png/.tiff`，Finder 文件则只记录绝对路径。全程在本地完成，不联网、不存历史数据库、不上传任何东西。

- 复制文字 → 自动存一份 Markdown
- 截图 / 复制图片 → 自动存图片文件
- 在 Finder 复制文件/文件夹 → 自动记录它的路径（不搬动原文件）

适合用来快速归档灵感、素材、临时文件路径。

---

## 下载安装

### 方式一：下载现成的 App（推荐普通用户）

1. 打开 [Releases 页面](https://github.com/huasanai/ClipSaver/releases/latest)，下载 `ClipSaver.app.zip`。
2. 解压后，把 `ClipSaver.app` 拖进「应用程序」文件夹。
3. **首次打开**：因为这个 App 没有做苹果公证，直接双击会被拦。两种办法任选其一：
   - 右键点 `ClipSaver.app` → 选「打开」→ 在弹窗里再点「打开」；或
   - 打开「终端」执行一次：
     ```bash
     xattr -dr com.apple.quarantine /Applications/ClipSaver.app
     ```
     之后就能正常双击打开了。

> 这是开源工具的常规现象，不是病毒提示。源码全部公开，你可以自己审。

### 方式二：源码自己构建（推荐开发者）

需要 macOS 14+ 和 Xcode 16.3 / 兼容的 Swift 6.1 工具链。

```bash
git clone https://github.com/huasanai/ClipSaver.git
cd ClipSaver
./scripts/build-app.sh
open dist/ClipSaver.app
```

---

## 怎么用

打开后，菜单栏右上角会出现 `ClipSaver`，同时弹出「ClipSaver 设置」窗口。

基本流程：**在设置里选好保存文件夹 → 打开「监听」→ 之后正常复制内容即可，会自动存进去。**

设置项说明：

- **监听**：总开关，开启后才会自动保存，随时可暂停。
- **保存类型**：文本 / 图片 / Finder 文件路径，三类可分别开关。比如只想存文字，就只勾文本。
- **保存路径**：点「选择文件夹」指定目录；点「打开保存文件夹」直接在 Finder 里查看。默认是 `~/Documents/ClipSaver`。
- **文件命名**：
  - 系统自动命名：`{type}_{timestamp}`
  - 自定义格式：支持 `{type}`、`{timestamp}`、`{date}`、`{time}`、`{uuid}` 占位符
  - 每次保存前询问：每次复制后弹窗让你确认/修改文件名（也可在弹窗里选「以后不再询问」）
- **快捷键**：默认 `⇧⌘S` 用来快速开关监听，可在设置里重新录制。
- **开机自动启动**：从 `.app` 运行时可开启，登录后会在后台静默启动。

---

## 保存规则

- 文本 → `text_<timestamp>.md`
- 图片（PNG/TIFF）→ `image_<timestamp>.png` 或 `.tiff`
- Finder 文件/文件夹 → 只把**绝对路径**写进 `files_<timestamp>.md`，**不复制原文件本体**
- 已存在的同名文件**不会被覆盖**，直接跳过
- 如果只勾了「文本」，截图和 Finder 文件就不会进目录

---

## 安全性

- **纯本地运行**：所有保存都写到你指定的本地文件夹，全程不联网、不上传、无云同步。
- **不留剪贴板历史库**：它不建数据库记录你复制过的一切，只在内容变化时写一份文件，写完即止。
- **Finder 文件只存路径**：复制文件/文件夹时不会搬动或拷贝你的原文件，只记录一行路径文本。
- **完全开源**：代码在本仓库，逻辑可审。未做苹果签名公证，所以首次打开需手动放行（见上方安装说明）。

---

## 开发

```bash
swift test             # 跑测试
swift run ClipSaverApp # 直接运行
./scripts/build-app.sh # 打包成 .app
```

CI 会在每次 push / PR 时自动跑 `swift test`。

---

## 分发说明

当前版本面向本地直接使用和开源演示，**没有**做 App Store 沙盒、签名公证、自动更新，也没有剪贴板历史数据库或云同步。

## License

[MIT](LICENSE) © 2026 Huasan
