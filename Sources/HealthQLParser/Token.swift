import Foundation

/// Types of tokens in HealthQL queries
public enum TokenType: Equatable, Sendable {
    // Keywords
    case select
    case from
    case `where`
    case groupBy
    case having
    case orderBy
    case limit
    case asc
    case desc
    case and
    case or
    case not
    case `is`
    case null

    // Aggregation functions
    case sum
    case avg
    case min
    case max
    case count

    // Date functions
    case today
    case startOfWeek
    case startOfMonth
    case startOfYear

    // Literals
    case identifier    // table/column names: steps, heart_rate
    case number        // 42, 3.14
    case string        // 'quoted string'
    case duration      // 7d, 2w, 3mo, 1y

    // Operators
    case equal         // =
    case notEqual      // != or <>
    case greaterThan   // >
    case greaterThanOrEqual  // >=
    case lessThan      // <
    case lessThanOrEqual     // <=
    case plus          // +
    case minus         // -
    case star          // *
    case slash         // /

    // Punctuation
    case leftParen     // (
    case rightParen    // )
    case comma         // ,
    case dot           // .

    // Special
    case eof           // end of input
}

/// A token from lexical analysis
public struct Token: Equatable, Sendable {
    public let type: TokenType
    public let value: String
    public let line: Int
    public let column: Int

    public init(type: TokenType, value: String, line: Int, column: Int) {
        self.type = type
        self.value = value
        self.line = line
        self.column = column
    }
}
