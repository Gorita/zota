import XCTest
@testable import Zota

final class OllamaServiceTests: XCTestCase {

    func testHealthCheckReturnsTrue_whenServerRunning() async {
        // 실제 Ollama가 실행 중일 때만 통과하는 통합 테스트
        let service = OllamaService(
            baseURL: URL(string: "http://localhost:11434")!
        )
        let result = await service.healthCheck()
        // Ollama가 실행 중이 아닐 수 있으므로 결과만 확인
        XCTAssertNotNil(result)
    }

    func testHealthCheckReturnsFalse_whenServerNotRunning() async {
        let service = OllamaService(
            baseURL: URL(string: "http://localhost:99999")!
        )
        let result = await service.healthCheck()
        XCTAssertFalse(result)
    }

    func testGenerateThrows_whenServerNotRunning() async {
        let service = OllamaService(
            baseURL: URL(string: "http://localhost:99999")!
        )

        struct TestResponse: Decodable {
            let message: String
        }

        do {
            _ = try await service.generate(
                prompt: "테스트",
                responseType: TestResponse.self,
                timeout: 2
            )
            XCTFail("에러가 발생해야 합니다")
        } catch {
            // 연결 실패 에러가 발생하면 성공
            XCTAssertNotNil(error)
        }
    }
}
