# HealthQL Phase 2: SQL Parser Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a SQL-like string parser that compiles queries like `SELECT sum(count) FROM steps WHERE date > today() - 7d` into the HealthQuery IR from Phase 1.

**Architecture:** Three-stage parser pipeline: Lexer (string → tokens) → Parser (tokens → AST) → Compiler (AST → HealthQuery IR). The parser module is separate from the core HealthQL package so the DSL can be used without the parser overhead.

**Tech Stack:** Swift 6.2, no external dependencies (hand-written recursive descent parser)

---

## Task 1: Token Types

**Files:**
- Create: `Sources/HealthQLParser/Token.swift`
- Create: `Tests/HealthQLParserTests/TokenTests.swift`
- Modify: `Package.swift`

**Step 1: Update Package.swift to add HealthQLParser module**

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HealthQL",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HealthQL",
            targets: ["HealthQL"]
        ),
        .library(
            name: "HealthQLParser",
            targets: ["HealthQLParser"]
        ),
    ],
    targets: [
        .target(
            name: "HealthQL",
            linkerSettings: [
                .linkedFramework("HealthKit")
            ]
        ),
        .target(
            name: "HealthQLParser",
            dependencies: ["HealthQL"]
        ),
        .testTarget(
            name: "HealthQLTests",
            dependencies: ["HealthQL"]
        ),
        .testTarget(
            name: "HealthQLParserTests",
            dependencies: ["HealthQLParser"]
        ),
    ]
)
```

**Step 2: Create directory structure**

Run:
```bash
mkdir -p Sources/HealthQLParser
mkdir -p Tests/HealthQLParserTests
```

**Step 3: Write failing test for Token types**

Create `Tests/HealthQLParserTests/TokenTests.swift`:
```swift
import Testing
@testable import HealthQLParser

@Suite("Token Tests")
struct TokenTests {

    @Test("TokenType has all required cases")
    func tokenTypes() {
        // Keywords
        #expect(TokenType.select != TokenType.from)
        #expect(TokenType.where != TokenType.groupBy)

        // Literals
        #expect(TokenType.identifier != TokenType.number)
        #expect(TokenType.string != TokenType.duration)

        // Operators
        #expect(TokenType.greaterThan != TokenType.lessThan)
    }

    @Test("Token stores value and position")
    func tokenStructure() {
        let token = Token(type: .identifier, value: "steps", line: 1, column: 5)

        #expect(token.type == .identifier)
        #expect(token.value == "steps")
        #expect(token.line == 1)
        #expect(token.column == 5)
    }
}
```

**Step 4: Run test to verify it fails**

Run: `swift test --filter TokenTests`
Expected: FAIL - "No such module 'HealthQLParser'"

**Step 5: Implement Token types**

Create `Sources/HealthQLParser/Token.swift`:
```swift
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
```

**Step 6: Run test to verify it passes**

Run: `swift test --filter TokenTests`
Expected: All tests pass

**Step 7: Commit**

```bash
git add -A
git commit -m "feat(parser): add Token types for lexer

- TokenType enum with keywords, literals, operators
- Token struct with type, value, and position
- Separate HealthQLParser module"
```

---

## Task 2: Lexer - Basic Tokenization

**Files:**
- Create: `Sources/HealthQLParser/Lexer.swift`
- Create: `Tests/HealthQLParserTests/LexerTests.swift`

**Step 1: Write failing test for basic lexer**

Create `Tests/HealthQLParserTests/LexerTests.swift`:
```swift
import Testing
@testable import HealthQLParser

@Suite("Lexer Tests")
struct LexerTests {

    @Test("Lexer tokenizes simple SELECT FROM")
    func simpleSelectFrom() throws {
        let lexer = Lexer("SELECT * FROM steps")
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 5) // SELECT, *, FROM, steps, EOF
        #expect(tokens[0].type == .select)
        #expect(tokens[1].type == .star)
        #expect(tokens[2].type == .from)
        #expect(tokens[3].type == .identifier)
        #expect(tokens[3].value == "steps")
        #expect(tokens[4].type == .eof)
    }

    @Test("Lexer handles case insensitive keywords")
    func caseInsensitiveKeywords() throws {
        let lexer = Lexer("select FROM Steps")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .select)
        #expect(tokens[1].type == .from)
        #expect(tokens[2].type == .identifier)
    }

    @Test("Lexer tokenizes numbers")
    func numbers() throws {
        let lexer = Lexer("LIMIT 10")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .number)
        #expect(tokens[1].value == "10")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LexerTests`
