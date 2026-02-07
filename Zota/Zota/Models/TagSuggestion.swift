import Foundation

struct TagSuggestionResult: Codable {
    let tags: [String]

    /// 허용된 태그 목록에 있는 태그만 필터링
    func filteredTags(allowedTags: [String]) -> [String] {
        tags.filter { allowedTags.contains($0) }
    }

    /// Tagger 프롬프트에 사용할 사용자 입력 텍스트 생성
    static func buildPrompt(title: String, content: String, availableTags: [String]) -> String {
        let tagList = availableTags.map { "\"\($0)\"" }.joined(separator: ", ")
        return """
        Allowed tags: [\(tagList)]

        Title: \(title)
        Content: \(content)
        """
    }
}
