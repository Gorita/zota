import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("vaultPath") var vaultPath: String = ""
    @AppStorage("ollamaURL") var ollamaURL: String = "http://localhost:11434"
    @AppStorage("ollamaModel") var ollamaModel: String = "llama3"
    @AppStorage("availableTags") var availableTagsRaw: String = "개발,디자인,업무,학습,아이디어,회의,자동화,도구"

    var vaultURL: URL? {
        guard !vaultPath.isEmpty else { return nil }
        return URL(fileURLWithPath: vaultPath)
    }

    var availableTags: [String] {
        get { availableTagsRaw.split(separator: ",").map(String.init) }
        set { availableTagsRaw = newValue.joined(separator: ",") }
    }
}
