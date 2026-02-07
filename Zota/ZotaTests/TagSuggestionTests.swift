import XCTest
@testable import Zota

final class TagSuggestionTests: XCTestCase {

    // MARK: - TagSuggestionResult JSON 디코딩

    func testTagSuggestionResult_decodesFromJSON() throws {
        let json = """
        {"tags": ["개발", "학습"]}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TagSuggestionResult.self, from: json)

        XCTAssertEqual(result.tags, ["개발", "학습"])
    }

    func testTagSuggestionResult_decodesEmptyArray() throws {
        let json = """
        {"tags": []}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TagSuggestionResult.self, from: json)

        XCTAssertTrue(result.tags.isEmpty)
    }

    // MARK: - 태그 필터링 (허용된 태그만)

    func testTagSuggestionResult_filteredTags_onlyReturnsAllowedTags() {
        let result = TagSuggestionResult(tags: ["개발", "학습", "존재하지않는태그"])
        let allowed = ["개발", "디자인", "업무", "학습"]

        let filtered = result.filteredTags(allowedTags: allowed)

        XCTAssertEqual(filtered, ["개발", "학습"])
    }

    func testTagSuggestionResult_filteredTags_returnsEmptyWhenNoneMatch() {
        let result = TagSuggestionResult(tags: ["없는태그1", "없는태그2"])
        let allowed = ["개발", "디자인"]

        let filtered = result.filteredTags(allowedTags: allowed)

        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - Tagger 프롬프트 빌드

    func testBuildTaggerPrompt_includesTagsAndContent() {
        let prompt = TagSuggestionResult.buildPrompt(
            title: "SwiftUI 학습",
            content: "NavigationStack 정리",
            availableTags: ["개발", "학습", "도구"]
        )

        XCTAssertTrue(prompt.contains("SwiftUI 학습"))
        XCTAssertTrue(prompt.contains("NavigationStack 정리"))
        XCTAssertTrue(prompt.contains("개발"))
        XCTAssertTrue(prompt.contains("학습"))
        XCTAssertTrue(prompt.contains("도구"))
    }
}
