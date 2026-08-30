import SwiftUI

struct CountdownOverlayView: View {
    let countdown: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.72))
                .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                .frame(width: 112, height: 112)
            Text("\(countdown)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.35), radius: 22, y: 12)
        .transition(.scale.combined(with: .opacity))
    }
}
