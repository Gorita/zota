import XCTest
@testable import Zota

final class VaultServiceTests: XCTestCase {
    var tempDir: URL!
    var service: VaultService!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZotaTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        service = VaultService(vaultPath: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testCreateNote_createsFileInInbox() throws {
        let filePath = try service.createNote(
            title: "테스트 메모",
            content: "내용입니다",
            tags: ["개발", "학습"]
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path))
        XCTAssertTrue(filePath.path.contains("Inbox/"))
        XCTAssertTrue(filePath.lastPathComponent.hasSuffix(".md"))

        let content = try String(contentsOf: filePath, encoding: .utf8)
        XCTAssertTrue(content.contains("title: \"테스트 메모\""))
        XCTAssertTrue(content.contains("내용입니다"))
        XCTAssertTrue(content.contains("개발"))
    }

    func testCreateNote_createsInboxFolderIfMissing() throws {
        let inboxPath = tempDir.appendingPathComponent("Inbox")
        XCTAssertFalse(FileManager.default.fileExists(atPath: inboxPath.path))

        _ = try service.createNote(title: "테스트", content: "내용")

        XCTAssertTrue(FileManager.default.fileExists(atPath: inboxPath.path))
    }

    func testCreateNote_withEmptyTitle_usesFallbackFilename() throws {
        let filePath = try service.createNote(title: "", content: "내용")

        XCTAssertTrue(filePath.lastPathComponent.contains("메모"))
    }

    func testCreateNote_withNoTags_createsEmptyTagsArray() throws {
        let filePath = try service.createNote(title: "테스트", content: "내용")

        let content = try String(contentsOf: filePath, encoding: .utf8)
        XCTAssertTrue(content.contains("tags: []"))
    }

    func testExtractMemos_fromDailyNote() throws {
        // 데일리 노트 생성
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
        - 첫 번째 메모
        - 두 번째 메모
        - 세 번째 메모

        ## Other Section
        - 이건 메모가 아님
        """

        let dailyPath = dailyDir.appendingPathComponent("\(todayString).md")
        try dailyContent.write(to: dailyPath, atomically: true, encoding: .utf8)

        let memos = try service.extractMemos(from: Date())

        XCTAssertEqual(memos.count, 3)
        XCTAssertEqual(memos[0], "첫 번째 메모")
        XCTAssertEqual(memos[1], "두 번째 메모")
        XCTAssertEqual(memos[2], "세 번째 메모")
    }

    func testExtractMemos_returnsEmptyWhenNoDaily() throws {
        let memos = try service.extractMemos(from: Date())
        XCTAssertTrue(memos.isEmpty)
    }

    func testIsValid_returnsTrueForExistingPath() {
        XCTAssertTrue(service.isValid)
    }

    func testIsValid_returnsFalseForNonExistingPath() {
        let badService = VaultService(vaultPath: URL(fileURLWithPath: "/nonexistent/path"))
        XCTAssertFalse(badService.isValid)
    }
}
