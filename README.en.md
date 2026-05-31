# ClipSaver

> A native macOS menu bar utility that watches the system clipboard and auto-saves what you copy to a local folder.

中文版 → [README.md](README.md)

---

## What it is

When you copy a snippet of text, take a screenshot, or grab a file in Finder and want to keep a copy, you usually have to create a file and paste it in by hand. ClipSaver removes that step.

The logic is simple: it lives in the menu bar, **polls the system clipboard**, and whenever the contents change it writes them to a local folder according to your rules — text becomes a `.md` file, images become `.png/.tiff`, and Finder files are recorded as absolute paths. Everything happens locally: no network, no history database, nothing uploaded.

- Copy text → saved as Markdown
- Take a screenshot / copy an image → saved as an image file
- Copy a file/folder in Finder → its path is recorded (the original is never moved)

Handy for quickly archiving ideas, assets, and temporary file paths.

---

## Download & Install

### Option 1: Download the prebuilt app (recommended for most users)

1. Open the [Releases page](https://github.com/huasanai/ClipSaver/releases/latest) and download `ClipSaver.app.zip`.
2. Unzip it and drag `ClipSaver.app` into your Applications folder.
3. **First launch**: the app is not notarized by Apple, so a plain double-click is blocked. Pick either workaround:
   - Right-click `ClipSaver.app` → **Open** → click **Open** again in the dialog; or
   - Run this once in Terminal:
     ```bash
     xattr -dr com.apple.quarantine /Applications/ClipSaver.app
     ```
     after which it opens normally.

> This is normal for open-source tools, not a malware warning. The full source is public — audit it yourself.

### Option 2: Build from source (recommended for developers)

Requires macOS 14+ and Xcode 16.3 / a compatible Swift 6.1 toolchain.

```bash
git clone https://github.com/huasanai/ClipSaver.git
cd ClipSaver
./scripts/build-app.sh
open dist/ClipSaver.app
```

---

## Usage

After launching, `ClipSaver` appears in the menu bar and the **ClipSaver Settings** window opens.

Basic flow: **pick a save folder in settings → turn on Monitoring → copy things as usual and they get saved automatically.**

Settings:

- **Monitoring**: master switch; auto-save only runs when it is on. Pause any time.
- **Save types**: text / images / Finder file paths, each toggled independently. Want text only? Enable just text.
- **Save folder**: use **Choose Folder** to set the directory, or **Open Save Folder** to view it in Finder. Default is `~/Documents/ClipSaver`.
- **Filename mode**:
  - automatic naming: `{type}_{timestamp}`
  - custom format: supports `{type}`, `{timestamp}`, `{date}`, `{time}`, `{uuid}`
  - ask before each save: confirm/edit the filename every time (with a "stop asking" option in the dialog)
- **Shortcut**: default `⇧⌘S` toggles monitoring; re-recordable in settings.
- **Launch at login**: available when running from the `.app`; starts silently in the background after login.

---

## Save rules

- Text → `text_<timestamp>.md`
- Images (PNG/TIFF) → `image_<timestamp>.png` or `.tiff`
- Finder files/folders → only the **absolute path** is written to `files_<timestamp>.md`; **the original file is never copied**
- An existing file with the same name is **never overwritten** — it is skipped
- If only "text" is enabled, screenshots and Finder files are not saved

---

## Security

- **Fully local**: everything is written to the local folder you choose. No network, no upload, no cloud sync.
- **No clipboard history database**: it does not record everything you ever copied — it just writes one file when the contents change, then stops.
- **Finder files store paths only**: copying a file/folder does not move or duplicate your original; only a line of path text is recorded.
- **Open source**: the code is in this repo and the logic is auditable. It is not signed/notarized, so the first launch needs a manual override (see install above).

---

## Development

```bash
swift test             # run tests
swift run ClipSaverApp # run directly
./scripts/build-app.sh # package into .app
```

CI runs `swift test` on every push / PR.

---

## Distribution

This version targets direct local use and open-source demonstration. It is **not** sandboxed, notarized, or prepared for the Mac App Store, and it has no clipboard history storage or cloud sync.

## License

[MIT](LICENSE) © 2026 Huasan
