import SwiftUI

struct PhotoCardGeneratorView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) private var dismiss
    let deckID: UUID

    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var generatedCards: [CardDraft] = []
    @State private var phase: Phase = .capture

    enum Phase {
        case capture    // 撮影前
        case processing // OCR処理中
        case review     // カード確認・編集
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .capture:
                    capturePhase
                case .processing:
                    processingPhase
                case .review:
                    reviewPhase
                }
            }
            .navigationTitle("写真からカード作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    capturedImage = image
                    processImage(image)
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - 撮影前

    private var capturePhase: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(.indigo)
            Text("教科書や参考書のページを撮影")
                .font(.title3)
                .fontWeight(.semibold)
            Text("テキストを認識して\n自動でカードを作成します")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                showingCamera = true
            } label: {
                Label("カメラで撮影", systemImage: "camera.fill")
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

    // MARK: - 処理中

    private var processingPhase: some View {
        VStack(spacing: 20) {
            Spacer()
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            }
            ProgressView()
                .scaleEffect(1.5)
            Text("テキストを認識中...")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - カード確認・編集

    private var reviewPhase: some View {
        VStack(spacing: 0) {
            if generatedCards.isEmpty {
                emptyResult
            } else {
                cardList
            }
        }
    }

    private var emptyResult: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("カードを生成できませんでした")
                .font(.headline)
            if !recognizedText.isEmpty {
                Text("認識されたテキスト:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ScrollView {
                    Text(recognizedText)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxHeight: 150)
                .padding(.horizontal)
            }
            Button("もう一度撮影") {
                phase = .capture
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            Spacer()
        }
    }

    private var cardList: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 120)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }

                Section("\(generatedCards.filter(\.isSelected).count)/\(generatedCards.count)枚 選択中") {
                    ForEach($generatedCards) { $card in
                        CardDraftRow(card: $card)
                    }
                    .onDelete { indexSet in
                        generatedCards.remove(atOffsets: indexSet)
                    }
                }
            }

            // 追加ボタン
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
                .disabled(generatedCards.filter(\.isSelected).isEmpty)

                Button("もう一度撮影") {
                    phase = .capture
                    generatedCards = []
                }
                .font(.subheadline)
            }
            .padding()
            .background(.bar)
        }
    }

    // MARK: - Actions

    private func processImage(_ image: UIImage) {
        phase = .processing
        TextRecognizer.recognizeText(from: image) { text in
            recognizedText = text
            let cards = TextRecognizer.generateCards(from: text)
            generatedCards = cards.map { CardDraft(front: $0.front, back: $0.back) }
            phase = .review
        }
    }

    private func addSelectedCards() {
        let selected = generatedCards.filter(\.isSelected)
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
