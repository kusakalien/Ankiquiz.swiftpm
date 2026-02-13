import Foundation

struct Flashcard: Identifiable, Codable {
    let id: UUID
    var front: String
    var back: String
    var isMastered: Bool     // 習得済みフラグ

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        isMastered: Bool = false
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.isMastered = isMastered
    }

    /// 復習待ち = 習得済みでないカード
    var isDue: Bool {
        !isMastered
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
        cards.filter { !$0.isMastered }.count
    }

    var dueCards: [Flashcard] {
        cards.filter { !$0.isMastered }
    }

    var masteredCardCount: Int {
        cards.filter(\.isMastered).count
    }

    var masteredCards: [Flashcard] {
        cards.filter(\.isMastered)
    }
}
