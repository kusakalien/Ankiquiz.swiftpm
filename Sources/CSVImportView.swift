import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) private var dismiss
    let deckID: UUID

    @State private var showingFilePicker = false
    @State private var importedCards: [CardDraft] = []
    @State private var errorMessage = ""
    @State private var phase: Phase = .pick

    enum Phase {
        case pick
        case review
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .pick:
                    pickPhase
                case .review:
                    reviewPhase
                }
            }
            .navigationTitle("CSVからカード作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    // MARK: - ファイル選択

    private var pickPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 72))
                .foregroundStyle(.indigo)
            Text("CSVファイルからカードを作成")
                .font(.title3)
                .fontWeight(.semibold)
            VStack(spacing: 8) {
                Text("CSVの形式：")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("用語, 説明")
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
            Button {
                showingFilePicker = true
            } label: {
                Label("CSVファイルを選択", systemImage: "folder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - カード確認

    private var reviewPhase: some View {
        VStack(spacing: 0) {
            if importedCards.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("カードが見つかりませんでした")
                        .font(.headline)
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Button("別のファイルを選択") {
                        phase = .pick
                        errorMessage = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    Spacer()
                }
            } else {
                cardList
            }
        }
    }

    private var cardList: some View {
        VStack(spacing: 0) {
            List {
                Section("\(importedCards.filter(\.isSelected).count)/\(importedCards.count)枚 選択中") {
                    ForEach($importedCards) { $card in
                        CardDraftRow(card: $card)
                    }
                    .onDelete { indexSet in
                        importedCards.remove(atOffsets: indexSet)
                    }
                }
            }

            VStack(spacing: 8) {
                Button {
                    addSelectedCards()
                } label: {
                    Text("選択したカードを追加")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(importedCards.filter(\.isSelected).isEmpty)

                Button("別のファイルを選択") {
                    phase = .pick
                    importedCards = []
                    errorMessage = ""
                }
                .font(.subheadline)
            }
            .padding()
            .background(.bar)
        }
    }

    // MARK: - Actions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        errorMessage = ""

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "ファイルへのアクセスが許可されていません"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let cards = parseCSV(content)
                importedCards = cards
                phase = .review
            } catch {
                errorMessage = "ファイルの読み込みに失敗しました"
            }

        case .failure:
            errorMessage = "ファイルの選択に失敗しました"
        }
    }

    private func parseCSV(_ content: String) -> [CardDraft] {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var cards: [CardDraft] = []

        for line in lines {
            // 最初のカンマで分割（説明にカンマが含まれる場合に対応）
            guard let commaIndex = line.firstIndex(of: ",") else { continue }

            let front = String(line[line.startIndex..<commaIndex])
                .trimmingCharacters(in: .whitespaces)
            let back = String(line[line.index(after: commaIndex)...])
                .trimmingCharacters(in: .whitespaces)

            if !front.isEmpty && !back.isEmpty {
                cards.append(CardDraft(front: front, back: back))
            }
        }

        return cards
    }

    private func addSelectedCards() {
        let selected = importedCards.filter(\.isSelected)
        for card in selected {
            let flashcard = Flashcard(front: card.front, back: card.back)
            store.addCard(to: deckID, card: flashcard)
        }
        dismiss()
    }
}

// MARK: - Card Draft Model

struct CardDraft: Identifiable {
    let id = UUID()
    var front: String
    var back: String
    var isSelected: Bool = true
}

// MARK: - Card Draft Row

struct CardDraftRow: View {
    @Binding var card: CardDraft

    var body: some View {
        HStack(spacing: 12) {
            Button {
                card.isSelected.toggle()
            } label: {
                Image(systemName: card.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(card.isSelected ? .indigo : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                TextField("表面", text: $card.front)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Divider()
                TextField("裏面", text: $card.back)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(card.isSelected ? 1.0 : 0.5)
    }
}
