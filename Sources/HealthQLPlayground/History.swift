import Foundation

/// Manages command history with up/down navigation
public struct History: Sendable {
    public private(set) var entries: [String] = []
    private var position: Int? = nil
    private let maxEntries: Int

    public var current: String? {
        guard let pos = position, pos >= 0, pos < entries.count else { return nil }
        return entries[pos]
    }

    public init(maxEntries: Int = 100) {
        self.maxEntries = maxEntries
    }

    /// Add a new entry to history
    public mutating func add(_ entry: String) {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Don't add duplicates consecutively
        if entries.last == trimmed { return }

        entries.append(trimmed)

        // Trim old entries
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }

        // Reset navigation
        position = nil
    }

    /// Navigate up (older entries)
    public mutating func up() -> String? {
        if entries.isEmpty { return nil }

        if position == nil {
            position = entries.count - 1
        } else if position! > 0 {
            position! -= 1
        }

        return current
    }

    /// Navigate down (newer entries)
    public mutating func down() -> String? {
        guard let pos = position else { return nil }

        if pos < entries.count - 1 {
            position = pos + 1
            return current
        } else {
            position = nil
            return nil
        }
    }

    /// Reset navigation position
    public mutating func reset() {
        position = nil
    }

    /// Get all entries for display
    public func all() -> [String] {
        entries
    }
}
