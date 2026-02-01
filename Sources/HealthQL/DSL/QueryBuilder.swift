import Foundation

/// Fluent builder for constructing HealthQL queries
public struct QueryBuilder: Sendable {
    private let source: HealthSource
    private let selections: [Selection]
    private var predicates: [Predicate] = []
    private var grouping: GroupBy? = nil
    private var ordering: [OrderBy]? = nil
    private var queryLimit: Int? = nil

    internal init(source: HealthSource, selections: [Selection]) {
        self.source = source
        self.selections = selections
    }

    /// Add a WHERE predicate
    public func `where`(_ field: Field, _ op: Operator, _ value: PredicateValue) -> QueryBuilder {
        var copy = self
        copy.predicates.append(Predicate(field: field, op: op, value: value))
        return copy
    }

    /// Group results by time period
    public func groupBy(_ period: GroupBy) -> QueryBuilder {
        var copy = self
        copy.grouping = period
        return copy
    }

    /// Order results by field
    public func orderBy(_ field: Field, _ direction: OrderDirection = .ascending) -> QueryBuilder {
        var copy = self
        if copy.ordering == nil {
            copy.ordering = []
        }
        copy.ordering?.append(OrderBy(field: field, direction: direction))
        return copy
    }

    /// Limit the number of results
    public func limit(_ count: Int) -> QueryBuilder {
        var copy = self
        copy.queryLimit = count
        return copy
    }

    /// Build the intermediate representation
    public func buildQuery() -> HealthQuery {
        HealthQuery(
            source: source,
            selections: selections,
            predicates: predicates,
            grouping: grouping,
            having: nil,
            ordering: ordering,
            limit: queryLimit
        )
    }
}
