import XCTest
@testable import Zota

final class PromptServiceTests: XCTestCase {
    var tempDir: URL!
    var service: PromptService!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZotaTests-\(UUID().uuidString)")

        // System/Prompts 폴더 구조 생성
        let promptsDir = tempDir
            .appendingPathComponent("System")
            .appendingPathComponent("Prompts")
        try! FileManager.default.createDirectory(at: promptsDir, withIntermediateDirectories: true)

        service = PromptService(vaultPath: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadPrompt_returnsContent() throws {
        // Given: 프롬프트 파일이 존재
        let promptContent = """
        You are a personal assistant.
        Organize daily memos into categories.
        Output in JSON format.
        """
        let promptPath = tempDir
            .appendingPathComponent("System/Prompts/DailySummary.md")
        try promptContent.write(to: promptPath, atomically: true, encoding: .utf8)

        // When
        let loaded = try service.loadPrompt(named: "DailySummary")

        // Then
        XCTAssertEqual(loaded, promptContent)
    }

    func testLoadPrompt_throwsWhenFileNotFound() {
        // When/Then: 존재하지 않는 프롬프트
        XCTAssertThrowsError(try service.loadPrompt(named: "NonExistent")) { error in
            XCTAssertTrue(error is ZotaError)
            if case ZotaError.promptNotFound(let name) = error as! ZotaError {
                XCTAssertEqual(name, "NonExistent")
            } else {
                XCTFail("promptNotFound 에러여야 합니다")
            }
        }
    }

    func testLoadPrompt_handlesKoreanFilename() throws {
        // Given: 한국어 이름의 프롬프트 파일
        let promptContent = "한국어 프롬프트 내용"
        let promptPath = tempDir
            .appendingPathComponent("System/Prompts/데일리요약.md")
        try promptContent.write(to: promptPath, atomically: true, encoding: .utf8)

        // When
        let loaded = try service.loadPrompt(named: "데일리요약")

        // Then
        XCTAssertEqual(loaded, promptContent)
    }
}
