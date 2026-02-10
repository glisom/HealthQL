import Foundation

/// Errors that can occur during parsing
public enum ParserError: Error, Equatable {
    case unexpectedToken(expected: String, got: Token)
    case unexpectedEndOfInput
    case invalidExpression(String)
}

/// Recursive descent parser for HealthQL queries
public final class Parser {
    private let tokens: [Token]
    private var current: Int = 0

    public init(_ source: String) throws {
        let lexer = Lexer(source)
        self.tokens = try lexer.tokenize()
    }

    /// Parse the query into a SelectStatement
    public func parse() throws -> SelectStatement {
        try parseSelectStatement()
    }

    // MARK: - Token Navigation

    private var isAtEnd: Bool {
        peek().type == .eof
    }

    private func peek() -> Token {
        tokens[current]
    }

    private func previous() -> Token {
        tokens[current - 1]
    }

    private func advance() -> Token {
        if !isAtEnd {
            current += 1
        }
        return previous()
    }

    private func check(_ type: TokenType) -> Bool {
        if isAtEnd { return false }
        return peek().type == type
    }

    private func match(_ types: TokenType...) -> Bool {
        for type in types {
            if check(type) {
                _ = advance()
                return true
            }
        }
        return false
    }

    private func consume(_ type: TokenType, message: String) throws -> Token {
        if check(type) { return advance() }
        throw ParserError.unexpectedToken(expected: message, got: peek())
    }

    // MARK: - Grammar Rules

    private func parseSelectStatement() throws -> SelectStatement {
        _ = try consume(.select, message: "SELECT")

        let selections = try parseSelections()

        _ = try consume(.from, message: "FROM")
        let fromToken = try consume(.identifier, message: "table name")
        let from = fromToken.value

        var whereClause: Expression? = nil
        if match(.where) {
            whereClause = try parseExpression()
        }

        var groupBy: GroupByClause? = nil
        if match(.group) {
            _ = try consume(.by, message: "BY after GROUP")
            groupBy = try parseGroupBy()
        }

        var having: Expression? = nil
        if match(.having) {
            having = try parseExpression()
        }

        var orderBy: [OrderByItem]? = nil
        if match(.order) {
            _ = try consume(.by, message: "BY after ORDER")
            orderBy = try parseOrderBy()
        }

        var limit: Int? = nil
        if match(.limit) {
            let numToken = try consume(.number, message: "number")
            limit = Int(numToken.value)
        }

        return SelectStatement(
            selections: selections,
            from: from,
            whereClause: whereClause,
            groupBy: groupBy,
            having: having,
            orderBy: orderBy,
            limit: limit
        )
    }

    private func parseSelections() throws -> [Expression] {
        var selections: [Expression] = []

        repeat {
            let expr = try parseSelectionExpression()
            selections.append(expr)
        } while match(.comma)

        return selections
    }

    private func parseSelectionExpression() throws -> Expression {
        // Check for *
        if match(.star) {
            return .star
        }

        // Check for aggregate function
        if match(.sum, .avg, .min, .max, .count) {
            let fnToken = previous()
            let fn: AggregateFunction
            switch fnToken.type {
            case .sum: fn = .sum
            case .avg: fn = .avg
            case .min: fn = .min
            case .max: fn = .max
            case .count: fn = .count
            default: throw ParserError.invalidExpression("Unknown aggregate")
            }

            _ = try consume(.leftParen, message: "(")
            let inner = try parseExpression()
            _ = try consume(.rightParen, message: ")")

            return .aggregate(fn, inner)
        }

        return try parseExpression()
    }

    private func parseGroupBy() throws -> GroupByClause {
        let token = try consume(.identifier, message: "GROUP BY column or period")
        let value = token.value.lowercased()

        // Check for time period
        if let period = GroupByPeriod(rawValue: value) {
            return .timePeriod(period)
        }

        return .expression(.identifier(token.value))
    }

    private func parseOrderBy() throws -> [OrderByItem] {
        var items: [OrderByItem] = []

        repeat {
            let expr = try parseExpression()
            var direction: ASTOrderDirection = .asc
            if match(.asc) {
                direction = .asc
            } else if match(.desc) {
                direction = .desc
            }
            items.append(OrderByItem(expression: expr, direction: direction))
        } while match(.comma)

        return items
    }

    // MARK: - Expression Parsing (Precedence Climbing)

    private func parseExpression() throws -> Expression {
        try parseOr()
    }

    private func parseOr() throws -> Expression {
        var left = try parseAnd()

        while match(.or) {
            let right = try parseAnd()
            left = .binary(left, .or, right)
        }

        return left
    }

