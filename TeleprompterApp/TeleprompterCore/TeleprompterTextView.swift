import SwiftUI

struct TeleprompterTextView: View {
    @Bindable var session: TeleprompterSession
    var backgroundStyle: String

    @State private var dragStartOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                ScrollView(.vertical, showsIndicators: false) {
                    Text(session.text)
                        .font(.system(size: session.fontSize, weight: .black, design: .rounded))
                        .lineSpacing(session.fontSize * 0.28)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(foreground)
                        .padding(.horizontal, 28)
                        .padding(.vertical, proxy.size.height * 0.42)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: session.isMirrorEnabled ? -1 : 1, y: 1)
                        .offset(y: -session.scrollOffset)
                }
                .scrollDisabled(true)
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            if !session.isDragging {
                                dragStartOffset = session.scrollOffset
                                session.beginManualReposition()
                            }
                            session.updateManualOffset(dragStartOffset - value.translation.height)
                        }
                        .onEnded { _ in
                            session.finishManualReposition()
                        }
                )

                if let countdown = session.activeCountdown {
                    CountdownOverlayView(countdown: countdown)
                }
            }
        }
    }

    private var background: some View {
        Group {
            if backgroundStyle == "clear" {
                Color.clear
            } else if backgroundStyle == "white" {
                Color.white
            } else if backgroundStyle == "gray" {
                LinearGradient(colors: [PromptDesign.panel, .black], startPoint: .top, endPoint: .bottom)
            } else {
                Color.black
            }
        }
        .ignoresSafeArea()
    }

    private var foreground: Color {
        backgroundStyle == "white" ? .black : PromptDesign.text
    }
}
