import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("保存类型") {
                Toggle("文本 (.md)", isOn: Binding(
                    get: { appState.saveText },
                    set: { appState.setSaveText($0) }
                ))

                Toggle("图片 (PNG/TIFF)", isOn: Binding(
                    get: { appState.saveImages },
                    set: { appState.setSaveImages($0) }
                ))

                Toggle("文件/文件夹路径 (.md)", isOn: Binding(
                    get: { appState.saveFiles },
                    set: { appState.setSaveFiles($0) }
                ))

                Text("至少保留一种保存类型。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("保存路径") {
                HStack {
                    Text(appState.saveDirectoryPath)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("选择文件夹") {
                        appState.chooseSaveDirectory()
                    }
                }
            }

            Section("快捷键") {
                KeyboardShortcuts.Recorder("开关监听:", name: .toggleMonitoring)
            }

            Section("启动") {
                Toggle("开机自动启动", isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { appState.setLaunchAtLogin($0) }
                ))

                Text("开机启动只在从 .app bundle 运行时可用。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("状态") {
                Text(appState.lastStatusMessage)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 480)
    }
}
