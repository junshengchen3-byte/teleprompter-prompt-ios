import XCTest
@testable import TeleprompterApp

final class TeleprompterSessionTests: XCTestCase {
    func testRestartResetsOffsetAndPauses() {
        let session = TeleprompterSession(text: "测试", settings: AppSettings())
        session.start()
        session.updateManualOffset(180)

        session.restart()

        XCTAssertEqual(session.scrollOffset, 0)
        XCTAssertFalse(session.isScrolling)
    }

    func testManualDragDuringScrollStartsResumeCountdown() {
        let session = TeleprompterSession(text: "测试", settings: AppSettings())
        session.start()

        session.beginManualReposition()
        session.updateManualOffset(120)
        session.finishManualReposition()

        XCTAssertEqual(session.scrollOffset, 120)
        XCTAssertEqual(session.activeCountdown, 3)
        XCTAssertFalse(session.isScrolling)
    }

    func testCountdownFinishesThenScrollingContinues() {
        let session = TeleprompterSession(text: "测试", settings: AppSettings())
        session.start()
        session.beginManualReposition()
        session.updateManualOffset(80)
        session.finishManualReposition()

        session.countdownTick()
        session.countdownTick()
        session.countdownTick()

        XCTAssertNil(session.activeCountdown)
        XCTAssertTrue(session.isScrolling)
    }

    func testPauseClearsPendingCountdown() {
        let session = TeleprompterSession(text: "测试", settings: AppSettings())
        session.requestStart()

        session.pause()

        XCTAssertNil(session.activeCountdown)
        XCTAssertFalse(session.isScrolling)
    }

    func testDisablingAutoHideKeepsControlsVisibleAfterStartCountdown() {
        let settings = AppSettings(autoHideControls: false)
        let session = TeleprompterSession(text: "测试", settings: settings)

        session.requestStart()
        session.countdownTick()
        session.countdownTick()
        session.countdownTick()

        XCTAssertTrue(session.areControlsVisible)
        XCTAssertTrue(session.isScrolling)
    }
}
