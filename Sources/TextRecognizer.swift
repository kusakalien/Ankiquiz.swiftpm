import Vision
import UIKit

enum TextRecognizer {
    /// 画像からテキストを認識する
    static func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                DispatchQueue.main.async { completion("") }
                return
            }

            // Y座標で上から下にソート
            let sorted = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
            let text = sorted.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async { completion(text) }
        }

        // 日本語と英語を認識
        request.recognitionLanguages = ["ja", "en"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    /// 認識テキストからフラッシュカード候補を生成する
    static func generateCards(from text: String) -> [(front: String, back: String)] {
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var cards: [(front: String, back: String)] = []

        for line in lines {
            // 「用語：定義」または「用語: 定義」パターン
            if let card = splitByDelimiter(line, delimiters: ["：", ":", "→", "⇒", " - ", "＝", "="]) {
                cards.append(card)
                continue
            }

            // 「用語　定義」（全角スペース区切り）
            let fullWidthParts = line.components(separatedBy: "　").filter { !$0.isEmpty }
            if fullWidthParts.count == 2 {
                cards.append((front: fullWidthParts[0], back: fullWidthParts[1]))
                continue
            }
        }

        // パターンにマッチしない場合は2行ずつペアにする
        if cards.isEmpty && lines.count >= 2 {
            for i in stride(from: 0, to: lines.count - 1, by: 2) {
                let front = lines[i]
                    .replacingOccurrences(of: "^[0-9０-９]+[.．)）、\\s]+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                let back = lines[i + 1]
                    .replacingOccurrences(of: "^[0-9０-９]+[.．)）、\\s]+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !front.isEmpty && !back.isEmpty {
                    cards.append((front: front, back: back))
                }
            }
        }

        return cards
    }

    private static func splitByDelimiter(_ line: String, delimiters: [String]) -> (front: String, back: String)? {
        for delimiter in delimiters {
            let parts = line.components(separatedBy: delimiter)
            if parts.count >= 2 {
                let front = parts[0].trimmingCharacters(in: .whitespaces)
                let back = parts.dropFirst().joined(separator: delimiter).trimmingCharacters(in: .whitespaces)
                if !front.isEmpty && !back.isEmpty && front.count <= 100 {
                    return (front: front, back: back)
                }
            }
        }
        return nil
    }
}
