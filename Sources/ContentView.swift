import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DeckStore
    @State private var showingAddDeck = false

    var body: some View {
        NavigationStack {
            Group {
                if store.decks.isEmpty {
                    emptyState
                } else {
                    deckList
                }
            }
            .navigationTitle("AnkiQuiz")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDeck) {
                AddDeckView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(.indigo)
            Text("デッキがありません")
                .font(.title2)
                .fontWeight(.semibold)
            Text("＋ボタンで新しいデッキを作成しましょう")
                .foregroundStyle(.secondary)
            Button("サンプルデッキを追加") {
                store.addSampleDeck()
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding()
    }

    private var deckList: some View {
        List {
            ForEach(store.decks) { deck in
                NavigationLink(destination: DeckDetailView(deck: deck)) {
                    DeckRow(deck: deck)
                }
            }
            .onDelete { indexSet in
                store.decks.remove(atOffsets: indexSet)
            }
        }
    }
}

struct DeckRow: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deck.name)
                .font(.headline)
            HStack(spacing: 12) {
                Label("\(deck.cards.count)枚", systemImage: "rectangle.on.rectangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if deck.dueCardCount > 0 {
                    Label("\(deck.dueCardCount)枚 復習待ち", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
