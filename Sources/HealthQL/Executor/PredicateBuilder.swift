import Foundation
import HealthKit

/// Builds HKQuery predicates from IR predicates
public struct PredicateBuilder: Sendable {

    public init() {}

    /// Build a compound predicate from IR predicates
    public func build(from predicates: [Predicate]) -> NSPredicate? {
        guard !predicates.isEmpty else { return nil }

        let hkPredicates = predicates.compactMap { buildSingle($0) }
        guard !hkPredicates.isEmpty else { return nil }

        if hkPredicates.count == 1 {
            return hkPredicates[0]
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: hkPredicates)
    }

    /// Build a single HK predicate from an IR predicate
    private func buildSingle(_ predicate: Predicate) -> NSPredicate? {
        switch predicate.field {
        case .date:
            return buildDatePredicate(predicate)
        case .value:
            return buildValuePredicate(predicate)
        case .source:
            return buildSourcePredicate(predicate)
        default:
            // Other fields handled at result filtering level
            return nil
        }
    }

    private func buildDatePredicate(_ predicate: Predicate) -> NSPredicate? {
        switch (predicate.op, predicate.value) {
        case (.greaterThan, .date(let date)):
            return HKQuery.predicateForSamples(withStart: date, end: nil, options: .strictStartDate)
        case (.greaterThanOrEqual, .date(let date)):
            return HKQuery.predicateForSamples(withStart: date, end: nil, options: [])
        case (.lessThan, .date(let date)):
            return HKQuery.predicateForSamples(withStart: nil, end: date, options: .strictEndDate)
        case (.lessThanOrEqual, .date(let date)):
            return HKQuery.predicateForSamples(withStart: nil, end: date, options: [])
        case (.between, .dateRange(let start, let end)):
            return HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        default:
            return nil
        }
    }

    private func buildValuePredicate(_ predicate: Predicate) -> NSPredicate? {
        // Value predicates require the quantity type and unit
        // These are applied post-fetch for simplicity
        return nil
    }

    private func buildSourcePredicate(_ predicate: Predicate) -> NSPredicate? {
        guard case .string(_) = predicate.value else { return nil }
        // Source predicates are applied post-fetch
        return nil
    }
}
