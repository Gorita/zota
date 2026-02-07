import XCTest
@testable import Zota

final class DailyReviewTests: XCTestCase {

    // MARK: - DailyReviewResult JSON 디코딩 테스트

    func testDailyReviewResult_decodesFromJSON() throws {
        let json = """
        {
            "achievements": ["PR 리뷰 완료", "SwiftUI 학습"],
            "ideas": ["새 기능 제안"],
            "todos": ["주간 회고 작성"],
            "summary": "코드 리뷰와 학습을 진행한 하루"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(DailyReviewResult.self, from: json)

        XCTAssertEqual(result.achievements, ["PR 리뷰 완료", "SwiftUI 학습"])
        XCTAssertEqual(result.ideas, ["새 기능 제안"])
        XCTAssertEqual(result.todos, ["주간 회고 작성"])
        XCTAssertEqual(result.summary, "코드 리뷰와 학습을 진행한 하루")
    }

    func testDailyReviewResult_decodesWithEmptyArrays() throws {
        let json = """
        {
            "achievements": [],
            "ideas": [],
            "todos": [],
            "summary": "특별한 활동이 없었던 하루"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(DailyReviewResult.self, from: json)

        XCTAssertTrue(result.achievements.isEmpty)
        XCTAssertTrue(result.ideas.isEmpty)
        XCTAssertTrue(result.todos.isEmpty)
        XCTAssertEqual(result.summary, "특별한 활동이 없었던 하루")
    }

    // MARK: - DailyReviewResult → 마크다운 변환 테스트

    func testDailyReviewResult_toMarkdown() throws {
        let result = DailyReviewResult(
            achievements: ["PR 리뷰 완료", "SwiftUI 학습"],
            ideas: ["새 기능 제안"],
            todos: ["주간 회고 작성"],
            summary: "코드 리뷰와 학습을 진행한 하루"
        )

        let markdown = result.toMarkdown()

        XCTAssertTrue(markdown.contains("## Daily Review"))
        XCTAssertTrue(markdown.contains("### 오늘의 성과"))
        XCTAssertTrue(markdown.contains("- PR 리뷰 완료"))
        XCTAssertTrue(markdown.contains("- SwiftUI 학습"))
        XCTAssertTrue(markdown.contains("### 아이디어"))
        XCTAssertTrue(markdown.contains("- 새 기능 제안"))
        XCTAssertTrue(markdown.contains("### 할 일"))
        XCTAssertTrue(markdown.contains("- [ ] 주간 회고 작성"))
        XCTAssertTrue(markdown.contains("> 코드 리뷰와 학습을 진행한 하루"))
    }

    func testDailyReviewResult_toMarkdown_skipsEmptySections() throws {
        let result = DailyReviewResult(
            achievements: ["무언가 완료"],
            ideas: [],
            todos: [],
            summary: "요약"
        )

        let markdown = result.toMarkdown()

        XCTAssertTrue(markdown.contains("### 오늘의 성과"))
        XCTAssertFalse(markdown.contains("### 아이디어"))
        XCTAssertFalse(markdown.contains("### 할 일"))
        XCTAssertTrue(markdown.contains("> 요약"))
    }

    // MARK: - VaultService updateDailyReview 통합 테스트

    func testUpdateDailyReview_addsReviewSection() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZotaTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dailyDir = tempDir.appendingPathComponent("Daily")
        try FileManager.default.createDirectory(at: dailyDir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        let dailyContent = """
        ---
        date: \(todayString)
        ---

        ## Memos
        - 메모 1
        - 메모 2
        """

        let dailyPath = dailyDir.appendingPathComponent("\(todayString).md")
        try dailyContent.write(to: dailyPath, atomically: true, encoding: .utf8)

        let service = VaultService(vaultPath: tempDir)
        let reviewContent = "## Daily Review\n\n### 오늘의 성과\n- 메모 1 완료"
        try service.updateDailyReview(for: Date(), reviewContent: reviewContent)

        let updated = try String(contentsOf: dailyPath, encoding: .utf8)
        XCTAssertTrue(updated.contains("## Daily Review"))
        XCTAssertTrue(updated.contains("### 오늘의 성과"))
        XCTAssertTrue(updated.contains("## Memos"))
    }

    func testUpdateDailyReview_replacesExistingReview() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZotaTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dailyDir = tempDir.appendingPathComponent("Daily")
        try FileManager.default.createDirectory(at: dailyDir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        let dailyContent = """
        ---
        date: \(todayString)
        ---

        ## Memos
        - 메모 1

        ## Daily Review

        ### 오늘의 성과
        - 이전 리뷰 내용
        """

        let dailyPath = dailyDir.appendingPathComponent("\(todayString).md")
        try dailyContent.write(to: dailyPath, atomically: true, encoding: .utf8)

        let service = VaultService(vaultPath: tempDir)
        let newReview = "## Daily Review\n\n### 오늘의 성과\n- 새 리뷰 내용"
        try service.updateDailyReview(for: Date(), reviewContent: newReview)

        let updated = try String(contentsOf: dailyPath, encoding: .utf8)
        XCTAssertTrue(updated.contains("새 리뷰 내용"))
        XCTAssertFalse(updated.contains("이전 리뷰 내용"))
    }
}
