//
//  deekseepService.swift
//  deekseep
//
//  Created by Goge on 2025/4/11.
//

import Foundation

struct DeekseepService {
    private let baseURL = URL(string: "https://api.deepseek.com/v1")!

    private let modelNameMapping: [String: String] = [
        "DeekSeep-V3": "deepseek-chat",
        "DeekSeep-R1": "deepseek-coder"
    ]

    // Function to get the API model name from UI model name
    private func getAPIModelName(_ uiModelName: String) -> String {
        return modelNameMapping[uiModelName] ?? "deepseek-chat"
    }

    struct RequestBody: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case temperature
            case max_tokens
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(model, forKey: .model)
            try container.encode(messages, forKey: .messages)
            try container.encode(temperature, forKey: .temperature)
            try container.encode(max_tokens, forKey: .max_tokens)
        }
    }

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct ResponseBody: Decodable {
        let choices: [Choice]?
        let error: APIError?
    }

    struct Choice: Decodable {
        let message: Message?
    }

    struct APIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }

    func sendMessageToDeekseep(model: String, messages: [Message], systemPrompt: String? = nil) async throws -> String {
        // Check for API key in UserDefaults first, then fall back to APIKeys
        let storedApiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        let apiKey = !storedApiKey.isEmpty ? storedApiKey : APIKeys.deepSeekAPIKey
        
        guard !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let endpointURL = baseURL.appendingPathComponent("chat/completions")

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // --- Prepare messages for API ---
        var apiMessages = messages

        if let prompt = systemPrompt, !prompt.isEmpty {
            apiMessages.insert(Message(role: "system", content: prompt), at: 0)
        }
        // --------------------------------
        
        let apiModelName = getAPIModelName(model)
        
        let temperature = UserDefaults.standard.double(forKey: "modelTemperature")
        let maxTokens = UserDefaults.standard.integer(forKey: "modelMaxTokens")

        let requestBody = RequestBody(
            model: apiModelName,
            messages: apiMessages,
            temperature: temperature > 0 ? temperature : 0.7,
            max_tokens: maxTokens > 0 ? maxTokens : 4000 
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("Error encoding request body: \(error)")
            throw error
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            print("Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw Response: \(responseString)")
            }

            let decoder = JSONDecoder()
            let responseBody = try decoder.decode(ResponseBody.self, from: data)

            if let apiError = responseBody.error {
                 print("API Error: \(apiError.message) (Type: \(apiError.type ?? "N/A"), Code: \(apiError.code ?? "N/A"))")
                throw NSError(domain: "DeepSeekAPIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: apiError.message])
            }

            guard let firstChoice = responseBody.choices?.first, let message = firstChoice.message else {
                print("No valid choice or message found in response")
                throw URLError(.cannotParseResponse)
            }

            return message.content

        } catch {
            print("Networking or Parsing Error: \(error)")
            throw error
        }
    }
}
