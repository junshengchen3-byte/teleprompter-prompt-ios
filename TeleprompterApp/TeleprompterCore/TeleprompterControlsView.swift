import SwiftUI

struct TeleprompterControlsView: View {
    @Bindable var session: TeleprompterSession
    var isLightMode: Bool = false
    var bottomInset: CGFloat = 18
    var onToggleTheme: () -> Void = {}

    var body: some View {
        let isPreparingToPlay = session.isScrolling || session.activeCountdown != nil

        VStack {
            Spacer()
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    IconControlButton(image: "minus") {
                        session.scrollSpeed = max(8, session.scrollSpeed - 4)
                    }
                    ValuePill(title: "速度", value: "\(Int(session.scrollSpeed))")
                    IconControlButton(image: "plus") {
                        session.scrollSpeed = min(120, session.scrollSpeed + 4)
                    }
                    ControlChip(title: isPreparingToPlay ? "暂停" : "播放", image: isPreparingToPlay ? "pause.fill" : "play.fill") {
                        isPreparingToPlay ? session.pause() : session.requestStart()
                    }
                    ControlChip(title: "黑/白", image: isLightMode ? "moon.fill" : "sun.max.fill") {
                        onToggleTheme()
                    }
                }

                HStack(spacing: 8) {
                    IconControlButton(image: "minus") {
                        session.fontSize = max(28, session.fontSize - 2)
                    }
                    ValuePill(title: "字号", value: "\(Int(session.fontSize))")
                    IconControlButton(image: "plus") {
                        session.fontSize = min(72, session.fontSize + 2)
                    }
                    ControlChip(title: "从头", image: "backward.end.fill") {
                        session.restart()
                    }
                    ControlChip(title: "镜像", image: "arrow.left.and.right") {
                        session.isMirrorEnabled.toggle()
                    }
                }
            }
            .padding(14)
            .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 18)
            .padding(.bottom, bottomInset)
        }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

struct IconControlButton: View {
    let image: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: image)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 32, height: 40)
                .background(PromptDesign.panelLight.opacity(0.92), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }
}

struct ValuePill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Text(value)
                .foregroundStyle(PromptDesign.accentBlue)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .frame(width: 64, height: 40)
        .padding(.horizontal, 8)
        .background(PromptDesign.panelLight.opacity(0.92), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct ControlChip: View {
    let title: String
    let image: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: image)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 40)
                .background(PromptDesign.panelLight.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

enum PromptDisplayMode {
    case camera
    case fullScreen
}

struct PromptModeSwitchBar: View {
    let selectedMode: PromptDisplayMode
    let onCamera: () -> Void
    let onFullScreen: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            switchButton(title: "拍摄提词", image: "record.circle", mode: .camera, action: onCamera)
            switchButton(title: "全屏提词", image: "text.alignleft", mode: .fullScreen, action: onFullScreen)
        }
        .padding(6)
        .background(.black.opacity(0.72), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func switchButton(title: String, image: String, mode: PromptDisplayMode, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: image)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(selectedMode == mode ? PromptDesign.accentGradient : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing), in: Capsule())
        }
        .disabled(selectedMode == mode)
    }
}