Expected: FAIL - "cannot find 'Lexer' in scope"

**Step 3: Implement basic Lexer**

Create `Sources/HealthQLParser/Lexer.swift`:
```swift
import Foundation

/// Errors that can occur during lexical analysis
public enum LexerError: Error, Equatable {
    case unexpectedCharacter(Character, line: Int, column: Int)
    case unterminatedString(line: Int, column: Int)
}

/// Tokenizes a HealthQL query string
public final class Lexer: Sendable {
    private let source: String
    private let characters: [Character]
    private var current: Int = 0
    private var line: Int = 1
    private var column: Int = 1

    /// Keyword mappings (case insensitive)
    private static let keywords: [String: TokenType] = [
        "select": .select,
        "from": .from,
        "where": .where,
        "group": .groupBy,  // Will combine with BY
        "having": .having,
        "order": .orderBy,  // Will combine with BY
        "limit": .limit,
        "asc": .asc,
        "desc": .desc,
        "and": .and,
        "or": .or,
        "not": .not,
        "is": .is,
        "null": .null,
        "by": .identifier,  // Handled specially after GROUP/ORDER
        "sum": .sum,
        "avg": .avg,
        "min": .min,
        "max": .max,
        "count": .count,
        "today": .today,
        "start_of_week": .startOfWeek,
        "start_of_month": .startOfMonth,
        "start_of_year": .startOfYear,
    ]

    public init(_ source: String) {
        self.source = source
        self.characters = Array(source)
    }

    /// Tokenize the entire source string
    public func tokenize() throws -> [Token] {
        var tokens: [Token] = []

        while !isAtEnd {
            try skipWhitespace()
            if isAtEnd { break }

            let token = try scanToken()

            // Handle GROUP BY and ORDER BY as single tokens
            if token.type == .groupBy || token.type == .orderBy {
                try skipWhitespace()
                if !isAtEnd {
                    let next = try scanToken()
                    if next.value.lowercased() == "by" {
                        tokens.append(token)
                        continue
                    } else {
                        tokens.append(token)
                        tokens.append(next)
                        continue
                    }
                }
            }

            tokens.append(token)
        }

        tokens.append(Token(type: .eof, value: "", line: line, column: column))
        return tokens
    }

    private var isAtEnd: Bool {
        current >= characters.count
    }

    private func peek() -> Character? {
        guard !isAtEnd else { return nil }
        return characters[current]
    }

    private func peekNext() -> Character? {
        guard current + 1 < characters.count else { return nil }
        return characters[current + 1]
    }

    private func advance() -> Character {
        let char = characters[current]
        current += 1
        if char == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }
        return char
    }

    private func skipWhitespace() throws {
        while let char = peek() {
            if char.isWhitespace {
                _ = advance()
            } else if char == "-" && peekNext() == "-" {
                // Skip line comment
                while let c = peek(), c != "\n" {
                    _ = advance()
                }
            } else {
                break
            }
        }
    }

    private func scanToken() throws -> Token {
        let startLine = line
        let startColumn = column
        let char = advance()

        switch char {
        case "(": return Token(type: .leftParen, value: "(", line: startLine, column: startColumn)
        case ")": return Token(type: .rightParen, value: ")", line: startLine, column: startColumn)
        case ",": return Token(type: .comma, value: ",", line: startLine, column: startColumn)
        case ".": return Token(type: .dot, value: ".", line: startLine, column: startColumn)
        case "*": return Token(type: .star, value: "*", line: startLine, column: startColumn)
        case "+": return Token(type: .plus, value: "+", line: startLine, column: startColumn)
        case "-": return Token(type: .minus, value: "-", line: startLine, column: startColumn)
        case "/": return Token(type: .slash, value: "/", line: startLine, column: startColumn)

        case "=": return Token(type: .equal, value: "=", line: startLine, column: startColumn)

        case "!":
            if peek() == "=" {
                _ = advance()
                return Token(type: .notEqual, value: "!=", line: startLine, column: startColumn)
            }
            throw LexerError.unexpectedCharacter(char, line: startLine, column: startColumn)

        case "<":
            if peek() == "=" {
                _ = advance()
                return Token(type: .lessThanOrEqual, value: "<=", line: startLine, column: startColumn)
            } else if peek() == ">" {
                _ = advance()
                return Token(type: .notEqual, value: "<>", line: startLine, column: startColumn)
            }
            return Token(type: .lessThan, value: "<", line: startLine, column: startColumn)

        case ">":
            if peek() == "=" {
                _ = advance()
                return Token(type: .greaterThanOrEqual, value: ">=", line: startLine, column: startColumn)
            }
            return Token(type: .greaterThan, value: ">", line: startLine, column: startColumn)

        case "'":
            return try scanString(startLine: startLine, startColumn: startColumn)

        default:
            if char.isNumber {
                return scanNumber(startChar: char, startLine: startLine, startColumn: startColumn)
            }
            if char.isLetter || char == "_" {
                return scanIdentifier(startChar: char, startLine: startLine, startColumn: startColumn)
            }
            throw LexerError.unexpectedCharacter(char, line: startLine, column: startColumn)
        }
    }

    private func scanString(startLine: Int, startColumn: Int) throws -> Token {
        var value = ""
        while let char = peek(), char != "'" {
            value.append(advance())
        }

        guard peek() == "'" else {
            throw LexerError.unterminatedString(line: startLine, column: startColumn)
        }
        _ = advance() // consume closing quote

        return Token(type: .string, value: value, line: startLine, column: startColumn)
    }

    private func scanNumber(startChar: Character, startLine: Int, startColumn: Int) -> Token {
        var value = String(startChar)

        while let char = peek(), char.isNumber || char == "." {
            value.append(advance())
        }

        // Check for duration suffix (d, w, mo, y)
        if let suffix = peek(), suffix.isLetter {
            var durationValue = value
            while let char = peek(), char.isLetter {
                durationValue.append(advance())
            }
            return Token(type: .duration, value: durationValue, line: startLine, column: startColumn)
        }

        return Token(type: .number, value: value, line: startLine, column: startColumn)
    }

    private func scanIdentifier(startChar: Character, startLine: Int, startColumn: Int) -> Token {
        var value = String(startChar)

        while let char = peek(), char.isLetter || char.isNumber || char == "_" {
            value.append(advance())
        }

        // Check for keyword
        let lowercase = value.lowercased()
        if let keywordType = Self.keywords[lowercase] {
            return Token(type: keywordType, value: value, line: startLine, column: startColumn)
        }

        return Token(type: .identifier, value: value, line: startLine, column: startColumn)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LexerTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(parser): add Lexer for tokenizing queries

- Keywords (SELECT, FROM, WHERE, etc.)
- Operators (=, !=, <, >, <=, >=)
- Literals (identifiers, numbers, strings)
- Line comments (-- comment)
- Case insensitive keywords"
```

