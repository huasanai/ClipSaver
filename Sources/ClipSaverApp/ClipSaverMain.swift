import AppKit

@main
struct ClipSaverMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()

        app.delegate = delegate
        app.run()
    }
}
