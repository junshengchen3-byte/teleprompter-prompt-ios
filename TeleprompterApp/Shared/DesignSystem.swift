import SwiftUI

enum PromptDesign {
    static let background = Color(red: 0.027, green: 0.031, blue: 0.039)
    static let panel = Color(red: 0.071, green: 0.075, blue: 0.094)
    static let panelLight = Color(red: 0.125, green: 0.133, blue: 0.165)
    static let text = Color(red: 0.961, green: 0.969, blue: 0.98)
    static let secondaryText = Color(red: 0.608, green: 0.631, blue: 0.678)
    static let accent = Color(red: 0.424, green: 0.384, blue: 1)
    static let accentBlue = Color(red: 0.302, green: 0.639, blue: 1)
    static let danger = Color(red: 1, green: 0.227, blue: 0.212)

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let darkTheme = PromptTheme(
        background: background,
        panel: panel,
        panelLight: panelLight,
        field: panelLight.opacity(0.72),
        text: text,
        secondaryText: secondaryText,
        stroke: .white.opacity(0.1),
        controlFill: panelLight.opacity(0.92),
        isLight: false
    )

    static let lightTheme = PromptTheme(
        background: Color(red: 0.958, green: 0.969, blue: 0.984),
        panel: .white,
        panelLight: Color(red: 0.91, green: 0.929, blue: 0.957),
        field: Color(red: 0.892, green: 0.914, blue: 0.949),
        text: Color(red: 0.055, green: 0.067, blue: 0.086),
        secondaryText: Color(red: 0.42, green: 0.455, blue: 0.514),
        stroke: .black.opacity(0.09),
        controlFill: Color(red: 0.89, green: 0.91, blue: 0.945),
        isLight: true
    )

    static func theme(for backgroundStyle: String) -> PromptTheme {
        backgroundStyle == "white" ? lightTheme : darkTheme
    }

    static func theme(for settings: AppSettings) -> PromptTheme {
        theme(for: settings.defaultBackgroundStyle)
    }
}

struct PromptTheme {
    let background: Color
    let panel: Color
    let panelLight: Color
    let field: Color
    let text: Color
    let secondaryText: Color
    let stroke: Color
    let controlFill: Color
    let isLight: Bool

    var pageGradient: LinearGradient {
        LinearGradient(
            colors: [
                PromptDesign.accent.opacity(isLight ? 0.12 : 0.22),
                .clear,
                PromptDesign.accentBlue.opacity(isLight ? 0.08 : 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var glassFill: Color {
        isLight ? .white.opacity(0.72) : .white.opacity(0.055)
    }

    var glassStroke: Color {
        isLight ? .black.opacity(0.08) : .white.opacity(0.11)
    }
}

struct GlassPanel: ViewModifier {
    var radius: CGFloat = 24
    var theme: PromptTheme = PromptDesign.darkTheme

    func body(content: Content) -> some View {
        content
            .background(theme.glassFill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(theme.glassStroke, lineWidth: 1)
            )
    }
}

extension View {
    func promptPanel(radius: CGFloat = 24, theme: PromptTheme = PromptDesign.darkTheme) -> some View {
        modifier(GlassPanel(radius: radius, theme: theme))
    }
}
