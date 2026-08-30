import XCTest
@testable import TeleprompterApp

final class AppSettingsTests: XCTestCase {
    func testDefaultSettingsMatchMVPDecisions() {
        let settings = AppSettings()
        XCTAssertEqual(settings.defaultFontSize, 42)
        XCTAssertEqual(settings.defaultScrollSpeed, 32)
        XCTAssertEqual(settings.defaultCountdownSeconds, 3)
        XCTAssertEqual(settings.resumeCountdownSeconds, 3)
        XCTAssertFalse(settings.defaultMirrorEnabled)
        XCTAssertEqual(settings.defaultBackgroundStyle, "black")
        XCTAssertTrue(settings.autoHideControls)
        XCTAssertEqual(settings.defaultCameraPosition, "front")
    }
}
