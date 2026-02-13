import Foundation
import UIKit

enum ClaudeAPIService {
    private static let apiURL = "https://api.anthropic.com/v1/messages"
    private static let model = "claude-haiku-4-5-20251001"

    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: "AnkiQuiz_ClaudeAPIKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "AnkiQuiz_ClaudeAPIKey") }
    }

    static var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 画像を分析してフラッシュカードを生成する
    static func generateCards(
        from image: UIImage,
        completion: @escaping (Result<[(front: String, back: String)], Error>) -> Void
    ) {
        guard hasAPIKey else {
            completion(.failure(APIError.noAPIKey))
            return
        }

        // 画像をリサイズしてbase64エンコード
        guard let base64 = encodeImage(image) else {
            completion(.failure(APIError.imageEncodingFailed))
            return
        }

        let prompt = """
        この画像は教科書や参考書のページです。
        画像の中から重要な用語・キーワード（特に赤字、太字、色付きの文字）を見つけ、
        それぞれの用語について、画像内の文脈からその意味や定義を読み取ってください。

        以下のJSON形式で出力してください（他のテキストは一切不要です）：
        [{"front":"用語","back":"意味・定義"},{"front":"用語2","back":"意味・定義2"}]

        ルール：
        - frontには用語・キーワードを入れる
        - backにはその用語の意味・定義・説明を入れる（画像内の文脈から読み取る）
        - 重要でない用語は含めない
        - JSON配列のみを出力し、他の文章は含めない
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody),
              let url = URL(string: apiURL) else {
            completion(.failure(APIError.requestFailed))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(APIError.noResponse)) }
                return
            }

            // レスポンスをパース
            do {
                let cards = try parseResponse(data)
                DispatchQueue.main.async { completion(.success(cards)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Private

    private static func encodeImage(_ image: UIImage) -> String? {
        // 長辺を1200pxにリサイズしてJPEG圧縮
        let maxDimension: CGFloat = 1200
        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = min(1.0, maxDimension / image.size.width)
        } else {
            scale = min(1.0, maxDimension / image.size.height)
        }
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: 0.7)?.base64EncodedString()
    }

    private static func parseResponse(_ data: Data) throws -> [(front: String, back: String)] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String else {

            // エラーレスポンスをチェック
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError.apiError(message)
            }
            throw APIError.parseFailed
        }

        // JSON配列部分を抽出（前後に余計なテキストがある場合に対応）
        let jsonText = extractJSONArray(from: text)

        guard let jsonData = jsonText.data(using: .utf8),
              let cards = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]] else {
            throw APIError.parseFailed
        }

        return cards.compactMap { dict in
            guard let front = dict["front"], let back = dict["back"],
                  !front.isEmpty, !back.isEmpty else { return nil }
            return (front: front, back: back)
        }
    }

    /// テキストからJSON配列部分を抽出する
    private static func extractJSONArray(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // ```json ... ``` ブロックを検出
        if let codeBlockRange = trimmed.range(of: "```(?:json)?\\s*\\n?(\\[.*?\\])\\s*\\n?```",
                                                options: [.regularExpression, .dotMatchesLineSeparators]) {
            let match = String(trimmed[codeBlockRange])
            if let start = match.firstIndex(of: "["),
               let end = match.lastIndex(of: "]") {
                return String(match[start...end])
            }
        }

        // [ ... ] を直接探す
        if let start = trimmed.firstIndex(of: "["),
           let end = trimmed.lastIndex(of: "]") {
            return String(trimmed[start...end])
        }

        return trimmed
    }

    enum APIError: LocalizedError {
        case noAPIKey
        case imageEncodingFailed
        case requestFailed
        case noResponse
        case parseFailed
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "APIキーが設定されていません"
            case .imageEncodingFailed: return "画像の変換に失敗しました"
            case .requestFailed: return "リクエストの作成に失敗しました"
            case .noResponse: return "サーバーから応答がありませんでした"
            case .parseFailed: return "AIの応答を解析できませんでした"
            case .apiError(let msg): return "API エラー: \(msg)"
            }
        }
    }
}