---

## Task 3: Lexer - Advanced Features

**Files:**
- Modify: `Sources/HealthQLParser/Lexer.swift`
- Modify: `Tests/HealthQLParserTests/LexerTests.swift`

**Step 1: Write failing tests for duration literals and date functions**

Add to `Tests/HealthQLParserTests/LexerTests.swift`:
```swift
@Suite("Lexer Duration Tests")
struct LexerDurationTests {

    @Test("Lexer tokenizes duration literals")
    func durationLiterals() throws {
        let lexer = Lexer("7d 2w 3mo 1y")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .duration)
        #expect(tokens[0].value == "7d")
        #expect(tokens[1].type == .duration)
        #expect(tokens[1].value == "2w")
        #expect(tokens[2].type == .duration)
        #expect(tokens[2].value == "3mo")
        #expect(tokens[3].type == .duration)
        #expect(tokens[3].value == "1y")
    }

    @Test("Lexer tokenizes date functions")
    func dateFunctions() throws {
        let lexer = Lexer("today() start_of_month()")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .today)
        #expect(tokens[1].type == .leftParen)
        #expect(tokens[2].type == .rightParen)
        #expect(tokens[3].type == .startOfMonth)
    }

    @Test("Lexer handles complex WHERE clause")
    func complexWhere() throws {
        let lexer = Lexer("WHERE date > today() - 7d")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .where)
        #expect(tokens[1].type == .identifier)
        #expect(tokens[1].value == "date")
        #expect(tokens[2].type == .greaterThan)
        #expect(tokens[3].type == .today)
        #expect(tokens[4].type == .leftParen)
        #expect(tokens[5].type == .rightParen)
        #expect(tokens[6].type == .minus)
        #expect(tokens[7].type == .duration)
        #expect(tokens[7].value == "7d")
    }
}
```

