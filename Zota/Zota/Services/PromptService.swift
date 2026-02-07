import Foundation

class PromptService {
    let vaultPath: URL

    init(vaultPath: URL) {
        self.vaultPath = vaultPath
    }

    /// Vault 내 System/Prompts/ 폴더에서 프롬프트 파일 로딩
    func loadPrompt(named name: String) throws -> String {
        let path = vaultPath
            .appendingPathComponent("System/Prompts")
            .appendingPathComponent("\(name).md")

        guard FileManager.default.fileExists(atPath: path.path) else {
            throw ZotaError.promptNotFound(name)
        }
        return try String(contentsOf: path, encoding: .utf8)
    }
}
