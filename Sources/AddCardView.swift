import SwiftUI

struct AddCardView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) private var dismiss
    let deckID: UUID

    @State private var front = ""
    @State private var back = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("表面（質問）") {
                    TextField("質問を入力", text: $front)
                }
                Section("裏面（答え）") {
                    TextField("答えを入力", text: $back)
                }
            }
            .navigationTitle("カードを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let card = Flashcard(front: front, back: back)
                        store.addCard(to: deckID, card: card)
                        dismiss()
                    }
                    .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty ||
                              back.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