**Step 2: Run test to verify behavior**

Run: `swift test --filter LexerDurationTests`
Expected: All tests pass (Lexer already handles these cases)

**Step 3: Commit**

```bash
git add -A
git commit -m "test(parser): add lexer tests for durations and date functions"
```

---

## Task 4: AST Node Types

**Files:**
- Create: `Sources/HealthQLParser/AST.swift`
- Create: `Tests/HealthQLParserTests/ASTTests.swift`

**Step 1: Write failing test for AST nodes**

Create `Tests/HealthQLParserTests/ASTTests.swift`:
```swift
import Testing
@testable import HealthQLParser

@Suite("AST Tests")
struct ASTTests {

    @Test("SelectStatement holds query components")
    func selectStatement() {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("count"))],
            from: "steps",
            whereClause: nil,
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        #expect(stmt.from == "steps")
        #expect(stmt.selections.count == 1)
    }

    @Test("Expression can represent aggregates")
    func aggregateExpression() {
        let expr = Expression.aggregate(.sum, .identifier("value"))

        if case .aggregate(let fn, let inner) = expr {
            #expect(fn == .sum)
            if case .identifier(let name) = inner {
                #expect(name == "value")
            }
        }
    }

    @Test("Expression can represent date arithmetic")
    func dateArithmetic() {
        let expr = Expression.binary(
            .function(.today, []),
            .minus,
            .duration(7, .days)
        )

        if case .binary(_, let op, _) = expr {
            #expect(op == .minus)
        }
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ASTTests`
Expected: FAIL - "cannot find 'SelectStatement' in scope"

**Step 3: Implement AST nodes**

Create `Sources/HealthQLParser/AST.swift`:
```swift
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
    case unary(BinaryOperator, Expression)  // NOT, negative
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ASTTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(parser): add AST node types

- Expression enum with identifier, number, aggregate, binary, etc.
- SelectStatement struct with all SQL clauses
- AggregateFunction, DateFunction, DurationUnit enums
- GroupByClause with time periods and expressions"
```

---

## Task 5: Parser - Basic SELECT FROM

**Files:**
- Create: `Sources/HealthQLParser/Parser.swift`
- Create: `Tests/HealthQLParserTests/ParserTests.swift`

**Step 1: Write failing test for basic parsing**

Create `Tests/HealthQLParserTests/ParserTests.swift`:
```swift
import Testing
@testable import HealthQLParser

@Suite("Parser Tests")
struct ParserTests {

    @Test("Parser parses SELECT * FROM table")
    func selectStarFrom() throws {
        let parser = Parser("SELECT * FROM steps")
        let stmt = try parser.parse()

        #expect(stmt.from == "steps")
        #expect(stmt.selections.count == 1)
        #expect(stmt.selections[0] == .star)
    }

    @Test("Parser parses SELECT column FROM table")
    func selectColumnFrom() throws {
        let parser = Parser("SELECT value FROM heart_rate")
        let stmt = try parser.parse()

        #expect(stmt.from == "heart_rate")
        #expect(stmt.selections[0] == .identifier("value"))
    }

    @Test("Parser parses SELECT with aggregate")
    func selectAggregate() throws {
        let parser = Parser("SELECT sum(count) FROM steps")
        let stmt = try parser.parse()

        #expect(stmt.selections[0] == .aggregate(.sum, .identifier("count")))
    }

    @Test("Parser parses multiple selections")
    func multipleSelections() throws {
        let parser = Parser("SELECT avg(value), min(value), max(value) FROM heart_rate")
        let stmt = try parser.parse()

        #expect(stmt.selections.count == 3)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ParserTests`
