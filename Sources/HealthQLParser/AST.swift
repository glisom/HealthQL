import Foundation

/// Aggregate function types
public enum AggregateFunction: String, Equatable, Sendable {
    case sum
    case avg
    case min
    case max
    case count
}

/// Date function types
public enum DateFunction: Equatable, Sendable {
    case today
    case startOfWeek
    case startOfMonth
    case startOfYear
}

/// Duration units
public enum DurationUnit: String, Equatable, Sendable {
    case days = "d"
    case weeks = "w"
    case months = "mo"
    case years = "y"
}

/// Binary operators
public enum BinaryOperator: Equatable, Sendable {
    case plus
    case minus
    case multiply
    case divide
    case equal
    case notEqual
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case and
    case or
}

/// Unary operators
public enum UnaryOperator: Equatable, Sendable {
    case not
    case negative
}

/// Order direction
public enum OrderDirection: Equatable, Sendable {
    case asc
    case desc
}

/// Expression in the AST
public indirect enum Expression: Equatable, Sendable {
    case identifier(String)
    case qualifiedIdentifier(table: String, column: String)
    case number(Double)
    case string(String)
    case duration(Int, DurationUnit)
    case aggregate(AggregateFunction, Expression)
    case function(DateFunction, [Expression])
    case binary(Expression, BinaryOperator, Expression)
    case unary(UnaryOperator, Expression)
    case isNull(Expression, negated: Bool)
    case star  // SELECT *
}

/// ORDER BY clause item
public struct OrderByItem: Equatable, Sendable {
    public let expression: Expression
    public let direction: OrderDirection

    public init(expression: Expression, direction: OrderDirection = .asc) {
        self.expression = expression
        self.direction = direction
    }
}

/// GROUP BY clause
public enum GroupByClause: Equatable, Sendable {
    case timePeriod(GroupByPeriod)
    case expression(Expression)
}

/// Time periods for GROUP BY
public enum GroupByPeriod: String, Equatable, Sendable {
    case hour
    case day
    case week
    case month
    case year
}

/// A complete SELECT statement
public struct SelectStatement: Equatable, Sendable {
    public let selections: [Expression]
    public let from: String
    public let whereClause: Expression?
    public let groupBy: GroupByClause?
    public let having: Expression?
    public let orderBy: [OrderByItem]?
    public let limit: Int?

    public init(
        selections: [Expression],
        from: String,
        whereClause: Expression? = nil,
        groupBy: GroupByClause? = nil,
        having: Expression? = nil,
        orderBy: [OrderByItem]? = nil,
        limit: Int? = nil
    ) {
        self.selections = selections
        self.from = from
        self.whereClause = whereClause
        self.groupBy = groupBy
        self.having = having
        self.orderBy = orderBy
        self.limit = limit
    }
}
