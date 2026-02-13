import SwiftUI

struct QuizView: View {
    @EnvironmentObject var store: DeckStore
    let deck: Deck
    @Environment(\.dismiss) private var dismiss

    @State private var dueCards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var isFinished = false
    @State private var reviewedCount = 0

    var body: some View {
        VStack {
            if isFinished || dueCards.isEmpty {
                finishedView
            } else {
                quizContent
            }
        }
        .navigationTitle("クイズ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dueCards = deck.dueCards.shuffled()
        }
    }

    private var quizContent: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(reviewedCount), total: Double(dueCards.count))
                .tint(.indigo)
                .padding(.horizontal)

            Text("\(reviewedCount + 1) / \(dueCards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            cardView
                .onTapGesture {
                    withAnimation(.spring(response: 0.4)) {
                        isFlipped = true
                    }
                }

            Spacer()

            if isFlipped {
                answerButtons
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("タップしてめくる")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .padding()
    }

    private var cardView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.indigo.opacity(0.3), lineWidth: 1)

            VStack(spacing: 12) {
                if !isFlipped {
                    Text("表")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                        .textCase(.uppercase)
                    Text(dueCards[currentIndex].front)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                } else {
                    Text("裏")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .textCase(.uppercase)
                    Text(dueCards[currentIndex].back)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
    }

    private var answerButtons: some View {
        HStack(spacing: 16) {
            Button {
                answerCard(mastered: false)
            } label: {
                Label("覚えてない", systemImage: "xmark.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button {
                answerCard(mastered: true)
            } label: {
                Label("覚えた", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
    }

    private var finishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("完了！")
                .font(.title)
                .fontWeight(.bold)
            Text("全\(max(reviewedCount, dueCards.count))枚のカードを復習しました")
                .foregroundStyle(.secondary)
            Button("戻る") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
    }

    private func answerCard(mastered: Bool) {
        var card = dueCards[currentIndex]
        card.isMastered = mastered
        store.updateCard(deckID: deck.id, card: card)

        reviewedCount += 1
        isFlipped = false

        if currentIndex + 1 < dueCards.count {
            currentIndex += 1
        } else {
            withAnimation {
                isFinished = true
            }
        }
    }
}
