import XCTest
@testable import Zota

final class MarkdownParserTests: XCTestCase {

    func testParse_withValidFrontmatter() {
        let content = """
        ---
        title: "테스트 노트"
        date: 2026-02-07
        tags: ["개발", "학습"]
        ---

        본문 내용입니다.
        """

        let (frontmatter, body) = MarkdownParser.parse(content: content)

        XCTAssertEqual(frontmatter["title"], "테스트 노트")
        XCTAssertEqual(frontmatter["date"], "2026-02-07")
        XCTAssertEqual(frontmatter["tags"], "[\"개발\", \"학습\"]")
        XCTAssertTrue(body.contains("본문 내용입니다."))
    }

    func testParse_withoutFrontmatter() {
        let content = "그냥 텍스트만 있는 파일"

        let (frontmatter, body) = MarkdownParser.parse(content: content)

        XCTAssertTrue(frontmatter.isEmpty)
        XCTAssertEqual(body, content)
    }

    func testParse_withEmptyContent() {
        let (frontmatter, body) = MarkdownParser.parse(content: "")

        XCTAssertTrue(frontmatter.isEmpty)
        XCTAssertEqual(body, "")
    }

    func testCompose_createsValidMarkdown() {
        let frontmatter = ["title": "테스트", "date": "2026-02-07"]
        let body = "본문입니다."

        let result = MarkdownParser.compose(frontmatter: frontmatter, body: body)

        XCTAssertTrue(result.hasPrefix("---\n"))
        XCTAssertTrue(result.contains("title: \"테스트\""))
        XCTAssertTrue(result.contains("date: \"2026-02-07\""))
        XCTAssertTrue(result.contains("본문입니다."))
    }

    func testCompose_preservesArrayFormat() {
        let frontmatter = ["tags": "[\"개발\", \"학습\"]"]
        let body = "내용"

        let result = MarkdownParser.compose(frontmatter: frontmatter, body: body)

        // 배열은 따옴표로 감싸지 않아야 한다
        XCTAssertTrue(result.contains("tags: [\"개발\", \"학습\"]"))
    }

    func testSlugify_withKorean() {
        let result = MarkdownParser.slugify("Swift 학습 노트")
        XCTAssertEqual(result, "swift-학습-노트")
    }

    func testSlugify_withSpecialCharacters() {
        let result = MarkdownParser.slugify("Hello, World! @#$%")
        XCTAssertEqual(result, "hello-world")
    }

    func testSlugify_withEmptyString() {
        let result = MarkdownParser.slugify("")
        XCTAssertEqual(result, "")
    }
}