Expected: FAIL - "cannot find 'Parser' in scope"

**Step 3: Implement basic Parser**

Create `Sources/HealthQLParser/Parser.swift`:
```swift
import Foundation

/// Errors that can occur during parsing
public enum ParserError: Error, Equatable {
    case unexpectedToken(expected: String, got: Token)
    case unexpectedEndOfInput
    case invalidExpression(String)
}

/// Recursive descent parser for HealthQL queries
public final class Parser: Sendable {
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
        if match(.groupBy) {
            groupBy = try parseGroupBy()
        }

        var having: Expression? = nil
        if match(.having) {
            having = try parseExpression()
        }

        var orderBy: [OrderByItem]? = nil
        if match(.orderBy) {
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
            var direction: OrderDirection = .asc
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
        var left = try parseAddition()

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
            return .unary(.and, expr)  // NOT is unary
        }
        if match(.minus) {
            let expr = try parseUnary()
            return .unary(.minus, expr)
        }

        return try parsePrimary()
    }

    private func parsePrimary() throws -> Expression {
        // Number or duration
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

        // Parenthesized expression
        if match(.leftParen) {
            let expr = try parseExpression()
            _ = try consume(.rightParen, message: ")")
            return expr
        }

        // Identifier (possibly qualified with table.column)
        if match(.identifier) {
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
        // Parse "7d", "2w", "3mo", "1y"
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ParserTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(parser): add recursive descent parser

- Parse SELECT with *, columns, and aggregates
- Parse FROM clause
- Expression parsing with precedence climbing
- Support for WHERE, GROUP BY, ORDER BY, LIMIT"
```

---

## Task 6: Parser - Complex Queries

**Files:**
- Modify: `Tests/HealthQLParserTests/ParserTests.swift`

**Step 1: Write tests for complex queries**

Add to `Tests/HealthQLParserTests/ParserTests.swift`:
```swift
@Suite("Parser Complex Query Tests")
struct ParserComplexTests {

    @Test("Parser handles WHERE with date arithmetic")
    func whereWithDateArithmetic() throws {
        let parser = Parser("SELECT sum(count) FROM steps WHERE date > today() - 7d")
        let stmt = try parser.parse()

        #expect(stmt.whereClause != nil)
        if case .binary(let left, let op, let right) = stmt.whereClause! {
            #expect(op == .greaterThan)
            #expect(left == .identifier("date"))
            if case .binary(_, .minus, .duration(7, .days)) = right {
                // Correct structure
            } else {
                Issue.record("Expected date arithmetic")
            }
        }
    }

    @Test("Parser handles GROUP BY day")
    func groupByDay() throws {
        let parser = Parser("SELECT sum(count) FROM steps GROUP BY day")
        let stmt = try parser.parse()

        #expect(stmt.groupBy == .timePeriod(.day))
    }

    @Test("Parser handles ORDER BY with direction")
    func orderByWithDirection() throws {
        let parser = Parser("SELECT value FROM heart_rate ORDER BY date DESC")
        let stmt = try parser.parse()

        #expect(stmt.orderBy?.count == 1)
        #expect(stmt.orderBy?[0].direction == .desc)
    }

    @Test("Parser handles LIMIT")
    func limitClause() throws {
        let parser = Parser("SELECT * FROM steps LIMIT 10")
        let stmt = try parser.parse()

        #expect(stmt.limit == 10)
    }

    @Test("Parser handles full complex query")
    func fullComplexQuery() throws {
        let query = """
            SELECT avg(value), min(value), max(value)
            FROM heart_rate
            WHERE date > start_of_month()
            GROUP BY day
            ORDER BY date DESC
            LIMIT 30
            """
        let parser = Parser(query)
        let stmt = try parser.parse()

        #expect(stmt.selections.count == 3)
        #expect(stmt.from == "heart_rate")
        #expect(stmt.whereClause != nil)
        #expect(stmt.groupBy == .timePeriod(.day))
        #expect(stmt.orderBy?.count == 1)
        #expect(stmt.limit == 30)
    }
}
```

