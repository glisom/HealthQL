import Foundation
import HealthQL

/// Public API for string-based HealthQL queries
///
/// This enum provides static methods to parse and execute SQL-like query strings.
///
/// Example:
/// ```swift
/// // Parse only - returns HealthQuery IR
/// let query = try HQL.parse("SELECT avg(value) FROM heart_rate")
///
/// // Parse and execute - returns QueryResult
/// let result = try await HQL.query("SELECT sum(count) FROM steps WHERE date > today() - 7d GROUP BY day")
/// ```
public enum HQL {

    /// Parse a SQL-like query string into HealthQuery IR
    /// - Parameter query: The query string (e.g., "SELECT sum(count) FROM steps")
    /// - Returns: The HealthQuery intermediate representation
    /// - Throws: LexerError, ParserError, or CompilerError
    public static func parse(_ query: String) throws -> HealthQuery {
        let parser = try Parser(query)
        let ast = try parser.parse()
        let compiler = Compiler()
        return try compiler.compile(ast)
    }

    /// Parse and execute a SQL-like query string
    /// - Parameter query: The query string
    /// - Returns: QueryResult with rows and execution time
    /// - Throws: LexerError, ParserError, CompilerError, or QueryError
    public static func query(_ query: String) async throws -> QueryResult {
        let healthQuery = try parse(query)
        let executor = HealthQueryExecutor()
        return try await executor.execute(healthQuery)
    }
}
