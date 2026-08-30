import XCTest
@testable import TeleprompterApp

final class ScriptMetricsTests: XCTestCase {
    func testChineseTextReturnsNonZeroWordCount() {
        XCTAssertGreaterThan(ScriptMetrics.wordCount(for: "今天这个手镯不是看起来大"), 0)
    }

    func testLongerBodyHasLongerEstimatedDuration() {
        let short = ScriptMetrics.estimatedDuration(for: "今天这个手镯")
        let long = ScriptMetrics.estimatedDuration(for: "今天这个手镯，不是看起来大，就一定更划算。你要先看克重，再看工费，最后才看款式。")
        XCTAssertGreaterThan(long, short)
    }
}