**Step 2: Run tests**

Run: `swift test --filter ParserComplexTests`
Expected: All tests pass

**Step 3: Commit**

```bash
git add -A
git commit -m "test(parser): add tests for complex query parsing"
```

---

## Task 7: Compiler - AST to IR

**Files:**
- Create: `Sources/HealthQLParser/Compiler.swift`
- Create: `Tests/HealthQLParserTests/CompilerTests.swift`

**Step 1: Write failing test for compiler**

Create `Tests/HealthQLParserTests/CompilerTests.swift`:
```swift
import Testing
@testable import HealthQLParser
@testable import HealthQL

@Suite("Compiler Tests")
struct CompilerTests {

    @Test("Compiler converts simple query to IR")
    func simpleQuery() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("count"))],
            from: "steps",
            whereClause: nil,
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.steps))
        #expect(query.selections.count == 1)
    }

    @Test("Compiler maps table name to QuantityType")
    func tableNameMapping() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "heart_rate",
            whereClause: nil,
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.heartRate))
    }

    @Test("Compiler converts WHERE to predicates")
    func whereToPredicates() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .binary(
                .identifier("date"),
                .greaterThan,
                .function(.today, [])
            ),
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
        #expect(query.predicates[0].op == .greaterThan)
    }

    @Test("Compiler converts GROUP BY period")
    func groupByPeriod() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("count"))],
            from: "steps",
            whereClause: nil,
            groupBy: .timePeriod(.day),
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.grouping == .day)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CompilerTests`
Expected: FAIL - "cannot find 'Compiler' in scope"

**Step 3: Implement Compiler**

