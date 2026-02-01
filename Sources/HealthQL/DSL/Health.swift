import Foundation

/// Entry point for the HealthQL DSL
public enum Health {

    /// Select all fields from a quantity type
    public static func select(_ type: QuantityType) -> QueryBuilder {
        QueryBuilder(source: .quantity(type), selections: [.field(.value)])
    }

    /// Select with a single aggregate
    public static func select(_ type: QuantityType, aggregate: Aggregate) -> QueryBuilder {
        QueryBuilder(source: .quantity(type), selections: [.aggregate(aggregate, .value)])
    }

    /// Select with multiple aggregates
    public static func select(_ type: QuantityType, aggregates: [Aggregate]) -> QueryBuilder {
        let selections = aggregates.map { Selection.aggregate($0, .value) }
        return QueryBuilder(source: .quantity(type), selections: selections)
    }
}
