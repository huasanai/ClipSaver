import ClipSaverCore
import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    let chooseSaveDirectory: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("监听") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("自动保存剪贴板内容", isOn: Binding(
                            get: { appState.isMonitoringEnabled },
                            set: { appState.setMonitoringEnabled($0) }
                        ))

                        Text("关闭后会继续观察剪贴板变化，但不会保存暂停期间复制的内容。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("保存类型") {
                    VStack(alignment: .leading, spacing: 8) {
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

                        Text("至少保留一种保存类型。只勾选文本时，截图和 Finder 文件不会进入目录。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("保存路径") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(appState.saveDirectoryPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.enabled)

                            Spacer()

                            Button("选择文件夹") {
                                chooseSaveDirectory()
                            }
                        }

                        Button("打开保存文件夹") {
                            appState.openSaveDirectory()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("文件命名") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("命名方式", selection: Binding(
                            get: { appState.fileNamingStrategy },
                            set: { appState.setFileNamingStrategy($0) }
                        )) {
                            ForEach(FileNamingStrategy.allCases) { strategy in
                                Text(strategy.displayName).tag(strategy)
                            }
                        }
                        .pickerStyle(.radioGroup)

                        TextField("命名格式", text: Binding(
                            get: { appState.filenameFormat },
                            set: { appState.setFilenameFormat($0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .disabled(appState.fileNamingStrategy != .customFormat)

                        Text("可用变量：{type}、{timestamp}、{date}、{time}、{uuid}。扩展名会自动补上。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("选择“每次保存前询问”时，每次复制后会先弹出文件名确认框，也可以在确认框里选择之后不再询问。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("快捷键") {
                    VStack(alignment: .leading, spacing: 8) {
                        KeyboardShortcuts.Recorder("开关监听:", name: .toggleMonitoring)

                        Text("默认快捷键是 ⇧⌘S。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("启动") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("开机自动启动", isOn: Binding(
                            get: { appState.launchAtLogin },
                            set: { appState.setLaunchAtLogin($0) }
                        ))

                        Text("开机启动只在从 .app bundle 运行时可用。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("状态") {
                    Text(appState.lastStatusMessage)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 560, idealWidth: 620, minHeight: 560, idealHeight: 680)
    }
}
