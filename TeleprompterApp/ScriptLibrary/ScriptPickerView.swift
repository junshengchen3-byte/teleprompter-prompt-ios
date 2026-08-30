import SwiftUI

struct ScriptPickerView: View {
    let modeTitle: String
    let theme: PromptTheme
    let onCreate: () -> Void
    let onOpenLibrary: () -> Void
    let recentScripts: [Script]
    let onSelect: (Script) -> Void
    let onEdit: (Script) -> Void
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(modeTitle)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(theme.text)
                Spacer()
                Button(action: onCreate) {
                    Label("新建脚本", systemImage: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .promptPanel(radius: 19, theme: theme)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                TextField("搜索脚本", text: $searchText)
                    .textInputAutocapitalization(.never)
            }
            .foregroundStyle(theme.secondaryText)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(theme.field, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if recentScripts.isEmpty {
                ContentUnavailableView("暂无脚本", systemImage: "doc.text", description: Text("可以先新建脚本，正文输入框里能直接粘贴文案。"))
                    .foregroundStyle(theme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .promptPanel(radius: 20, theme: theme)
            } else if filteredScripts.isEmpty {
                ContentUnavailableView("没有找到脚本", systemImage: "magnifyingglass", description: Text("换个关键词试试，或新建一个脚本。"))
                    .foregroundStyle(theme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .promptPanel(radius: 20, theme: theme)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 12)], spacing: 12) {
                        ForEach(filteredScripts) { script in
                            ScriptCardView(script: script, theme: theme) {
                                onSelect(script)
                            } onEdit: {
                                onEdit(script)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private var filteredScripts: [Script] {
        let matched = recentScripts.filter { script in
            searchText.isEmpty ||
            script.title.localizedCaseInsensitiveContains(searchText) ||
            script.body.localizedCaseInsensitiveContains(searchText)
        }
        return matched.sortedForPromptLibrary()
    }
}

extension Array where Element == Script {
    func sortedForPromptLibrary() -> [Script] {
        sorted { lhs, rhs in
            let lhsPinned = lhs.isPinned || lhs.isFavorite
            let rhsPinned = rhs.isPinned || rhs.isFavorite
            if lhsPinned != rhsPinned { return lhsPinned }
            let lhsActivity = lhs.lastUsedAt ?? lhs.updatedAt
            let rhsActivity = rhs.lastUsedAt ?? rhs.updatedAt
            return lhsActivity > rhsActivity
        }
    }
}
