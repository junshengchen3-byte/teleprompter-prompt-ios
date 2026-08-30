import Foundation
import SwiftData

@Model
final class Script: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    var isFavorite: Bool
    var isPinned: Bool
    var estimatedDuration: TimeInterval
    var wordCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastUsedAt: Date? = nil,
        isFavorite: Bool = false,
        isPinned: Bool = false,
        estimatedDuration: TimeInterval = 0,
        wordCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
        self.isPinned = isPinned
        self.estimatedDuration = estimatedDuration
        self.wordCount = wordCount
    }
}

extension Script {
    func refreshMetrics(wordsPerMinute: Double = 220) {
        wordCount = ScriptMetrics.wordCount(for: body)
        estimatedDuration = ScriptMetrics.estimatedDuration(for: body, wordsPerMinute: wordsPerMinute)
        updatedAt = .now
    }
}
