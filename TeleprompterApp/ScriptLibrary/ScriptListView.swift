import SwiftData
import SwiftUI

struct ScriptListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var scripts: [Script]
    @State private var searchText = ""
    @State private var activeSheet: ScriptListSheet?

    let theme: PromptTheme
    let onSelect: (Script) -> Void

    init(theme: PromptTheme = PromptDesign.darkTheme, onSelect: @escaping (Script) -> Void) {
        self.theme = theme
        self.onSelect = onSelect
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            theme.pageGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                topBar
                searchField

                if scripts.isEmpty {
                    ContentUnavailableView("暂无脚本", systemImage: "doc.text", description: Text("新建一段口播文案后，就能从这里快速找回。"))
                        .foregroundStyle(theme.secondaryText)
                } else if filteredScripts.isEmpty {
                    ContentUnavailableView("没有找到脚本", systemImage: "magnifyingglass", description: Text("换个关键词试试，或新建一个脚本。"))
                        .foregroundStyle(theme.secondaryText)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredScripts) { script in
                                ScriptRowView(script: script, theme: theme) {
                                    activeSheet = .edit(script)
                                }
                                    .onTapGesture {
                                        script.lastUsedAt = .now
                                        onSelect(script)
                                        dismiss()
                                    }
                                    .contextMenu {
                                        Button(script.isPinned ? "取消置顶" : "置顶") {
                                            script.isPinned.toggle()
                                        }
                                        Button(script.isFavorite ? "取消收藏" : "收藏") {
                                            script.isFavorite.toggle()
                                        }
                                        Button("编辑") {
                                            activeSheet = .edit(script)
                                        }
                                        Button("删除", role: .destructive) {
                                            modelContext.delete(script)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
        }
        .colorScheme(theme.isLight ? .light : .dark)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                ScriptEditorView(modeTitle: "新建脚本", theme: theme) { saved in
                    onSelect(saved)
                    dismiss()
                }
            case .edit(let script):
                ScriptEditorView(script: script, modeTitle: "编辑脚本", theme: theme) { saved in
                    onSelect(saved)
                    dismiss()
                }
            }
        }
    }

    private enum ScriptListSheet: Identifiable {
        case new
        case edit(Script)

        var id: String {
            switch self {
            case .new:
                "new"
            case .edit(let script):
                "edit-\(script.id.uuidString)"
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button("返回") { dismiss() }
            Spacer()
            Text("脚本列表")
                .font(.headline)
                .foregroundStyle(theme.text)
            Spacer()
            Button {
                activeSheet = .new
            } label: {
                Image(systemName: "plus")
            }
        }
        .foregroundStyle(theme.text)
        .padding(.horizontal, 14)
        .frame(height: 46)
        .promptPanel(radius: 23, theme: theme)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("搜索脚本", text: $searchText)
                .textInputAutocapitalization(.never)
        }
        .foregroundStyle(theme.secondaryText)
        .padding(14)
        .promptPanel(radius: 18, theme: theme)
    }

    private var filteredScripts: [Script] {
        let matched = scripts.filter { script in
            searchText.isEmpty ||
            script.title.localizedCaseInsensitiveContains(searchText) ||
            script.body.localizedCaseInsensitiveContains(searchText)
        }

        return matched.sortedForPromptLibrary()
    }
}

struct ScriptRowView: View {
    @Bindable var script: Script
    let theme: PromptTheme
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                let nextValue = !script.isFavorite
                script.isFavorite = nextValue
                script.isPinned = nextValue
            } label: {
                Image(systemName: script.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(script.isFavorite ? PromptDesign.accentBlue : theme.secondaryText)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(script.title.isEmpty ? "未命名脚本" : script.title)
                        .font(.headline)
                    .foregroundStyle(theme.text)
                    if script.isPinned {
                        Text("星标置顶")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PromptDesign.accentBlue)
                    }
                    Spacer()
                }

                Text(script.body)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(2)

                Text("\(script.wordCount) 字 · \(ScriptMetrics.durationText(script.estimatedDuration))")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText.opacity(0.85))
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .promptPanel(radius: 18, theme: theme)
    }
}
