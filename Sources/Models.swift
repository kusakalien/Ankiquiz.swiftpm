import Foundation

struct Flashcard: Identifiable, Codable {
    let id: UUID
    var front: String
    var back: String
    var nextReviewDate: Date
    var interval: Int        // 復習間隔（日数）
    var easeFactor: Double   // 難易度係数
    var repetitions: Int     // 連続正解数

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        nextReviewDate: Date = Date(),
        interval: Int = 0,
        easeFactor: Double = 2.5,
        repetitions: Int = 0
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.nextReviewDate = nextReviewDate
        self.interval = interval
        self.easeFactor = easeFactor
        self.repetitions = repetitions
    }

    var isDue: Bool {
        nextReviewDate <= Date()
    }
}

struct Deck: Identifiable, Codable {
    let id: UUID
    var name: String
    var cards: [Flashcard]

    init(id: UUID = UUID(), name: String, cards: [Flashcard] = []) {
        self.id = id
        self.name = name
        self.cards = cards
    }

    var dueCardCount: Int {
        cards.filter(\.isDue).count
    }

    var dueCards: [Flashcard] {
        cards.filter(\.isDue)
    }
}

enum ReviewRating: Int, CaseIterable {
    case again = 0   // もう一度
    case hard = 1    // 難しい
    case good = 2    // 普通
    case easy = 3    // 簡単

    var label: String {
        switch self {
        case .again: return "もう一度"
        case .hard: return "難しい"
        case .good: return "普通"
        case .easy: return "簡単"
        }
    }

    var color: String {
        switch self {
        case .again: return "red"
        case .hard: return "orange"
        case .good: return "green"
        case .easy: return "blue"
        }
    }
}

/// SM-2アルゴリズムに基づくスペースドリピティション
enum SpacedRepetition {
    static func review(card: Flashcard, rating: ReviewRating) -> Flashcard {
        var updated = card
        let quality = Double(rating.rawValue)

        if rating == .again {
            updated.repetitions = 0
            updated.interval = 1
        } else {
            if updated.repetitions == 0 {
                updated.interval = 1
            } else if updated.repetitions == 1 {
                updated.interval = 6
            } else {
                updated.interval = Int(Double(updated.interval) * updated.easeFactor)
            }
            updated.repetitions += 1
        }

        // 難易度係数の更新
        let newEF = updated.easeFactor + (0.1 - (5.0 - quality * 1.25) * (0.08 + (5.0 - quality * 1.25) * 0.02))
        updated.easeFactor = max(1.3, newEF)

        // 次の復習日を設定
        updated.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: updated.interval,
            to: Date()
        ) ?? Date()

        return updated
    }
}
