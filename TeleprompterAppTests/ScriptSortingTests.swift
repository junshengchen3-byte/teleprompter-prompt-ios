import XCTest
@testable import TeleprompterApp

final class ScriptSortingTests: XCTestCase {
    func testPinnedScriptsSortBeforeUnpinnedScripts() {
        let pinned = Script(title: "置顶", body: "A", updatedAt: .distantPast, isPinned: true)
        let normal = Script(title: "普通", body: "B", updatedAt: .now, isPinned: false)

        let sorted = [normal, pinned].sortedForPromptLibrary()

        XCTAssertEqual(sorted.first?.title, "置顶")
    }

    func testFavoriteScriptsSortBeforeUnpinnedScripts() {
        let favorite = Script(title: "收藏", body: "A", updatedAt: .distantPast, isFavorite: true)
        let normal = Script(title: "普通", body: "B", updatedAt: .now)

        let sorted = [normal, favorite].sortedForPromptLibrary()

        XCTAssertEqual(sorted.first?.title, "收藏")
    }

    func testLastUsedAtSortsBeforeUpdatedAt() {
        let used = Script(title: "最近用", body: "A", updatedAt: .distantPast, lastUsedAt: .now)
        let edited = Script(title: "最近改", body: "B", updatedAt: Date(timeIntervalSinceNow: -60))

        let sorted = [edited, used].sortedForPromptLibrary()

        XCTAssertEqual(sorted.first?.title, "最近用")
    }
}
