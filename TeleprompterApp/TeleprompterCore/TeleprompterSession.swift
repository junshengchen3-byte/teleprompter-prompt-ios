import CoreGraphics
import Foundation
import Observation

@Observable
final class TeleprompterSession {
    var text: String
    var isScrolling: Bool = false
    var isDragging: Bool = false
    var scrollSpeed: Double
    var fontSize: Double
    var isMirrorEnabled: Bool
    var countdownSeconds: Int
    var resumeCountdownSeconds: Int
    var activeCountdown: Int?
    var scrollOffset: CGFloat = 0
    var areControlsVisible: Bool
    var autoHideControls: Bool

    private var shouldResumeAfterDrag = false

    init(text: String, settings: AppSettings) {
        self.text = text
        self.scrollSpeed = settings.defaultScrollSpeed
        self.fontSize = settings.defaultFontSize
        self.isMirrorEnabled = settings.defaultMirrorEnabled
        self.countdownSeconds = settings.defaultCountdownSeconds
        self.resumeCountdownSeconds = settings.resumeCountdownSeconds
        self.areControlsVisible = true
        self.autoHideControls = settings.autoHideControls
    }

    func start() {
        isScrolling = true
        activeCountdown = nil
    }

    func requestStart() {
        guard countdownSeconds > 0 else {
            start()
            return
        }
        activeCountdown = countdownSeconds
        isScrolling = false
        areControlsVisible = !autoHideControls
    }

    func pause() {
        isScrolling = false
        activeCountdown = nil
        shouldResumeAfterDrag = false
    }

    func restart() {
        scrollOffset = 0
        pause()
    }

    func beginManualReposition() {
        shouldResumeAfterDrag = isScrolling
        isDragging = true
        isScrolling = false
        activeCountdown = nil
    }

    func updateManualOffset(_ offset: CGFloat) {
        scrollOffset = max(0, offset)
    }

    func finishManualReposition() {
        isDragging = false
        guard shouldResumeAfterDrag else { return }
        resumeAfterManualReposition()
    }

    func resumeAfterManualReposition() {
        activeCountdown = max(1, resumeCountdownSeconds)
    }

    func countdownTick() {
        guard let current = activeCountdown else { return }
        if current <= 1 {
            activeCountdown = nil
            isScrolling = true
            areControlsVisible = !autoHideControls
            shouldResumeAfterDrag = false
        } else {
            activeCountdown = current - 1
        }
    }

    func tick(delta: TimeInterval, maximumOffset: CGFloat) {
        guard isScrolling, activeCountdown == nil, !isDragging else { return }
        scrollOffset = min(maximumOffset, scrollOffset + CGFloat(scrollSpeed * delta))
    }

    func toggleControls() {
        areControlsVisible.toggle()
    }

    func applySettings(_ settings: AppSettings) {
        scrollSpeed = settings.defaultScrollSpeed
        fontSize = settings.defaultFontSize
        isMirrorEnabled = settings.defaultMirrorEnabled
        countdownSeconds = settings.defaultCountdownSeconds
        resumeCountdownSeconds = settings.resumeCountdownSeconds
        autoHideControls = settings.autoHideControls
    }
}
