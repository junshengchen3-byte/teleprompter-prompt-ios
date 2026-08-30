import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @Query private var scripts: [Script]
    @State private var fallbackSettings = AppSettings()
    @State private var searchText = ""
    @State private var activeSheet: HomeSheet?
    @State private var activeRoute: AppRoute?
    @State private var quickStartScript: Script?

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                theme.pageGradient.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    header

                    HStack(spacing: 12) {
                        Button {
                            activeRoute = .cameraPrompt
                        } label: {
                            HomeActionCard(
                                title: "拍摄提词",
                                systemImage: "record.circle",
                                isPrimary: true,
                                theme: theme
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.cameraPrompt")

                        Button {
                            activeRoute = .fullScreenPrompt
                        } label: {
                            HomeActionCard(
                                title: "全屏提词",
                                systemImage: "text.alignleft",
                                isPrimary: false,
                                theme: theme
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.fullScreenPrompt")

                        Button {
                            activeRoute = .settings
                        } label: {
                            HomeActionCard(
                                title: "设置",
                                systemImage: "gearshape",
                                isPrimary: false,
                                theme: theme
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.settings")
                    }

                    librarySection
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 18)
                .frame(maxWidth: 720, maxHeight: .infinity, alignment: .top)
            }
            .fullScreenCover(item: $activeRoute) { route in
                switch route {
                case .fullScreenPrompt:
                    PromptModeView(settings: activeSettings, initialMode: .fullScreen)
                case .cameraPrompt:
                    PromptModeView(settings: activeSettings, initialMode: .camera)
                case .settings:
                    SettingsView(settings: activeSettings)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .newScript:
                    ScriptEditorView(modeTitle: "新建脚本", theme: theme) { script in
                        quickStart(script)
                    }
                case .editScript(let script):
                    ScriptEditorView(script: script, modeTitle: "编辑脚本", theme: theme) { script in
                        quickStart(script)
                    }
                }
            }
            .fullScreenCover(item: $quickStartScript) { script in
                NavigationStack {
                    PromptModeView(settings: activeSettings, initialScript: script)
                }
            }
            .task {
                ensureSettings()
            }
        }
        .tint(PromptDesign.accentBlue)
        .background(theme.background.ignoresSafeArea())
        .colorScheme(theme.isLight ? .light : .dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            AppIconMark(size: 36)
            Text("提词器Prompt")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.text)
                .lineLimit(1)
            Spacer()
        }
        .padding(.top, 2)
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("脚本列表")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(theme.text)
                Spacer()
                Button {
                    activeSheet = .newScript
                } label: {
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

            if scripts.isEmpty {
                emptyLibrary
            } else if sortedScripts.isEmpty {
                emptySearchResult
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 12)], spacing: 12) {
                        ForEach(sortedScripts) { script in
                            ScriptCardView(script: script, theme: theme) {
                                quickStart(script)
                            } onEdit: {
                                activeSheet = .editScript(script)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private var emptyLibrary: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 34, weight: .semibold))
            Text("还没有脚本")
                .font(.headline)
            Text("新建一段文案后，首页会按时间顺序显示，置顶脚本优先。")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.secondaryText)
        }
        .foregroundStyle(theme.text)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .promptPanel(radius: 20, theme: theme)
    }

    private var emptySearchResult: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .semibold))
            Text("没有找到脚本")
                .font(.headline)
            Text("换个关键词试试，或直接新建一个脚本。")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.secondaryText)
        }
        .foregroundStyle(theme.text)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .promptPanel(radius: 20, theme: theme)
    }

    private var activeSettings: AppSettings {
        if let existing = settings.first {
            return existing
        }
        return fallbackSettings
    }

    private func ensureSettings() {
        guard settings.isEmpty else { return }
        modelContext.insert(fallbackSettings)
    }

    private var sortedScripts: [Script] {
        let matched = scripts.filter { script in
            searchText.isEmpty ||
            script.title.localizedCaseInsensitiveContains(searchText) ||
            script.body.localizedCaseInsensitiveContains(searchText)
        }
        return matched.sortedForPromptLibrary()
    }

    private func quickStart(_ script: Script) {
        script.lastUsedAt = .now
        quickStartScript = script
    }

    private var theme: PromptTheme {
        PromptDesign.theme(for: activeSettings)
    }
}

struct HomeActionCard: View {
    let title: String
    let systemImage: String
    let isPrimary: Bool
    let theme: PromptTheme

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isPrimary ? PromptDesign.accentGradient : LinearGradient(colors: [theme.controlFill], startPoint: .top, endPoint: .bottom))
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(isPrimary ? Color.white : theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 112)
        .padding(.horizontal, 10)
        .background(isPrimary ? PromptDesign.accentGradient : LinearGradient(colors: [theme.panel.opacity(0.92), theme.panelLight.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isPrimary ? .white.opacity(0.22) : theme.glassStroke, lineWidth: 1)
        )
    }
}

struct AppIconMark: View {
    let size: CGFloat

    var body: some View {
        Image("BrandIcon")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: PromptDesign.accent.opacity(0.18), radius: 14, y: 8)
    }
}

private enum HomeSheet: Identifiable {
    case newScript
    case editScript(Script)

    var id: String {
        switch self {
        case .newScript: "newScript"
        case .editScript(let script): "edit-\(script.id.uuidString)"
        }
    }
}

struct ScriptCardView: View {
    @Bindable var script: Script
    let theme: PromptTheme
    let onSelect: () -> Void
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    let nextValue = !(script.isPinned || script.isFavorite)
                    script.isFavorite = nextValue
                    script.isPinned = nextValue
                } label: {
                    Image(systemName: script.isPinned || script.isFavorite ? "star.fill" : "star")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(script.isPinned || script.isFavorite ? PromptDesign.accentBlue : theme.secondaryText.opacity(0.62))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                Spacer()
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
                Text(Formatters.shortDate.string(from: script.updatedAt))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
            }

            Text(script.body.isEmpty ? script.title : script.body)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.text)
                .lineLimit(5)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 144)
        .padding(16)
        .background(theme.field, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.stroke, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .contextMenu {
            if let onEdit {
                Button("编辑脚本", systemImage: "pencil") {
                    onEdit()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Script.self, AppSettings.self], inMemory: true)
}