Create `Sources/HealthQLParser/Compiler.swift`:
```swift
import Foundation
import HealthQL

/// Errors that can occur during compilation
public enum CompilerError: Error, Equatable {
    case unknownTable(String)
    case unknownField(String)
    case invalidExpression(String)
    case unsupportedFeature(String)
}

/// Compiles AST SelectStatement to HealthQuery IR
public final class Compiler: Sendable {

    public init() {}

    /// Compile a SelectStatement to HealthQuery IR
    public func compile(_ stmt: SelectStatement) throws -> HealthQuery {
        // Resolve table name to QuantityType
        let source = try resolveSource(stmt.from)

        // Convert selections
        let selections = try stmt.selections.map { try compileSelection($0) }

        // Convert WHERE clause to predicates
        let predicates = try compileWhere(stmt.whereClause)

        // Convert GROUP BY
        let grouping = try compileGroupBy(stmt.groupBy)

        // Convert ORDER BY
        let ordering = try compileOrderBy(stmt.orderBy)

        return HealthQuery(
            source: source,
            selections: selections,
            predicates: predicates,
            grouping: grouping,
            having: nil,  // TODO: compile HAVING
            ordering: ordering,
            limit: stmt.limit
        )
    }

    // MARK: - Source Resolution

    private func resolveSource(_ tableName: String) throws -> HealthSource {
        // Try to find matching QuantityType by display name
        if let quantityType = QuantityType.from(displayName: tableName) {
            return .quantity(quantityType)
        }

        // Try camelCase conversion (heart_rate -> heartRate)
        let camelCase = tableName
            .split(separator: "_")
            .enumerated()
            .map { $0.offset == 0 ? String($0.element) : String($0.element).capitalized }
            .joined()

        if let quantityType = QuantityType(rawValue: camelCase) {
            return .quantity(quantityType)
        }

        throw CompilerError.unknownTable(tableName)
    }

    // MARK: - Selection Compilation

    private func compileSelection(_ expr: Expression) throws -> Selection {
        switch expr {
        case .star:
            return .field(.value)

        case .identifier(let name):
            let field = try resolveField(name)
            return .field(field)

        case .aggregate(let fn, let inner):
            let aggregate = compileAggregate(fn)
            let field = try resolveFieldFromExpression(inner)
            return .aggregate(aggregate, field)

        default:
            throw CompilerError.invalidExpression("Cannot use complex expression in SELECT")
        }
    }

    private func compileAggregate(_ fn: AggregateFunction) -> Aggregate {
        switch fn {
        case .sum: return .sum
        case .avg: return .avg
        case .min: return .min
        case .max: return .max
        case .count: return .count
        }
    }

    private func resolveField(_ name: String) throws -> Field {
        switch name.lowercased() {
        case "value", "count": return .value
        case "date", "start_date": return .date
        case "end_date": return .endDate
        case "source": return .source
        case "device": return .device
        default:
            throw CompilerError.unknownField(name)
        }
    }

    private func resolveFieldFromExpression(_ expr: Expression) throws -> Field {
        switch expr {
        case .identifier(let name):
            return try resolveField(name)
        case .star:
            return .value
        default:
            throw CompilerError.invalidExpression("Expected field name in aggregate")
        }
    }

    // MARK: - WHERE Compilation

    private func compileWhere(_ expr: Expression?) throws -> [Predicate] {
        guard let expr = expr else { return [] }

        // Handle AND at top level
        if case .binary(let left, .and, let right) = expr {
            let leftPredicates = try compileWhere(left)
            let rightPredicates = try compileWhere(right)
            return leftPredicates + rightPredicates
        }

        // Single comparison
        if case .binary(let left, let op, let right) = expr {
            let field = try resolveFieldFromExpression(left)
            let irOp = try compileOperator(op)
            let value = try compileValue(right)
            return [Predicate(field: field, op: irOp, value: value)]
        }

        // IS NULL / IS NOT NULL
        if case .isNull(let inner, let negated) = expr {
            let field = try resolveFieldFromExpression(inner)
            let op: Operator = negated ? .isNotNull : .isNull
            return [Predicate(field: field, op: op, value: .null)]
        }

        throw CompilerError.invalidExpression("Unsupported WHERE expression")
    }

    private func compileOperator(_ op: BinaryOperator) throws -> Operator {
        switch op {
        case .equal: return .equal
        case .notEqual: return .notEqual
        case .greaterThan: return .greaterThan
        case .greaterThanOrEqual: return .greaterThanOrEqual
        case .lessThan: return .lessThan
        case .lessThanOrEqual: return .lessThanOrEqual
        default:
            throw CompilerError.unsupportedFeature("Operator \(op) not supported in WHERE")
        }
    }

    private func compileValue(_ expr: Expression) throws -> PredicateValue {
        switch expr {
        case .number(let n):
            return .double(n)

        case .string(let s):
            return .string(s)

        case .function(let fn, _):
            let date = resolveDateFunction(fn)
            return .date(date)

        case .binary(let left, .minus, let right):
            // Handle date arithmetic: today() - 7d
            if case .function(let fn, _) = left,
               case .duration(let num, let unit) = right {
                let baseDate = resolveDateFunction(fn)
                let resultDate = subtractDuration(from: baseDate, amount: num, unit: unit)
                return .date(resultDate)
            }
            throw CompilerError.invalidExpression("Unsupported arithmetic in value")

        case .duration(let num, let unit):
            // Duration alone - calculate from today
            let resultDate = subtractDuration(from: Date(), amount: num, unit: unit)
            return .date(resultDate)

        default:
            throw CompilerError.invalidExpression("Cannot use expression as predicate value")
        }
    }

    private func resolveDateFunction(_ fn: DateFunction) -> Date {
        let calendar = Calendar.current
        let now = Date()

        switch fn {
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
        }
    }

    private func subtractDuration(from date: Date, amount: Int, unit: DurationUnit) -> Date {
        let calendar = Calendar.current

        switch unit {
        case .days:
            return calendar.date(byAdding: .day, value: -amount, to: date) ?? date
        case .weeks:
            return calendar.date(byAdding: .weekOfYear, value: -amount, to: date) ?? date
        case .months:
            return calendar.date(byAdding: .month, value: -amount, to: date) ?? date
        case .years:
            return calendar.date(byAdding: .year, value: -amount, to: date) ?? date
        }
    }

    // MARK: - GROUP BY Compilation

    private func compileGroupBy(_ groupBy: GroupByClause?) throws -> GroupBy? {
        guard let groupBy = groupBy else { return nil }

        switch groupBy {
        case .timePeriod(let period):
            switch period {
            case .hour: return .hour
            case .day: return .day
            case .week: return .week
            case .month: return .month
            case .year: return .year
            }
        case .expression:
            throw CompilerError.unsupportedFeature("GROUP BY expression not yet supported")
        }
    }

    // MARK: - ORDER BY Compilation

    private func compileOrderBy(_ orderBy: [OrderByItem]?) throws -> [OrderBy]? {
        guard let orderBy = orderBy else { return nil }

        return try orderBy.map { item in
            let field = try resolveFieldFromExpression(item.expression)
            let direction: HealthQL.OrderDirection = item.direction == .asc ? .ascending : .descending
            return OrderBy(field: field, direction: direction)
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter CompilerTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(parser): add Compiler to transform AST to IR

- Resolve table names to QuantityType
- Compile selections (*, columns, aggregates)
- Compile WHERE to predicates with date arithmetic
- Compile GROUP BY time periods
- Compile ORDER BY with direction"
```