    private func parseAnd() throws -> Expression {
        var left = try parseComparison()

        while match(.and) {
            let right = try parseComparison()
            left = .binary(left, .and, right)
        }

        return left
    }

    private func parseComparison() throws -> Expression {
        let left = try parseAddition()

        if match(.equal) {
            let right = try parseAddition()
            return .binary(left, .equal, right)
        }
        if match(.notEqual) {
            let right = try parseAddition()
            return .binary(left, .notEqual, right)
        }
        if match(.greaterThan) {
            let right = try parseAddition()
            return .binary(left, .greaterThan, right)
        }
        if match(.greaterThanOrEqual) {
            let right = try parseAddition()
            return .binary(left, .greaterThanOrEqual, right)
        }
        if match(.lessThan) {
            let right = try parseAddition()
            return .binary(left, .lessThan, right)
        }
        if match(.lessThanOrEqual) {
            let right = try parseAddition()
            return .binary(left, .lessThanOrEqual, right)
        }
        if match(.is) {
            let negated = match(.not)
            _ = try consume(.null, message: "NULL")
            return .isNull(left, negated: negated)
        }
        if match(.between) {
            let low = try parseAddition()
            _ = try consume(.and, message: "AND after BETWEEN")
            let high = try parseAddition()
            return .between(left, low, high)
        }

        return left
    }

    private func parseAddition() throws -> Expression {
        var left = try parseMultiplication()

        while match(.plus, .minus) {
            let op: BinaryOperator = previous().type == .plus ? .plus : .minus
            let right = try parseMultiplication()
            left = .binary(left, op, right)
        }

        return left
    }

    private func parseMultiplication() throws -> Expression {
        var left = try parseUnary()

        while match(.star, .slash) {
            let op: BinaryOperator = previous().type == .star ? .multiply : .divide
            let right = try parseUnary()
            left = .binary(left, op, right)
        }

        return left
    }

    private func parseUnary() throws -> Expression {
        if match(.not) {
            let expr = try parseUnary()
            return .unary(.not, expr)
        }
        if match(.minus) {
            let expr = try parseUnary()
            return .unary(.negative, expr)
        }

        return try parsePrimary()
    }

    private func parsePrimary() throws -> Expression {
        // Number
        if match(.number) {
            let value = Double(previous().value) ?? 0
            return .number(value)
        }

        // Duration
        if match(.duration) {
            return try parseDuration(previous().value)
        }

        // String
        if match(.string) {
            return .string(previous().value)
        }

        // Date functions
        if match(.today) {
            _ = try consume(.leftParen, message: "(")
            _ = try consume(.rightParen, message: ")")
            return .function(.today, [])
        }
        if match(.startOfWeek) {
            _ = try consume(.leftParen, message: "(")
            _ = try consume(.rightParen, message: ")")
            return .function(.startOfWeek, [])
        }
        if match(.startOfMonth) {
            _ = try consume(.leftParen, message: "(")
            _ = try consume(.rightParen, message: ")")
            return .function(.startOfMonth, [])
        }
        if match(.startOfYear) {
            _ = try consume(.leftParen, message: "(")
            _ = try consume(.rightParen, message: ")")
            return .function(.startOfYear, [])
        }

        // Star (for COUNT(*))
        if match(.star) {
            return .star
        }

        // Parenthesized expression
        if match(.leftParen) {
            let expr = try parseExpression()
            _ = try consume(.rightParen, message: ")")
            return expr
        }

        // Identifier (possibly qualified with table.column)
        // Also treat aggregate keywords as identifiers when used as column names
        if match(.identifier) || match(.sum, .avg, .min, .max, .count) {
            let name = previous().value
            if match(.dot) {
                let column = try consume(.identifier, message: "column name")
                return .qualifiedIdentifier(table: name, column: column.value)
            }
            return .identifier(name)
        }

        throw ParserError.unexpectedToken(expected: "expression", got: peek())
    }

    private func parseDuration(_ value: String) throws -> Expression {
        // Parse "2h", "7d", "2w", "3mo", "1y"
        var numStr = ""
        var unitStr = ""

        for char in value {
            if char.isNumber {
                numStr.append(char)
            } else {
                unitStr.append(char)
            }
        }

        guard let num = Int(numStr) else {
            throw ParserError.invalidExpression("Invalid duration number: \(value)")
        }

        let unit: DurationUnit
        switch unitStr {
        case "h": unit = .hours
        case "d": unit = .days
        case "w": unit = .weeks
        case "mo": unit = .months
        case "y": unit = .years
        default:
            throw ParserError.invalidExpression("Invalid duration unit: \(unitStr)")
        }

        return .duration(num, unit)
    }
}
