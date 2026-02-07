import Foundation

struct MarkdownParser {
    /// YAML frontmatter와 body를 분리하여 파싱
    static func parse(content: String) -> (frontmatter: [String: String], body: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.hasPrefix("---") else {
            return ([:], content)
        }

        // "---" 이후의 두 번째 "---"를 찾는다
        let afterFirstDelimiter = trimmed.dropFirst(3)
        guard let endRange = afterFirstDelimiter.range(of: "\n---") else {
            return ([:], content)
        }

        let yamlString = String(afterFirstDelimiter[afterFirstDelimiter.startIndex..<endRange.lowerBound])
        let body = String(afterFirstDelimiter[endRange.upperBound...]).trimmingCharacters(in: .newlines)

        let frontmatter = parseYAML(yamlString)
        return (frontmatter, body)
    }

    /// 간단한 YAML key: value 파싱 (중첩 구조 미지원)
    private static func parseYAML(_ yaml: String) -> [String: String] {
        var result: [String: String] = [:]

        for line in yaml.components(separatedBy: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            if let colonIndex = trimmedLine.firstIndex(of: ":") {
                let key = String(trimmedLine[trimmedLine.startIndex..<colonIndex])
                    .trimmingCharacters(in: .whitespaces)
                var value = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespaces)

                // 따옴표 제거
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }

                result[key] = value
            }
        }

        return result
    }

    /// frontmatter + body를 마크다운 문자열로 결합
    static func compose(frontmatter: [String: String], body: String) -> String {
        guard !frontmatter.isEmpty else { return body }

        let yaml = frontmatter
            .sorted(by: { $0.key < $1.key })
            .map { key, value in
                // 배열 형태([ ])는 그대로, 나머지는 따옴표 감싸기
                if value.hasPrefix("[") && value.hasSuffix("]") {
                    return "\(key): \(value)"
                }
                return "\(key): \"\(value)\""
            }
            .joined(separator: "\n")

        return "---\n\(yaml)\n---\n\n\(body)\n"
    }

    /// 파일명에 사용할 수 있는 slug 생성
    static func slugify(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-가-힣ㄱ-ㅎㅏ-ㅣ"))
        return text
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .lowercased()
            .prefix(50)
            .description
    }
}