---

## Task 8: Public API - HealthQL.query()

**Files:**
- Create: `Sources/HealthQLParser/HealthQLParser.swift`
- Create: `Tests/HealthQLParserTests/IntegrationTests.swift`

**Step 1: Write failing test for public API**

Create `Tests/HealthQLParserTests/IntegrationTests.swift`:
```swift
import Testing
@testable import HealthQLParser
@testable import HealthQL

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("HealthQL.query parses and executes")
    func queryEndToEnd() async throws {
        let result = try await HealthQL.query("SELECT sum(count) FROM steps WHERE date > today() - 7d GROUP BY day")

        // Result may be empty but should not throw
        #expect(result.executionTime >= 0)
    }

    @Test("HealthQL.parse returns HealthQuery IR")
    func parseOnly() throws {
        let query = try HealthQL.parse("SELECT avg(value) FROM heart_rate")

        #expect(query.source == .quantity(.heartRate))
    }

    @Test("Complex query parses correctly")
    func complexQuery() throws {
        let query = try HealthQL.parse("""
            SELECT avg(value), min(value), max(value)
            FROM heart_rate
            WHERE date > start_of_month()
            GROUP BY day
            ORDER BY date DESC
            LIMIT 30
        """)

        #expect(query.selections.count == 3)
        #expect(query.grouping == .day)
        #expect(query.limit == 30)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter IntegrationTests`
Expected: FAIL - "Type 'HealthQL' has no member 'query'"

**Step 3: Implement public API**

Create `Sources/HealthQLParser/HealthQLParser.swift`:
```swift
import Foundation
import HealthQL

/// Extension to add string query support to HealthQL
extension HealthQL {

    /// Parse a SQL-like query string into HealthQuery IR
    /// - Parameter query: The query string (e.g., "SELECT sum(count) FROM steps")
    /// - Returns: The HealthQuery intermediate representation
    /// - Throws: LexerError, ParserError, or CompilerError
    public static func parse(_ query: String) throws -> HealthQuery {
        let parser = Parser(query)
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter IntegrationTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(parser): add HealthQL.query() and .parse() public API

- HealthQL.parse() converts string to HealthQuery IR
- HealthQL.query() parses and executes in one call
- Full pipeline: String -> Tokens -> AST -> IR -> Execution"
```

---

## Task 9: Run Full Test Suite

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 2: Verify build**

Run: `swift build`
Expected: Build Succeeded

**Step 3: Commit if needed**

```bash
git status
# If clean, no commit needed
```

---

## Phase 2 Complete

At the end of Phase 2, you have:

- **Lexer** that tokenizes SQL-like query strings
- **Parser** using recursive descent with precedence climbing
- **AST** representing the query structure
- **Compiler** transforming AST to HealthQuery IR
- **Public API**: `HealthQL.query("SELECT...")` and `HealthQL.parse("SELECT...")`

**Supported syntax:**
```sql
SELECT sum(count), avg(value), *
FROM steps, heart_rate, active_calories, ...
WHERE date > today() - 7d
GROUP BY hour/day/week/month/year
ORDER BY date ASC/DESC
LIMIT 10
```

**Next:** Phase 3 builds the REPL playground app.
