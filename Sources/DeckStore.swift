import SwiftUI

class DeckStore: ObservableObject {
    @Published var decks: [Deck] = [] {
        didSet { save() }
    }

    private let saveKey = "AnkiQuiz_Decks"

    init() {
        load()
    }

    func addDeck(_ deck: Deck) {
        decks.append(deck)
    }

    func updateCard(deckID: UUID, card: Flashcard) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckID }),
              let cardIndex = decks[deckIndex].cards.firstIndex(where: { $0.id == card.id }) else {
            return
        }
        decks[deckIndex].cards[cardIndex] = card
    }

    func addCard(to deckID: UUID, card: Flashcard) {
        guard let index = decks.firstIndex(where: { $0.id == deckID }) else { return }
        decks[index].cards.append(card)
    }

    func deleteCard(from deckID: UUID, cardID: UUID) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckID }) else { return }
        decks[deckIndex].cards.removeAll { $0.id == cardID }
    }

    func addSampleDeck() {
        let sampleCards = [
            Flashcard(front: "Swift", back: "Appleが開発したプログラミング言語"),
            Flashcard(front: "SwiftUI", back: "宣言的UIフレームワーク"),
            Flashcard(front: "Xcode", back: "Appleの統合開発環境"),
            Flashcard(front: "@State", back: "ビュー内で値の変更を監視するプロパティラッパー"),
            Flashcard(front: "@Binding", back: "親ビューの@Stateへの参照を持つプロパティラッパー"),
            Flashcard(front: "NavigationStack", back: "iOS 16以降のナビゲーション管理ビュー"),
            Flashcard(front: "ObservableObject", back: "データの変更をビューに通知するプロトコル"),
            Flashcard(front: "struct vs class", back: "structは値型、classは参照型"),
            Flashcard(front: "Optional", back: "値があるかnilかを表す型 (T?)"),
            Flashcard(front: "guard let", back: "条件を満たさない場合に早期リターンする制御構文"),
        ]
        let deck = Deck(name: "Swift基礎", cards: sampleCards)
        addDeck(deck)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(decks) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Deck].self, from: data) else {
            return
        }
        decks = decoded
    }
}
