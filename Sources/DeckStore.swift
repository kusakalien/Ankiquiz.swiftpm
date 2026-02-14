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
