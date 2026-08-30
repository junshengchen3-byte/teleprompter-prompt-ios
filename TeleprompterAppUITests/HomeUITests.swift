import XCTest

@MainActor
final class HomeUITests: XCTestCase {
    func testHomeShowsThreePrimaryActions() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["全屏提词"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["拍摄提词"].exists)
        XCTAssertTrue(app.staticTexts["设置"].exists)
        XCTAssertTrue(app.staticTexts["脚本列表"].exists)
    }

    func testPromptEntryUsesScriptTerminology() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["home.fullScreenPrompt"].waitForExistence(timeout: 3))
        app.buttons["home.fullScreenPrompt"].tap()

        XCTAssertTrue(app.staticTexts["选择脚本"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["选择" + "台" + "词"].exists)
    }
}
