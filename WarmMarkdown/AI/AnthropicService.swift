import Foundation

// MARK: - Errors

enum AnthropicError: Error {
    case missingAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(Int, String)
}

// MARK: - Response types

struct AnthropicComment: Decodable {
    let anchorText: String
    let comment: String
}

// MARK: - Service

final class AnthropicService {
    static let shared = AnthropicService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    // API key stored in UserDefaults for simplicity; swap for Keychain in production
    var apiKey: String? {
        get { UserDefaults.standard.string(forKey: "dev.warmmarkdown.anthropicAPIKey") }
        set { UserDefaults.standard.set(newValue, forKey: "dev.warmmarkdown.anthropicAPIKey") }
    }

    // MARK: - Inline provocation (single paragraph → one comment)

    func generateProvocation(for passage: String) async throws -> String {
        guard let key = apiKey, !key.isEmpty else { throw AnthropicError.missingAPIKey }

        let system = """
        You are a warm, intellectually curious writing companion. \
        Respond with a single provocative question or observation about this passage \
        that might push the writer's thinking deeper. \
        Be warm but challenging. Maximum 2 sentences. No compliments, no summaries.
        """

        return try await call(
            system: system,
            user: passage,
            apiKey: key,
            model: "claude-haiku-4-5-20251001",
            maxTokens: 150
        )
    }

    // MARK: - Coach pass (full document → 2-5 anchored comments)

    func runCoachPass(on document: String) async throws -> [AnthropicComment] {
        guard let key = apiKey, !key.isEmpty else { throw AnthropicError.missingAPIKey }

        let system = """
        You are a sharp, warm writing coach. You read drafts and leave marginal notes \
        that provoke the writer to think deeper, cut what isn't working, or pursue an idea further. \
        You never flatter. You ask questions more than you give answers.
        """

        let user = """
        Here is a document. Identify 2-5 moments where a marginal note would genuinely help \
        the writer. Return ONLY valid JSON — no markdown fences, no explanation — in this exact format:
        [{"anchorText": "exact phrase from document (10-15 words)", "comment": "provocation (max 2 sentences)"}]

        Document:
        \(document)
        """

        let raw = try await call(
            system: system,
            user: user,
            apiKey: key,
            model: "claude-sonnet-4-6",
            maxTokens: 1024
        )

        // Strip any accidental markdown fences before decoding
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let comments = try? JSONDecoder().decode([AnthropicComment].self, from: data) else {
            throw AnthropicError.invalidResponse
        }
        return comments
    }

    // MARK: - Private

    private func call(system: String, user: String, apiKey: String, model: String, maxTokens: Int) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [["role": "user", "content": user]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AnthropicError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw AnthropicError.invalidResponse }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw AnthropicError.apiError(http.statusCode, msg)
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first = content.first,
            let text = first["text"] as? String
        else { throw AnthropicError.invalidResponse }

        return text
    }
}
