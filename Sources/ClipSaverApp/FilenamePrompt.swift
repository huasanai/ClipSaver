import AppKit
import ClipSaverCore

enum FilenamePromptResult {
    case save(filename: String, stopAsking: Bool)
    case skip
}

@MainActor
enum FilenamePrompt {
    static func show(defaultFilename: String) -> FilenamePromptResult {
        let filenameField = NSTextField(string: defaultFilename)
        filenameField.frame = NSRect(x: 0, y: 34, width: 360, height: 24)
        filenameField.placeholderString = "文件名"

        let checkbox = NSButton(checkboxWithTitle: "不再询问，之后使用系统自动命名", target: nil, action: nil)
        checkbox.frame = NSRect(x: 0, y: 0, width: 360, height: 24)

        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 62))
        accessory.addSubview(filenameField)
        accessory.addSubview(checkbox)

        let alert = NSAlert()
        alert.messageText = "保存剪贴板内容"
        alert.informativeText = "确认或修改本次保存的文件名。"
        alert.accessoryView = accessory
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "跳过")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        guard response == .alertFirstButtonReturn else {
            return .skip
        }

        let filename = filenameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !filename.isEmpty else {
            return .skip
        }

        return .save(filename: filename, stopAsking: checkbox.state == .on)
    }
}
