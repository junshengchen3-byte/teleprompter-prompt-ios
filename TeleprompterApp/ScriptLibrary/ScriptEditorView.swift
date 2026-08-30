import SwiftData
import SwiftUI

struct ScriptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let existingScript: Script?
    private let modeTitle: String
    private let theme: PromptTheme
    private let onSaveAndStart: (Script) -> Void

    @State private var title: String
    @State private var bodyText: String
    @FocusState private var focusedField: EditorField?

    init(script: Script? = nil, modeTitle: String = "新建脚本", theme: PromptTheme = PromptDesign.darkTheme, onSaveAndStart: @escaping (Script) -> Void) {
        self.existingScript = script
        self.modeTitle = modeTitle
        self.theme = theme
        self.onSaveAndStart = onSaveAndStart
        _title = State(initialValue: script?.title ?? "")
        _bodyText = State(initialValue: script?.body ?? "")
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            theme.pageGradient.ignoresSafeArea()

            VStack(spacing: 18) {
                topBar

                VStack(alignment: .leading, spacing: 10) {
                    Text("标题")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                    TextField("请输入标题", text: $title)
                        .font(.headline)
                        .foregroundStyle(theme.text)
                        .focused($focusedField, equals: .title)
                        .textFieldStyle(.plain)
                        .padding(16)
                        .promptPanel(radius: 16, theme: theme)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("正文")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                    TextEditor(text: $bodyText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.text)
                        .focused($focusedField, equals: .body)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 260)
                        .background(theme.panel.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(theme.stroke, lineWidth: 1)
                        )
                }

                HStack {
                    Text("\(wordCount) 字 · \(ScriptMetrics.durationText(estimatedDuration))")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                    Spacer()
                }

                Button {
                    let script = save()
                    onSaveAndStart(script)
                    dismiss()
                } label: {
                    Text("保存并开始")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(PromptDesign.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
        }
        .colorScheme(theme.isLight ? .light : .dark)
        .onAppear {
            focusedField = existingScript == nil ? .title : .body
        }
    }

    private var topBar: some View {
        HStack {
            Button("取消") { dismiss() }
            Spacer()
            Text(modeTitle)
                .font(.headline)
            Spacer()
            Button("保存") {
                _ = save()
                dismiss()
            }
            .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .foregroundStyle(theme.text)
        .padding(.horizontal, 14)
        .frame(height: 46)
        .promptPanel(radius: 23, theme: theme)
    }

    private var wordCount: Int {
        ScriptMetrics.wordCount(for: bodyText)
    }

    private var estimatedDuration: TimeInterval {
        ScriptMetrics.estimatedDuration(for: bodyText)
    }

    private func save() -> Script {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let script = existingScript ?? Script(title: cleanTitle.isEmpty ? "未命名脚本" : cleanTitle, body: cleanBody)

        if existingScript == nil {
            modelContext.insert(script)
        }

        script.title = cleanTitle.isEmpty ? "未命名脚本" : cleanTitle
        script.body = cleanBody
        script.lastUsedAt = .now
        script.refreshMetrics()
        try? modelContext.save()
        return script
    }

    private enum EditorField {
        case title
        case body
    }
}
