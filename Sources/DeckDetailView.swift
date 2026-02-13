import SwiftUI

enum CardFilter: String, CaseIterable {
    case all = "全カード"
    case due = "復習待ち"
    case mastered = "習得済み"
}

struct DeckDetailView: View {
    @EnvironmentObject var store: DeckStore
    let deck: Deck
    @State private var showingAddCard = false
    @State private var selectedFilter: CardFilter = .all

    private var currentDeck: Deck {
        store.decks.first(where: { $0.id == deck.id }) ?? deck
    }

    private var filteredCards: [Flashcard] {
        switch selectedFilter {
        case .all: return currentDeck.cards
        case .due: return currentDeck.dueCards
        case .mastered: return currentDeck.masteredCards
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    StatCard(
                        title: "全カード",
                        value: "\(currentDeck.cards.count)",
                        icon: "rectangle.on.rectangle",
                        color: .indigo,
                        isSelected: selectedFilter == .all
                    )
                    .onTapGesture { selectedFilter = .all }

                    StatCard(
                        title: "復習待ち",
                        value: "\(currentDeck.dueCardCount)",
                        icon: "clock",
                        color: .orange,
                        isSelected: selectedFilter == .due
                    )
                    .onTapGesture { selectedFilter = .due }

                    StatCard(
                        title: "習得済み",
                        value: "\(currentDeck.masteredCardCount)",
                        icon: "checkmark.circle",
                        color: .green,
                        isSelected: selectedFilter == .mastered
                    )
                    .onTapGesture { selectedFilter = .mastered }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if currentDeck.dueCardCount > 0 {
                    NavigationLink(destination: QuizView(deck: currentDeck)) {
                        Label("クイズを始める", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.indigo)
                    }
                }
            }

            Section(selectedFilter.rawValue) {
                if filteredCards.isEmpty {
                    Text("カードがありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredCards) { card in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.front)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(card.back)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if card.isMastered {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { indexSet in
                        let cardsToDelete = indexSet.map { filteredCards[$0] }
                        for card in cardsToDelete {
                            store.deleteCard(from: deck.id, cardID: card.id)
                        }
                    }
                }
            }
        }
        .navigationTitle(currentDeck.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardView(deckID: deck.id)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? color.opacity(0.2) : color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? color : .clear, lineWidth: 2)
        )
        .padding(2)
    }
}
