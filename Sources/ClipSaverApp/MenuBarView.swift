import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.statusTitle)
                .font(.headline)

            Text(appState.lastStatusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Divider()

            Button(appState.toggleTitle) {
                appState.toggleMonitoring()
            }

            Button("打开保存文件夹") {
                appState.openSaveDirectory()
            }

            Button("设置...") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("退出") {
                NSApp.terminate(nil)
            }
        }
        .padding(.vertical, 6)
    }
}
