import Foundation

struct OllamaRequest: Encodable {
    let model: String
    let system: String
    let prompt: String
    let stream: Bool
    let format: String?
}

struct OllamaResponse: Decodable {
    let response: String
}

enum ZotaError: LocalizedError {
    case invalidResponse
    case ollamaNotRunning
    case promptNotFound(String)
    case dailyNoteNotFound
    case vaultNotConfigured

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Ollama 응답을 파싱할 수 없습니다"
        case .ollamaNotRunning: return "Ollama 서버에 연결할 수 없습니다"
        case .promptNotFound(let name): return "프롬프트 파일을 찾을 수 없습니다: \(name)"
        case .dailyNoteNotFound: return "데일리 노트를 찾을 수 없습니다"
        case .vaultNotConfigured: return "Vault 경로가 설정되지 않았습니다"
        }
    }
}

class OllamaService {
    let baseURL: URL
    let model: String

    init(baseURL: URL, model: String = "llama3") {
        self.baseURL = baseURL
        self.model = model
    }

    /// Ollama 서버 연결 + 모델 존재 여부 확인
    func healthCheck() async -> HealthStatus {
        do {
            var request = URLRequest(url: baseURL)
            request.timeoutInterval = 5
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return .serverUnavailable
            }
        } catch {
            return .serverUnavailable
        }

        let models = await listModels()
        if models.contains(where: { $0 == model || $0.hasPrefix("\(model):") }) {
            return .ready
        } else {
            return .modelNotFound(model)
        }
    }

    enum HealthStatus: Equatable {
        case ready
        case serverUnavailable
        case modelNotFound(String)
    }

    /// Ollama에 프롬프트를 보내고 JSON 응답을 받는다
    func generate<T: Decodable>(
        prompt: String,
        system: String = "",
        responseType: T.Type,
        timeout: TimeInterval = 30
    ) async throws -> T {
        let ollamaRequest = OllamaRequest(
            model: model,
            system: system,
            prompt: prompt,
            stream: false,
            format: "json"
        )

        let url = baseURL.appendingPathComponent("api/generate")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(ollamaRequest)
        urlRequest.timeoutInterval = timeout

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)

        guard let responseData = ollamaResponse.response.data(using: .utf8) else {
            throw ZotaError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: responseData)
    }

    /// 설치된 모델 목록 조회
    func listModels() async -> [String] {
        do {
            let url = baseURL.appendingPathComponent("api/tags")
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, _) = try await URLSession.shared.data(for: request)

            struct ModelsResponse: Decodable {
                struct Model: Decodable {
                    let name: String
                }
                let models: [Model]
            }

            let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
            return response.models.map(\.name)
        } catch {
            return []
        }
    }
}
