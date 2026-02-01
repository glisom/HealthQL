import Foundation

/// The source of data for a query
public enum HealthSource: Equatable, Sendable {
    case quantity(QuantityType)
    // Future: case category(CategoryType)
    // Future: case workout
    // Future: case clinicalRecord(ClinicalType)
}

/// Fields that can be selected or used in predicates
public enum Field: Equatable, Sendable {
    case value      // The numeric value of a quantity sample
    case date       // The start date of the sample
    case endDate    // The end date of the sample
    case source     // The source (app/device) of the sample
    case device     // The device that recorded the sample
}

/// Aggregation functions
public enum Aggregate: Equatable, Sendable {
    case sum
    case avg
    case min
    case max
    case count
    // Future: case p50, p90, p95, p99
    // Future: case stddev, variance
}

/// What to select from the query
public enum Selection: Equatable, Sendable {
    case field(Field)
    case aggregate(Aggregate, Field)
}

/// Comparison operators for predicates
public enum Operator: Equatable, Sendable {
    case equal
    case notEqual
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case between
    case isNull
    case isNotNull
}

/// Values that can be used in predicates
public enum PredicateValue: Equatable, Sendable {
    case date(Date)
    case double(Double)
    case int(Int)
    case string(String)
    case dateRange(start: Date, end: Date)
    case null
}

/// A condition for filtering results
public struct Predicate: Equatable, Sendable {
    public let field: Field
    public let op: Operator
    public let value: PredicateValue

    public init(field: Field, op: Operator, value: PredicateValue) {
        self.field = field
        self.op = op
        self.value = value
    }
}

/// Time period for grouping results
public enum GroupBy: Equatable, Sendable {
    case hour
    case day
    case week
    case month
    case year
}

/// Ordering direction
public enum OrderDirection: Equatable, Sendable {
    case ascending
    case descending
}

/// Ordering specification
public struct OrderBy: Equatable, Sendable {
    public let field: Field
    public let direction: OrderDirection

    public init(field: Field, direction: OrderDirection = .ascending) {
        self.field = field
        self.direction = direction
    }
}

/// The intermediate representation of a HealthQL query
/// Both the DSL and string parser compile to this structure
public struct HealthQuery: Equatable, Sendable {
    public let source: HealthSource
    public let selections: [Selection]
    public let predicates: [Predicate]
    public let grouping: GroupBy?
    public let having: [Predicate]?
    public let ordering: [OrderBy]?
    public let limit: Int?

    public init(
        source: HealthSource,
        selections: [Selection],
        predicates: [Predicate] = [],
        grouping: GroupBy? = nil,
        having: [Predicate]? = nil,
        ordering: [OrderBy]? = nil,
        limit: Int? = nil
    ) {
        self.source = source
        self.selections = selections
        self.predicates = predicates
        self.grouping = grouping
        self.having = having
        self.ordering = ordering
        self.limit = limit
    }
}
