import Foundation

class VaultService {
    let vaultPath: URL

    init(vaultPath: URL) {
        self.vaultPath = vaultPath
    }

    /// Inbox 폴더에 새 노트 생성
    func createNote(title: String, content: String, tags: [String] = []) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let slug = MarkdownParser.slugify(title)
        let filename = slug.isEmpty ? "\(dateString)-메모.md" : "\(dateString)-\(slug).md"

        let tagsValue = tags.isEmpty ? "[]" : "[\(tags.map { "\"\($0)\"" }.joined(separator: ", "))]"

        let frontmatter: [String: String] = [
            "title": title,
            "date": dateString,
            "tags": tagsValue,
        ]

        let markdown = MarkdownParser.compose(frontmatter: frontmatter, body: content)

        let inboxPath = vaultPath.appendingPathComponent("Inbox")

        // Inbox 폴더가 없으면 생성
        if !FileManager.default.fileExists(atPath: inboxPath.path) {
            try FileManager.default.createDirectory(at: inboxPath, withIntermediateDirectories: true)
        }

        let filePath = inboxPath.appendingPathComponent(filename)
        try markdown.write(to: filePath, atomically: true, encoding: .utf8)
        return filePath
    }

    /// 데일리 노트에서 메모 항목들 추출
    func extractMemos(from date: Date) throws -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let path = vaultPath
            .appendingPathComponent("Daily")
            .appendingPathComponent("\(dateString).md")

        guard FileManager.default.fileExists(atPath: path.path) else { return [] }

        let content = try String(contentsOf: path, encoding: .utf8)
        let (_, body) = MarkdownParser.parse(content: content)

        // "## Memos" 섹션 아래의 리스트 항목들 추출
        guard let memosRange = body.range(of: "## Memos", options: .caseInsensitive) else {
            return []
        }

        let afterMemos = String(body[memosRange.upperBound...])

        // 다음 ## 헤딩이 나올 때까지의 내용만
        let section: String
        if let nextHeading = afterMemos.range(of: "\n## ") {
            section = String(afterMemos[afterMemos.startIndex..<nextHeading.lowerBound])
        } else {
            section = afterMemos
        }

        return section
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("- ") }
            .map { String($0.dropFirst(2)) }
    }

    /// 데일리 노트에 리뷰 섹션 추가/교체
    func updateDailyReview(for date: Date, reviewContent: String) throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let path = vaultPath
            .appendingPathComponent("Daily")
            .appendingPathComponent("\(dateString).md")

        guard FileManager.default.fileExists(atPath: path.path) else {
            throw ZotaError.dailyNoteNotFound
        }

        var content = try String(contentsOf: path, encoding: .utf8)

        // "## Daily Review" 섹션이 있으면 교체
        if let reviewRange = content.range(of: "## Daily Review") {
            // 다음 ## 헤딩까지 또는 끝까지
            let afterReview = String(content[reviewRange.upperBound...])
            if let nextHeading = afterReview.range(of: "\n## ") {
                let endIndex = content.index(reviewRange.upperBound, offsetBy: afterReview.distance(from: afterReview.startIndex, to: nextHeading.lowerBound))
                content.replaceSubrange(reviewRange.lowerBound..<endIndex, with: reviewContent)
            } else {
                content.replaceSubrange(reviewRange.lowerBound..., with: reviewContent)
            }
        } else {
            content.append("\n\n\(reviewContent)\n")
        }

        try content.write(to: path, atomically: true, encoding: .utf8)
    }

    /// Vault 경로 유효성 확인
    var isValid: Bool {
        FileManager.default.fileExists(atPath: vaultPath.path)
    }
}
