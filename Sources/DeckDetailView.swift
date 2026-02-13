import SwiftUI

struct DeckDetailView: View {
    @EnvironmentObject var store: DeckStore
    let deck: Deck
    @State private var showingAddCard = false

    private var currentDeck: Deck {
        store.decks.first(where: { $0.id == deck.id }) ?? deck
    }

    var body: some View {
        List {
            Section {
                HStack {
                    StatCard(title: "全カード", value: "\(currentDeck.cards.count)", icon: "rectangle.on.rectangle", color: .indigo)
                    StatCard(title: "復習待ち", value: "\(currentDeck.dueCardCount)", icon: "clock", color: .orange)
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

            Section("カード一覧") {
                if currentDeck.cards.isEmpty {
                    Text("カードがありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(currentDeck.cards) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.front)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(card.back)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let card = currentDeck.cards[index]
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

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(4)
    }
}
