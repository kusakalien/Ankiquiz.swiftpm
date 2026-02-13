# AnkiQuiz.swiftpm

暗記クイズアプリ - Swift Playgrounds対応

## 機能

- デッキの作成・管理
- フラッシュカードの追加・削除
- SM-2アルゴリズムによるスペースドリピティション（間隔反復）
- クイズモード（もう一度 / 難しい / 普通 / 簡単 の4段階評価）
- UserDefaultsによるデータ永続化
- サンプルデッキ（Swift基礎）

## 必要環境

- iOS 16.0以上
- Swift Playgrounds 4+ または Xcode 14+

## プロジェクト構成

```
Sources/
├── AnkiQuizApp.swift   # アプリエントリポイント
├── ContentView.swift    # メイン画面（デッキ一覧）
├── Models.swift         # データモデル（Flashcard, Deck, SpacedRepetition）
├── DeckStore.swift      # データ管理（永続化）
├── DeckDetailView.swift # デッキ詳細画面
├── QuizView.swift       # クイズ画面
├── AddDeckView.swift    # デッキ追加画面
└── AddCardView.swift    # カード追加画面
```
