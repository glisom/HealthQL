import Foundation

/// Convenience type for expressing dates in queries
public enum DateReference: Sendable {
    case today
    case startOfWeek
    case startOfMonth
    case startOfYear
    case hoursAgo(Int)
    case daysAgo(Int)
    case weeksAgo(Int)
    case monthsAgo(Int)
    case exact(Date)

    /// Resolve to an actual Date
    public var date: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            return calendar.startOfDay(for: now)

        case .startOfWeek:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return calendar.date(from: components) ?? now

        case .startOfMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components) ?? now

        case .startOfYear:
            let components = calendar.dateComponents([.year], from: now)
            return calendar.date(from: components) ?? now

        case .hoursAgo(let hours):
            return calendar.date(byAdding: .hour, value: -hours, to: now) ?? now

        case .daysAgo(let days):
            let startOfToday = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .day, value: -days, to: startOfToday) ?? now

        case .weeksAgo(let weeks):
            let startOfToday = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .weekOfYear, value: -weeks, to: startOfToday) ?? now

        case .monthsAgo(let months):
            let startOfToday = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .month, value: -months, to: startOfToday) ?? now

        case .exact(let date):
            return date
        }
    }
}

// MARK: - PredicateValue convenience initializer

extension PredicateValue {
    /// Create a date predicate value from a DateReference
    public static func date(_ reference: DateReference) -> PredicateValue {
        .date(reference.date)
    }
}
