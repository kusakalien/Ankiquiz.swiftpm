import Vision
import UIKit
import CoreGraphics

/// テキスト認識結果（位置情報付き）
struct RecognizedLine {
    let text: String
    let boundingBox: CGRect   // Vision座標系（左下原点、0〜1）
    let isHighlighted: Bool   // 赤字・色付きテキストか
}

enum TextRecognizer {

    // MARK: - Public API

    /// 画像からテキストを認識し、赤字・太字を検出してカードを生成する
    static func recognizeAndGenerateCards(
        from image: UIImage,
        completion: @escaping (String, [(front: String, back: String)]) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { completion("", []) }
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                DispatchQueue.main.async { completion("", []) }
                return
            }

            // 上から下にソート
            let sorted = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

            // 各テキスト行の色を分析
            var lines: [RecognizedLine] = []
            for obs in sorted {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let isHighlighted = isColoredText(observation: obs, in: cgImage)
                lines.append(RecognizedLine(
                    text: candidate.string,
                    boundingBox: obs.boundingBox,
                    isHighlighted: isHighlighted
                ))
            }

            let fullText = lines.map(\.text).joined(separator: "\n")
            let cards = generateCardsFromLines(lines)

            DispatchQueue.main.async { completion(fullText, cards) }
        }

        request.recognitionLanguages = ["ja", "en"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // MARK: - 色検出

    /// テキスト領域のピクセルカラーを分析して、赤字・色付きテキストかどうか判定する
    private static func isColoredText(observation: VNRecognizedTextObservation, in cgImage: CGImage) -> Bool {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        // Vision座標（左下原点 0〜1）→ ピクセル座標に変換
        let box = observation.boundingBox
        let pixelX = Int(box.origin.x * imageWidth)
        let pixelY = Int((1.0 - box.origin.y - box.height) * imageHeight)
        let pixelW = max(1, Int(box.width * imageWidth))
        let pixelH = max(1, Int(box.height * imageHeight))

        // 画像範囲にクランプ
        let cropRect = CGRect(
            x: max(0, pixelX),
            y: max(0, pixelY),
            width: min(pixelW, cgImage.width - max(0, pixelX)),
            height: min(pixelH, cgImage.height - max(0, pixelY))
        )

        guard cropRect.width > 0, cropRect.height > 0,
              let cropped = cgImage.cropping(to: cropRect) else {
            return false
        }

        return analyzeTextColor(in: cropped)
    }

    /// クロップされたテキスト領域の色を分析する
    private static func analyzeTextColor(in cgImage: CGImage) -> Bool {
        let width = cgImage.width
        let height = cgImage.height
        let totalPixels = width * height

        guard totalPixels > 0 else { return false }

        // ビットマップコンテキストを作成してピクセルデータを取得
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return false }
        let pixels = data.bindMemory(to: UInt8.self, capacity: totalPixels * 4)

        // テキストピクセル（暗い部分）の色を集計
        var coloredCount = 0
        var darkPixelCount = 0

        // サンプリング（大きい画像はスキップ）
        let step = max(1, totalPixels / 2000)

        for i in stride(from: 0, to: totalPixels, by: step) {
            let offset = i * 4
            let r = Float(pixels[offset])
            let g = Float(pixels[offset + 1])
            let b = Float(pixels[offset + 2])

            let brightness = (r + g + b) / (3.0 * 255.0)

            // 暗めのピクセル＝テキスト部分を分析
            if brightness < 0.65 {
                darkPixelCount += 1

                // 赤系: Rが高く、G/Bが低い
                let isRed = r > 120 && r > g * 1.6 && r > b * 1.6

                // 青系: Bが高く、R/Gが低い
                let isBlue = b > 120 && b > r * 1.4 && b > g * 1.3

                // 緑系: Gが高く、R/Bが低い
                let isGreen = g > 100 && g > r * 1.4 && g > b * 1.4

                // オレンジ/マゼンタなど鮮やかな色
                let maxC = max(r, g, b)
                let minC = min(r, g, b)
                let saturation = maxC > 0 ? (maxC - minC) / maxC : 0
                let isVivid = saturation > 0.4 && maxC > 100

                if isRed || isBlue || isGreen || isVivid {
                    coloredCount += 1
                }
            }
        }

        // 暗いピクセルの30%以上が色付き→色付きテキストと判定
        guard darkPixelCount > 5 else { return false }
        let colorRatio = Float(coloredCount) / Float(darkPixelCount)
        return colorRatio > 0.30
    }

    // MARK: - カード生成

    /// ハイライトされた行をキーワードとして、前後の文脈から定義を抽出する
    private static func generateCardsFromLines(_ lines: [RecognizedLine]) -> [(front: String, back: String)] {
        var cards: [(front: String, back: String)] = []

        let highlightedIndices = lines.enumerated().compactMap { $0.element.isHighlighted ? $0.offset : nil }

        if highlightedIndices.isEmpty {
            // ハイライトが見つからない場合は従来のテキストパターンマッチにフォールバック
            return generateCardsByPattern(lines.map(\.text))
        }

        for idx in highlightedIndices {
            let keyword = lines[idx].text.trimmingCharacters(in: .whitespacesAndNewlines)

            // 短すぎるまたは長すぎるキーワードはスキップ
            guard keyword.count >= 1 && keyword.count <= 50 else { continue }

            // 前後の通常テキスト行から文脈を収集
            let context = collectContext(around: idx, in: lines, keyword: keyword)

            if !context.isEmpty {
                cards.append((front: keyword, back: context))
            }
        }

        return cards
    }

    /// 指定インデックス前後の通常テキストから文脈を収集する
    private static func collectContext(around index: Int, in lines: [RecognizedLine], keyword: String) -> String {
        var contextParts: [String] = []
        let searchRange = 3 // 前後3行を探索

        // キーワードと同じ行に定義が含まれている場合（「用語：定義」パターン）
        let currentText = lines[index].text
        if let extracted = extractDefinitionFromLine(currentText, keyword: keyword) {
            return extracted
        }

        // 後方の通常テキスト行を収集
        for i in (index + 1)..<min(index + 1 + searchRange, lines.count) {
            if lines[i].isHighlighted { break } // 次のハイライトに到達したら停止
            let text = lines[i].text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                contextParts.append(text)
            }
        }

        // 後方で見つからなければ前方も探索
        if contextParts.isEmpty {
            for i in stride(from: index - 1, through: max(0, index - searchRange), by: -1) {
                if lines[i].isHighlighted { break }
                let text = lines[i].text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    contextParts.insert(text, at: 0)
                }
            }
        }

        return contextParts.joined(separator: " ")
    }

    /// 同一行内から「キーワード：定義」パターンの定義部分を抽出する
    private static func extractDefinitionFromLine(_ line: String, keyword: String) -> String? {
        let delimiters = ["：", ":", "→", "⇒", " - ", "＝", "=", "…", "─", "−"]
        for delimiter in delimiters {
            let parts = line.components(separatedBy: delimiter)
            if parts.count >= 2 {
                let back = parts.dropFirst().joined(separator: delimiter).trimmingCharacters(in: .whitespaces)
                if !back.isEmpty && back != keyword {
                    return back
                }
            }
        }
        return nil
    }

    // MARK: - フォールバック: テキストパターンマッチ

    /// ハイライトがない場合のフォールバック
    private static func generateCardsByPattern(_ texts: [String]) -> [(front: String, back: String)] {
        let lines = texts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var cards: [(front: String, back: String)] = []

        for line in lines {
            if let card = splitByDelimiter(line) {
                cards.append(card)
            }
        }

        if cards.isEmpty && lines.count >= 2 {
            for i in stride(from: 0, to: lines.count - 1, by: 2) {
                let front = stripNumberPrefix(lines[i])
                let back = stripNumberPrefix(lines[i + 1])
                if !front.isEmpty && !back.isEmpty {
                    cards.append((front: front, back: back))
                }
            }
        }

        return cards
    }

    private static func splitByDelimiter(_ line: String) -> (front: String, back: String)? {
        let delimiters = ["：", ":", "→", "⇒", " - ", "＝", "="]
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

    private static func stripNumberPrefix(_ text: String) -> String {
        text.replacingOccurrences(of: "^[0-9０-９]+[.．)）、\\s]+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
