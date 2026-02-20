import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var ollamaStatus: OllamaService.HealthStatus? = nil
    @State private var isCheckingConnection = false

    var body: some View {
        Form {
            // MARK: - Vault 경로
            Section("Vault 경로") {
                HStack {
                    TextField("Vault 경로를 선택하세요", text: $appSettings.vaultPath)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)

                    Button("선택") {
                        selectVaultFolder()
                    }
                }

                if let url = appSettings.vaultURL {
                    let exists = FileManager.default.fileExists(atPath: url.path)
                    Label(
                        exists ? "폴더 확인됨" : "폴더를 찾을 수 없음",
                        systemImage: exists ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .foregroundStyle(exists ? .green : .red)
                    .font(.caption)
                }
            }

            // MARK: - Ollama 설정
            Section("Ollama") {
                TextField("URL", text: $appSettings.ollamaURL)
                    .textFieldStyle(.roundedBorder)

                TextField("모델", text: $appSettings.ollamaModel)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    connectionStatusView
                    Spacer()
                    Button("연결 확인") {
                        checkOllamaConnection()
                    }
                    .disabled(isCheckingConnection)
                }
            }

            // MARK: - 태그 설정
            Section("태그 목록") {
                TextField("쉼표로 구분", text: $appSettings.availableTagsRaw)
                    .textFieldStyle(.roundedBorder)

                Text("캡처 시 선택할 수 있는 태그 목록입니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 450, minHeight: 350)
        .onAppear {
            checkOllamaConnection()
        }
    }

    @ViewBuilder
    private var connectionStatusView: some View {
        switch ollamaStatus {
        case .none:
            Label("확인 중...", systemImage: "circle.dotted")
                .foregroundStyle(.secondary)
                .font(.caption)
        case .some(.ready):
            Label("연결됨", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .some(.serverUnavailable):
            Label("서버 연결 실패", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        case .some(.modelNotFound(let name)):
            Label("모델 '\(name)' 없음", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }

    private func selectVaultFolder() {
        let panel = NSOpenPanel()
        panel.title = "Obsidian Vault 폴더를 선택하세요"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            appSettings.vaultPath = url.path
        }
    }

    private func checkOllamaConnection() {
        isCheckingConnection = true
        ollamaStatus = nil

        Task {
            let service = OllamaService(
                baseURL: URL(string: appSettings.ollamaURL)!,
                model: appSettings.ollamaModel
            )
            let status = await service.healthCheck()
            await MainActor.run {
                ollamaStatus = status
                isCheckingConnection = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
