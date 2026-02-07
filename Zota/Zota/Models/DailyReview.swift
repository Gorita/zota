import Foundation

struct DailyReviewResult: Codable {
    let achievements: [String]
    let ideas: [String]
    let todos: [String]
    let summary: String

    /// 리뷰 결과를 마크다운 형식으로 변환
    func toMarkdown() -> String {
        var sections: [String] = ["## Daily Review"]

        if !achievements.isEmpty {
            sections.append("### 오늘의 성과")
            sections.append(achievements.map { "- \($0)" }.joined(separator: "\n"))
        }

        if !ideas.isEmpty {
            sections.append("### 아이디어")
            sections.append(ideas.map { "- \($0)" }.joined(separator: "\n"))
        }

        if !todos.isEmpty {
            sections.append("### 할 일")
            sections.append(todos.map { "- [ ] \($0)" }.joined(separator: "\n"))
        }

        sections.append("> \(summary)")

        return sections.joined(separator: "\n\n")
    }
}
