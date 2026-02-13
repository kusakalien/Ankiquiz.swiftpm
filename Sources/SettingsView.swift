import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ClaudeAPIService.apiKey
    @State private var showingKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("カメラで撮影した教科書のページをAIが分析し、重要な用語と定義を自動でカードにします。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("AI カード生成", systemImage: "sparkles")
                }

                Section {
                    HStack {
                        if showingKey {
                            TextField("sk-ant-...", text: $apiKey)
                                .font(.system(.caption, design: .monospaced))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("sk-ant-...", text: $apiKey)
                                .font(.system(.caption, design: .monospaced))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        Button {
                            showingKey.toggle()
                        } label: {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Claude API キー")
                } footer: {
                    Text("anthropic.com でAPIキーを取得できます。キーはこの端末にのみ保存されます。")
                }

                Section {
                    HStack {
                        Text("ステータス")
                        Spacer()
                        if apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
                            Label("未設定", systemImage: "xmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        } else {
                            Label("設定済み", systemImage: "checkmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        ClaudeAPIService.apiKey = apiKey.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
