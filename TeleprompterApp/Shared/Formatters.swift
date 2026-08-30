import Foundation

enum Formatters {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
}

enum ScriptMetrics {
    static func wordCount(for text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let latinWords = trimmed
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.rangeOfCharacter(from: .letters) != nil }
            .count

        let cjkCharacters = trimmed.unicodeScalars.filter { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }.count

        return max(latinWords + cjkCharacters, trimmed.count)
    }

    static func estimatedDuration(for text: String, wordsPerMinute: Double = 220) -> TimeInterval {
        let words = Double(wordCount(for: text))
        guard words > 0, wordsPerMinute > 0 else { return 0 }
        return max(1, words / wordsPerMinute * 60)
    }

    static func durationText(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration.rounded()))
        if seconds < 60 {
            return "约 \(seconds) 秒"
        }
        return "约 \(seconds / 60) 分 \(seconds % 60) 秒"
    }
}

enum SampleData {
    static let scriptTitle = "口播脚本示例"
    static let scriptBody = """
    今天这个手镯，不是看起来大，就一定更划算。

    你要先看克重，再看工费，最后才看款式。
    """
}
