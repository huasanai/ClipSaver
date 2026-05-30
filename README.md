# ClipSaver

ClipSaver is a native macOS menu bar utility that watches clipboard changes and saves selected content to a local folder.

This repository is intentionally small: no clipboard history database, no sync service, no App Store sandboxing, and no cloud account.

## Requirements

- macOS 14+
- Xcode 16.3 or compatible Swift toolchain
- Swift 6.1 verified

## Development

```bash
swift test
swift run ClipSaverApp
```

## Build App Bundle

```bash
./scripts/build-app.sh
open dist/ClipSaver.app
```

## Behavior

- The menu bar item toggles monitoring, opens the save folder, opens settings, and quits the app.
- Text is saved as `text_<timestamp>.md`.
- Clipboard images are saved as `image_<timestamp>.png` or `image_<timestamp>.tiff`.
- Finder files and folders are saved as path references in `files_<timestamp>.md`.
- Existing files are skipped, never overwritten.
- The default save directory is `~/Documents/ClipSaver`.
- The default global shortcut is `Command + Shift + S` and can be changed in settings.
- Launch at login is available when running from the built `.app` bundle.

## Distribution

This MVP is for direct/local distribution. It is not sandboxed, notarized, or prepared for Mac App Store submission.
