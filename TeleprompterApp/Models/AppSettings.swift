import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultFontSize: Double
    var defaultScrollSpeed: Double
    var defaultCountdownSeconds: Int
    var resumeCountdownSeconds: Int
    var defaultMirrorEnabled: Bool
    var defaultBackgroundStyle: String
    var autoHideControls: Bool
    var defaultCameraPosition: String
    var hasSeenPermissionExplanation: Bool

    init(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
        defaultFontSize: Double = 42,
        defaultScrollSpeed: Double = 32,
        defaultCountdownSeconds: Int = 3,
        resumeCountdownSeconds: Int = 3,
        defaultMirrorEnabled: Bool = false,
        defaultBackgroundStyle: String = "black",
        autoHideControls: Bool = true,
        defaultCameraPosition: String = "front",
        hasSeenPermissionExplanation: Bool = false
    ) {
        self.id = id
        self.defaultFontSize = defaultFontSize
        self.defaultScrollSpeed = defaultScrollSpeed
        self.defaultCountdownSeconds = defaultCountdownSeconds
        self.resumeCountdownSeconds = resumeCountdownSeconds
        self.defaultMirrorEnabled = defaultMirrorEnabled
        self.defaultBackgroundStyle = defaultBackgroundStyle
        self.autoHideControls = autoHideControls
        self.defaultCameraPosition = defaultCameraPosition
        self.hasSeenPermissionExplanation = hasSeenPermissionExplanation
    }
}
