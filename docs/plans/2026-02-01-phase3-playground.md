# HealthQL Phase 3: Playground App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an interactive REPL playground app for macOS that lets users write SQL-like queries against their HealthKit data with autocomplete, history, and formatted output.

**Architecture:** Core REPL logic is implemented as testable library code in a new `HealthQLPlayground` module. A simple SwiftUI macOS app wraps the REPL engine, providing text input/output, history navigation, and formatted table display. Meta commands (`.schema`, `.types`, `.history`, `.clear`) are handled separately from SQL queries.

**Tech Stack:** Swift 6.2, SwiftUI, HealthQLParser module, macOS 13+

---

## Task 1: REPL Engine - Result Formatter

**Files:**
- Create: `Sources/HealthQLPlayground/ResultFormatter.swift`
- Create: `Tests/HealthQLPlaygroundTests/ResultFormatterTests.swift`
- Modify: `Package.swift`

**Step 1: Update Package.swift to add HealthQLPlayground module**

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
        .library(
            name: "HealthQLPlayground",
            targets: ["HealthQLPlayground"]
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
        .target(
            name: "HealthQLPlayground",
            dependencies: ["HealthQL", "HealthQLParser"]
        ),
        .testTarget(
            name: "HealthQLTests",
            dependencies: ["HealthQL"]
        ),
        .testTarget(
            name: "HealthQLParserTests",
            dependencies: ["HealthQLParser"]
        ),
        .testTarget(
            name: "HealthQLPlaygroundTests",
            dependencies: ["HealthQLPlayground"]
        ),
    ]
)
```

**Step 2: Create directory structure**

Run:
```bash
mkdir -p Sources/HealthQLPlayground
mkdir -p Tests/HealthQLPlaygroundTests
```

**Step 3: Write failing test for ResultFormatter**

Create `Tests/HealthQLPlaygroundTests/ResultFormatterTests.swift`:
```swift
import Testing
@testable import HealthQLPlayground
@testable import HealthQL

@Suite("Result Formatter Tests")
struct ResultFormatterTests {

    @Test("Formats empty result")
    func emptyResult() {
        let result = QueryResult(rows: [], executionTime: 0.023)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("0 rows"))
    }

    @Test("Formats single row result")
    func singleRow() {
        let row = ResultRow(values: [
            "date": .date(Date(timeIntervalSince1970: 0)),
            "sum": .double(8432)
        ])
        let result = QueryResult(rows: [row], executionTime: 0.015)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("date"))
        #expect(output.contains("sum"))
        #expect(output.contains("8432") || output.contains("8,432"))
        #expect(output.contains("1 row"))
    }

    @Test("Formats multiple rows as table")
    func multipleRows() {
        let rows = [
            ResultRow(values: ["name": .string("steps"), "count": .double(100)]),
            ResultRow(values: ["name": .string("heart_rate"), "count": .double(500)]),
        ]
        let result = QueryResult(rows: rows, executionTime: 0.005)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("steps"))
        #expect(output.contains("heart_rate"))
        #expect(output.contains("2 rows"))
    }

    @Test("Includes execution time")
    func executionTime() {
        let result = QueryResult(rows: [], executionTime: 0.023)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("23ms") || output.contains("0.023"))
    }
}
```

**Step 4: Run test to verify it fails**

Run: `swift test --filter ResultFormatterTests`
Expected: FAIL - "No such module 'HealthQLPlayground'"

**Step 5: Implement ResultFormatter**

Create `Sources/HealthQLPlayground/ResultFormatter.swift`:
```swift
import Foundation
import HealthQL

/// Formats QueryResult as ASCII table for REPL display
public struct ResultFormatter: Sendable {

    public init() {}

    /// Format a QueryResult as a displayable string
    public func format(_ result: QueryResult) -> String {
        var output = ""

        if result.rows.isEmpty {
            output += "0 rows"
        } else {
            // Get column names from first row
            let columns = result.rows[0].values.keys.sorted()

            // Calculate column widths
            var widths: [String: Int] = [:]
            for col in columns {
                widths[col] = col.count
            }
            for row in result.rows {
                for col in columns {
                    if let value = row.values[col] {
                        let str = formatValue(value)
                        widths[col] = max(widths[col] ?? 0, str.count)
                    }
                }
            }

            // Build table
            output += formatTableHeader(columns: columns, widths: widths)
            output += formatTableSeparator(columns: columns, widths: widths)
            for row in result.rows {
                output += formatTableRow(row: row, columns: columns, widths: widths)
            }
            output += formatTableFooter(columns: columns, widths: widths)

            // Row count
            let rowWord = result.rows.count == 1 ? "row" : "rows"
            output += "\n\(result.rows.count) \(rowWord)"
        }

        // Execution time
        let ms = Int(result.executionTime * 1000)
        output += " (\(ms)ms)"

        return output
    }

    private func formatValue(_ value: ResultValue) -> String {
        switch value {
        case .double(let d):
            if d == d.rounded() && d < 1_000_000 {
                return formatNumber(Int(d))
            }
            return String(format: "%.2f", d)
        case .string(let s):
            return s
        case .date(let d):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: d)
        case .null:
            return "NULL"
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func formatTableHeader(columns: [String], widths: [String: Int]) -> String {
        var line = "│"
        for col in columns {
            let width = widths[col] ?? col.count
            line += " " + col.padding(toLength: width, withPad: " ", startingAt: 0) + " │"
        }
        return line + "\n"
    }

    private func formatTableSeparator(columns: [String], widths: [String: Int]) -> String {
        var line = "├"
        for (i, col) in columns.enumerated() {
            let width = widths[col] ?? col.count
            line += String(repeating: "─", count: width + 2)
            line += i < columns.count - 1 ? "┼" : "┤"
        }
        return line + "\n"
    }

    private func formatTableRow(row: ResultRow, columns: [String], widths: [String: Int]) -> String {
        var line = "│"
        for col in columns {
            let width = widths[col] ?? col.count
            let value = row.values[col].map { formatValue($0) } ?? ""
            line += " " + value.padding(toLength: width, withPad: " ", startingAt: 0) + " │"
        }
        return line + "\n"
    }

    private func formatTableFooter(columns: [String], widths: [String: Int]) -> String {
        var line = "└"
        for (i, col) in columns.enumerated() {
            let width = widths[col] ?? col.count
            line += String(repeating: "─", count: width + 2)
            line += i < columns.count - 1 ? "┴" : "┘"
        }
        return line
    }
}
```

**Step 6: Run test to verify it passes**

Run: `swift test --filter ResultFormatterTests`
Expected: All tests pass

**Step 7: Commit**

```bash
git add -A
git commit -m "feat(playground): add ResultFormatter for table display

- Formats QueryResult as ASCII table
- Handles dates, numbers, strings, nulls
- Shows row count and execution time"
```

---

## Task 2: Meta Command Parser

**Files:**
- Create: `Sources/HealthQLPlayground/MetaCommand.swift`
- Create: `Tests/HealthQLPlaygroundTests/MetaCommandTests.swift`

**Step 1: Write failing test for meta commands**

Create `Tests/HealthQLPlaygroundTests/MetaCommandTests.swift`:
```swift
import Testing
@testable import HealthQLPlayground

@Suite("Meta Command Tests")
struct MetaCommandTests {

    @Test("Parses .types command")
    func typesCommand() {
        let result = MetaCommand.parse(".types")

        #expect(result == .types)
    }

    @Test("Parses .schema with argument")
    func schemaCommand() {
        let result = MetaCommand.parse(".schema steps")

        #expect(result == .schema("steps"))
    }

    @Test("Parses .history command")
    func historyCommand() {
        let result = MetaCommand.parse(".history")

        #expect(result == .history)
    }

    @Test("Parses .clear command")
    func clearCommand() {
        let result = MetaCommand.parse(".clear")

        #expect(result == .clear)
    }

    @Test("Parses .help command")
    func helpCommand() {
        let result = MetaCommand.parse(".help")

        #expect(result == .help)
    }

    @Test("Returns nil for SQL query")
    func sqlQuery() {
        let result = MetaCommand.parse("SELECT * FROM steps")

        #expect(result == nil)
    }

    @Test("Returns unknown for invalid meta command")
    func unknownCommand() {
        let result = MetaCommand.parse(".invalid")

        #expect(result == .unknown(".invalid"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter MetaCommandTests`
Expected: FAIL - "cannot find 'MetaCommand' in scope"

**Step 3: Implement MetaCommand**

Create `Sources/HealthQLPlayground/MetaCommand.swift`:
```swift
import Foundation

/// Meta commands for the REPL (prefixed with .)
public enum MetaCommand: Equatable, Sendable {
    case types                    // .types - list all health types
    case schema(String)           // .schema <type> - show fields for type
    case history                  // .history - show command history
    case clear                    // .clear - clear screen
    case help                     // .help - show help
    case export(ExportFormat)     // .export csv - export last result
    case unknown(String)          // unknown command

    public enum ExportFormat: String, Equatable, Sendable {
        case csv
        case json
    }

    /// Parse a string into a MetaCommand, or nil if it's not a meta command
    public static func parse(_ input: String) -> MetaCommand? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Meta commands start with .
        guard trimmed.hasPrefix(".") else { return nil }

        let parts = trimmed.dropFirst().split(separator: " ", maxSplits: 1)
        guard let command = parts.first else { return .unknown(trimmed) }

        let arg = parts.count > 1 ? String(parts[1]) : nil

        switch command.lowercased() {
        case "types":
            return .types
        case "schema":
            guard let typeName = arg else {
                return .unknown(trimmed)
            }
            return .schema(typeName)
        case "history":
            return .history
        case "clear":
            return .clear
        case "help":
            return .help
        case "export":
            if let format = arg, let exportFormat = ExportFormat(rawValue: format.lowercased()) {
                return .export(exportFormat)
            }
            return .export(.csv) // default to CSV
        default:
            return .unknown(trimmed)
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter MetaCommandTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(playground): add MetaCommand parser

- .types, .schema, .history, .clear, .help
- .export with csv/json formats
- Returns nil for SQL queries"
```

---

## Task 3: Command History Manager

**Files:**
- Create: `Sources/HealthQLPlayground/History.swift`
- Create: `Tests/HealthQLPlaygroundTests/HistoryTests.swift`

**Step 1: Write failing test for History**

Create `Tests/HealthQLPlaygroundTests/HistoryTests.swift`:
```swift
import Testing
@testable import HealthQLPlayground

@Suite("History Tests")
struct HistoryTests {

    @Test("History starts empty")
    func startsEmpty() {
        let history = History()

        #expect(history.entries.isEmpty)
        #expect(history.current == nil)
    }

    @Test("Adding entry updates history")
    func addEntry() {
        var history = History()
        history.add("SELECT * FROM steps")

        #expect(history.entries.count == 1)
        #expect(history.entries[0] == "SELECT * FROM steps")
    }

    @Test("Navigate up returns previous entry")
    func navigateUp() {
        var history = History()
        history.add("query1")
        history.add("query2")

        let result = history.up()

        #expect(result == "query2")
    }

    @Test("Navigate up twice returns older entry")
    func navigateUpTwice() {
        var history = History()
        history.add("query1")
        history.add("query2")

        _ = history.up()
        let result = history.up()

        #expect(result == "query1")
    }

    @Test("Navigate down returns newer entry")
    func navigateDown() {
        var history = History()
        history.add("query1")
        history.add("query2")

        _ = history.up() // query2
        _ = history.up() // query1
        let result = history.down()

        #expect(result == "query2")
    }

    @Test("Navigate down at end returns nil")
    func navigateDownAtEnd() {
        var history = History()
        history.add("query1")

        _ = history.up()
        _ = history.down()
        let result = history.down()

        #expect(result == nil)
    }

    @Test("Reset clears navigation position")
    func reset() {
        var history = History()
        history.add("query1")
        history.add("query2")

        _ = history.up()
        history.reset()
        let result = history.up()

        #expect(result == "query2")
    }

    @Test("Does not add duplicate consecutive entries")
    func noDuplicates() {
        var history = History()
        history.add("query1")
        history.add("query1")

        #expect(history.entries.count == 1)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter HistoryTests`
Expected: FAIL - "cannot find 'History' in scope"

**Step 3: Implement History**

Create `Sources/HealthQLPlayground/History.swift`:
```swift
import Foundation

/// Manages command history with up/down navigation
public struct History: Sendable {
    public private(set) var entries: [String] = []
    private var position: Int? = nil
    private let maxEntries: Int

    public var current: String? {
        guard let pos = position, pos >= 0, pos < entries.count else { return nil }
        return entries[pos]
    }

    public init(maxEntries: Int = 100) {
        self.maxEntries = maxEntries
    }

    /// Add a new entry to history
    public mutating func add(_ entry: String) {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Don't add duplicates consecutively
        if entries.last == trimmed { return }

        entries.append(trimmed)

        // Trim old entries
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }

        // Reset navigation
        position = nil
    }

    /// Navigate up (older entries)
    public mutating func up() -> String? {
        if entries.isEmpty { return nil }

        if position == nil {
            position = entries.count - 1
        } else if position! > 0 {
            position! -= 1
        }

        return current
    }

    /// Navigate down (newer entries)
    public mutating func down() -> String? {
        guard let pos = position else { return nil }

        if pos < entries.count - 1 {
            position = pos + 1
            return current
        } else {
            position = nil
            return nil
        }
    }

    /// Reset navigation position
    public mutating func reset() {
        position = nil
    }

    /// Get all entries for display
    public func all() -> [String] {
        entries
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter HistoryTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(playground): add History manager

- Up/down navigation through entries
- Prevents consecutive duplicates
- Configurable max entries"
```

---

## Task 4: Schema Info Provider

**Files:**
- Create: `Sources/HealthQLPlayground/SchemaInfo.swift`
- Create: `Tests/HealthQLPlaygroundTests/SchemaInfoTests.swift`

**Step 1: Write failing test for SchemaInfo**

Create `Tests/HealthQLPlaygroundTests/SchemaInfoTests.swift`:
```swift
import Testing
@testable import HealthQLPlayground
@testable import HealthQL

@Suite("Schema Info Tests")
struct SchemaInfoTests {

    @Test("Lists all available types")
    func allTypes() {
        let info = SchemaInfo()
        let types = info.allTypes()

        #expect(types.contains("steps"))
        #expect(types.contains("heart_rate"))
        #expect(types.contains("active_calories"))
    }

    @Test("Returns schema for valid type")
    func schemaForType() {
        let info = SchemaInfo()
        let schema = info.schema(for: "steps")

        #expect(schema != nil)
        #expect(schema!.fields.contains("value"))
        #expect(schema!.fields.contains("date"))
    }

    @Test("Returns nil for invalid type")
    func schemaForInvalidType() {
        let info = SchemaInfo()
        let schema = info.schema(for: "invalid_type")

        #expect(schema == nil)
    }

    @Test("Suggests similar type names")
    func suggestsSimilar() {
        let info = SchemaInfo()
        let suggestions = info.suggest(for: "stepz")

        #expect(suggestions.contains("steps"))
    }

    @Test("Returns type display info")
    func typeDisplayInfo() {
        let info = SchemaInfo()
        let schema = info.schema(for: "heart_rate")

        #expect(schema?.unit == "count/min")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SchemaInfoTests`
Expected: FAIL - "cannot find 'SchemaInfo' in scope"

**Step 3: Implement SchemaInfo**

Create `Sources/HealthQLPlayground/SchemaInfo.swift`:
```swift
import Foundation
import HealthQL

/// Provides schema information for REPL commands
public struct SchemaInfo: Sendable {

    public struct TypeSchema: Sendable {
        public let name: String
        public let displayName: String
        public let fields: [String]
        public let unit: String
    }

    public init() {}

    /// Get all available type names
    public func allTypes() -> [String] {
        QuantityType.allCases.map { $0.displayName }
    }

    /// Get schema for a specific type
    public func schema(for typeName: String) -> TypeSchema? {
        // Try exact match first
        if let type = QuantityType.from(displayName: typeName) {
            return typeSchema(for: type)
        }

        // Try camelCase conversion
        let camelCase = typeName
            .split(separator: "_")
            .enumerated()
            .map { $0.offset == 0 ? String($0.element) : String($0.element).capitalized }
            .joined()

        if let type = QuantityType(rawValue: camelCase) {
            return typeSchema(for: type)
        }

        return nil
    }

    /// Suggest similar type names for typos
    public func suggest(for typeName: String) -> [String] {
        let allNames = allTypes()
        let lowercased = typeName.lowercased()

        return allNames.filter { name in
            // Simple similarity check: contains most characters or starts with same prefix
            let nameLC = name.lowercased()
            let commonPrefix = nameLC.commonPrefix(with: lowercased)
            let similarity = Double(commonPrefix.count) / Double(max(nameLC.count, lowercased.count))

            return similarity > 0.5 || levenshteinDistance(nameLC, lowercased) <= 2
        }
    }

    private func typeSchema(for type: QuantityType) -> TypeSchema {
        TypeSchema(
            name: type.rawValue,
            displayName: type.displayName,
            fields: ["value", "date", "end_date", "source", "device"],
            unit: type.defaultUnit.unitString
        )
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = Swift.min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }

        return matrix[m][n]
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter SchemaInfoTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(playground): add SchemaInfo for type introspection

- Lists all available health types
- Returns field info for each type
- Suggests similar names for typos"
```

---

## Task 5: REPL Engine Core

**Files:**
- Create: `Sources/HealthQLPlayground/REPLEngine.swift`
- Create: `Tests/HealthQLPlaygroundTests/REPLEngineTests.swift`

**Step 1: Write failing test for REPLEngine**

Create `Tests/HealthQLPlaygroundTests/REPLEngineTests.swift`:
```swift
import Testing
@testable import HealthQLPlayground
@testable import HealthQL

@Suite("REPL Engine Tests")
struct REPLEngineTests {

    @Test("Executes .types command")
    func typesCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".types")

        #expect(result.contains("steps"))
        #expect(result.contains("heart_rate"))
    }

    @Test("Executes .schema command")
    func schemaCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".schema steps")

        #expect(result.contains("value"))
        #expect(result.contains("date"))
    }

    @Test("Executes .help command")
    func helpCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".help")

        #expect(result.contains(".types"))
        #expect(result.contains(".schema"))
    }

    @Test("Returns error for unknown command")
    func unknownCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".invalid")

        #expect(result.contains("Unknown command"))
    }

    @Test("Executes SQL query")
    func sqlQuery() async {
        let engine = REPLEngine()
        let result = await engine.execute("SELECT sum(count) FROM steps")

        // Should either show results or error (no HealthKit access in tests)
        #expect(!result.isEmpty)
    }

    @Test("Shows error suggestion for typos")
    func typoSuggestion() async {
        let engine = REPLEngine()
        let result = await engine.execute("SELECT * FROM stepz")

        #expect(result.contains("steps") || result.contains("Error"))
    }

    @Test("History is updated after command")
    func historyUpdated() async {
        let engine = REPLEngine()
        _ = await engine.execute("SELECT * FROM steps")

        #expect(engine.history.entries.contains("SELECT * FROM steps"))
    }

    @Test("Meta commands not added to history")
    func metaNotInHistory() async {
        let engine = REPLEngine()
        _ = await engine.execute(".types")

        #expect(!engine.history.entries.contains(".types"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter REPLEngineTests`
Expected: FAIL - "cannot find 'REPLEngine' in scope"

**Step 3: Implement REPLEngine**

Create `Sources/HealthQLPlayground/REPLEngine.swift`:
```swift
import Foundation
import HealthQL
import HealthQLParser

/// Core REPL engine that processes commands and queries
public final class REPLEngine: @unchecked Sendable {
    public private(set) var history = History()
    private let formatter = ResultFormatter()
    private let schemaInfo = SchemaInfo()
    private var lastResult: QueryResult?

    public init() {}

    /// Execute a command or query and return the output
    public func execute(_ input: String) async -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // Check for meta command
        if let metaCommand = MetaCommand.parse(trimmed) {
            return executeMetaCommand(metaCommand)
        }

        // Execute as SQL query
        history.add(trimmed)
        return await executeQuery(trimmed)
    }

    /// Navigate history up
    public func historyUp() -> String? {
        history.up()
    }

    /// Navigate history down
    public func historyDown() -> String? {
        history.down()
    }

    /// Reset history navigation
    public func resetHistoryNavigation() {
        history.reset()
    }

    // MARK: - Meta Commands

    private func executeMetaCommand(_ command: MetaCommand) -> String {
        switch command {
        case .types:
            return formatTypes()
        case .schema(let typeName):
            return formatSchema(for: typeName)
        case .history:
            return formatHistory()
        case .clear:
            return "\u{001B}[2J\u{001B}[H" // ANSI clear screen
        case .help:
            return formatHelp()
        case .export(let format):
            return exportLastResult(format: format)
        case .unknown(let cmd):
            return "Unknown command: \(cmd)\nType .help for available commands."
        }
    }

    private func formatTypes() -> String {
        let types = schemaInfo.allTypes()
        var output = "Available health types:\n"
        for type in types.sorted() {
            output += "  \(type)\n"
        }
        return output
    }

    private func formatSchema(for typeName: String) -> String {
        guard let schema = schemaInfo.schema(for: typeName) else {
            let suggestions = schemaInfo.suggest(for: typeName)
            var output = "Unknown type: '\(typeName)'"
            if !suggestions.isEmpty {
                output += "\nDid you mean: \(suggestions.joined(separator: ", "))?"
            }
            return output
        }

        var output = "\(schema.displayName)\n"
        output += "  Unit: \(schema.unit)\n"
        output += "  Fields:\n"
        for field in schema.fields {
            output += "    - \(field)\n"
        }
        return output
    }

    private func formatHistory() -> String {
        let entries = history.all()
        if entries.isEmpty {
            return "No history."
        }

        var output = "Query history:\n"
        for (i, entry) in entries.enumerated() {
            output += "  \(i + 1). \(entry)\n"
        }
        return output
    }

    private func formatHelp() -> String {
        """
        HealthQL REPL Commands:

        SQL Queries:
          SELECT <fields> FROM <type> [WHERE ...] [GROUP BY ...] [ORDER BY ...] [LIMIT n]

        Meta Commands:
          .types          - List all available health types
          .schema <type>  - Show fields and info for a type
          .history        - Show query history
          .export csv     - Export last result to CSV
          .export json    - Export last result to JSON
          .clear          - Clear the screen
          .help           - Show this help message

        Examples:
          SELECT sum(count) FROM steps WHERE date > today() - 7d GROUP BY day
          SELECT avg(value) FROM heart_rate WHERE date > start_of_month()
          .schema steps
        """
    }

    private func exportLastResult(format: MetaCommand.ExportFormat) -> String {
        guard let result = lastResult else {
            return "No results to export. Run a query first."
        }

        switch format {
        case .csv:
            return exportCSV(result)
        case .json:
            return exportJSON(result)
        }
    }

    private func exportCSV(_ result: QueryResult) -> String {
        guard let firstRow = result.rows.first else {
            return "No data to export."
        }

        let columns = firstRow.values.keys.sorted()
        var csv = columns.joined(separator: ",") + "\n"

        for row in result.rows {
            let values = columns.map { col -> String in
                guard let value = row.values[col] else { return "" }
                switch value {
                case .double(let d): return "\(d)"
                case .string(let s): return "\"\(s)\""
                case .date(let d):
                    let formatter = ISO8601DateFormatter()
                    return formatter.string(from: d)
                case .null: return ""
                }
            }
            csv += values.joined(separator: ",") + "\n"
        }

        return "CSV Export:\n\(csv)"
    }

    private func exportJSON(_ result: QueryResult) -> String {
        var json: [[String: Any]] = []

        for row in result.rows {
            var obj: [String: Any] = [:]
            for (key, value) in row.values {
                switch value {
                case .double(let d): obj[key] = d
                case .string(let s): obj[key] = s
                case .date(let d): obj[key] = ISO8601DateFormatter().string(from: d)
                case .null: obj[key] = NSNull()
                }
            }
            json.append(obj)
        }

        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            return "JSON Export:\n\(jsonString)"
        }

        return "Failed to export JSON."
    }

    // MARK: - Query Execution

    private func executeQuery(_ query: String) async -> String {
        do {
            let result = try await HQL.query(query)
            lastResult = result
            return formatter.format(result)
        } catch let error as CompilerError {
            return formatCompilerError(error, query: query)
        } catch let error as ParserError {
            return formatParserError(error)
        } catch let error as LexerError {
            return formatLexerError(error)
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    private func formatCompilerError(_ error: CompilerError, query: String) -> String {
        switch error {
        case .unknownTable(let name):
            let suggestions = schemaInfo.suggest(for: name)
            var output = "Error: Unknown type '\(name)'."
            if !suggestions.isEmpty {
                output += " Did you mean '\(suggestions.first!)'?"
            }
            return output
        case .unknownField(let name):
            return "Error: Unknown field '\(name)'."
        case .invalidExpression(let msg):
            return "Error: \(msg)"
        case .unsupportedFeature(let msg):
            return "Error: \(msg)"
        }
    }

    private func formatParserError(_ error: ParserError) -> String {
        switch error {
        case .unexpectedToken(let expected, let got):
            return "Syntax error at line \(got.line), column \(got.column): Expected \(expected), got '\(got.value)'"
        case .unexpectedEndOfInput:
            return "Syntax error: Unexpected end of input"
        case .invalidExpression(let msg):
            return "Syntax error: \(msg)"
        }
    }

    private func formatLexerError(_ error: LexerError) -> String {
        switch error {
        case .unexpectedCharacter(let char, let line, let column):
            return "Syntax error at line \(line), column \(column): Unexpected character '\(char)'"
        case .unterminatedString(let line, let column):
            return "Syntax error at line \(line), column \(column): Unterminated string"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter REPLEngineTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(playground): add REPLEngine core

- Executes SQL queries via HQL.query()
- Handles all meta commands
- Maintains query history
- Provides helpful error messages with suggestions"
```

---

## Task 6: Autocomplete Provider

**Files:**
- Create: `Sources/HealthQLPlayground/Autocomplete.swift`
- Create: `Tests/HealthQLPlaygroundTests/AutocompleteTests.swift`

**Step 1: Write failing test for Autocomplete**

Create `Tests/HealthQLPlaygroundTests/AutocompleteTests.swift`:
```swift
import Testing
@testable import HealthQLPlayground

@Suite("Autocomplete Tests")
struct AutocompleteTests {

    @Test("Suggests keywords at start")
    func keywordsAtStart() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SEL", cursorPosition: 3)

        #expect(suggestions.contains("SELECT"))
    }

    @Test("Suggests types after FROM")
    func typesAfterFrom() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM st", cursorPosition: 16)

        #expect(suggestions.contains("steps"))
    }

    @Test("Suggests fields after SELECT")
    func fieldsAfterSelect() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT va", cursorPosition: 9)

        #expect(suggestions.contains("value"))
    }

    @Test("Suggests aggregates after SELECT")
    func aggregatesAfterSelect() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT su", cursorPosition: 9)

        #expect(suggestions.contains("sum("))
    }

    @Test("Suggests clauses after type")
    func clausesAfterType() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM steps WH", cursorPosition: 22)

        #expect(suggestions.contains("WHERE"))
    }

    @Test("Suggests time periods after GROUP BY")
    func timePeriodsAfterGroupBy() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT sum(count) FROM steps GROUP BY d", cursorPosition: 39)

        #expect(suggestions.contains("day"))
    }

    @Test("Suggests date functions")
    func dateFunctions() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM steps WHERE date > to", cursorPosition: 35)

        #expect(suggestions.contains("today()"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AutocompleteTests`
Expected: FAIL - "cannot find 'Autocomplete' in scope"

**Step 3: Implement Autocomplete**

Create `Sources/HealthQLPlayground/Autocomplete.swift`:
```swift
import Foundation
import HealthQL

/// Provides autocomplete suggestions for the REPL
public struct Autocomplete: Sendable {

    private let keywords = ["SELECT", "FROM", "WHERE", "GROUP", "BY", "ORDER", "HAVING", "LIMIT", "ASC", "DESC", "AND", "OR", "NOT", "IS", "NULL"]
    private let aggregates = ["sum(", "avg(", "min(", "max(", "count("]
    private let fields = ["value", "date", "end_date", "source", "device", "*"]
    private let timePeriods = ["hour", "day", "week", "month", "year"]
    private let dateFunctions = ["today()", "start_of_week()", "start_of_month()", "start_of_year()"]
    private let durationSuffixes = ["d", "w", "mo", "y"]

    public init() {}

    /// Get autocomplete suggestions for current input
    public func suggest(for input: String, cursorPosition: Int) -> [String] {
        let textBeforeCursor = String(input.prefix(cursorPosition))
        let tokens = tokenize(textBeforeCursor)

        // Get the partial word being typed
        let partial = getCurrentPartial(textBeforeCursor)

        // Determine context
        let context = determineContext(tokens)

        // Get suggestions based on context
        var suggestions = getSuggestionsForContext(context)

        // Filter by partial match
        if !partial.isEmpty {
            let partialLower = partial.lowercased()
            suggestions = suggestions.filter {
                $0.lowercased().hasPrefix(partialLower)
            }
        }

        return suggestions.sorted()
    }

    private func tokenize(_ text: String) -> [String] {
        // Simple tokenization - split on whitespace and punctuation
        var tokens: [String] = []
        var current = ""

        for char in text {
            if char.isWhitespace || char == "," || char == "(" || char == ")" {
                if !current.isEmpty {
                    tokens.append(current.uppercased())
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        // Don't add final partial token

        return tokens
    }

    private func getCurrentPartial(_ text: String) -> String {
        var partial = ""
        for char in text.reversed() {
            if char.isWhitespace || char == "," || char == "(" || char == ")" {
                break
            }
            partial = String(char) + partial
        }
        return partial
    }

    private enum Context {
        case start
        case afterSelect
        case afterFrom
        case afterWhere
        case afterGroupBy
        case afterOrderBy
        case afterComparison
        case general
    }

    private func determineContext(_ tokens: [String]) -> Context {
        if tokens.isEmpty { return .start }

        // Look at last few tokens
        let lastToken = tokens.last ?? ""
        let secondLast = tokens.count >= 2 ? tokens[tokens.count - 2] : ""

        if tokens.contains("BY") && secondLast == "GROUP" || lastToken == "BY" && tokens.contains("GROUP") {
            return .afterGroupBy
        }
        if tokens.contains("BY") && secondLast == "ORDER" || lastToken == "BY" && tokens.contains("ORDER") {
            return .afterOrderBy
        }
        if lastToken == "FROM" {
            return .afterFrom
        }
        if lastToken == "SELECT" || (tokens.contains("SELECT") && !tokens.contains("FROM")) {
            return .afterSelect
        }
        if lastToken == "WHERE" || (tokens.contains("WHERE") && !tokens.contains("GROUP") && !tokens.contains("ORDER")) {
            return .afterWhere
        }
        if ["=", ">", "<", ">=", "<=", "!=", "<>"].contains(lastToken) {
            return .afterComparison
        }

        return .general
    }

    private func getSuggestionsForContext(_ context: Context) -> [String] {
        switch context {
        case .start:
            return ["SELECT"]
        case .afterSelect:
            return aggregates + fields
        case .afterFrom:
            return getTypeNames()
        case .afterWhere:
            return fields + dateFunctions
        case .afterGroupBy:
            return timePeriods
        case .afterOrderBy:
            return fields + ["ASC", "DESC"]
        case .afterComparison:
            return dateFunctions + ["NULL"]
        case .general:
            return keywords
        }
    }

    private func getTypeNames() -> [String] {
        QuantityType.allCases.map { $0.displayName }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AutocompleteTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(playground): add Autocomplete provider

- Context-aware suggestions
- Keywords, types, fields, aggregates
- Time periods, date functions"
```

---

## Task 7: SwiftUI REPL View

**Files:**
- Create: `Apps/HealthQLPlayground/HealthQLPlaygroundApp.swift`
- Create: `Apps/HealthQLPlayground/REPLView.swift`
- Create: `Apps/HealthQLPlayground/HealthQLPlayground.entitlements`
- Create: `Apps/HealthQLPlayground/Info.plist`

**Note:** This task creates the macOS app structure. Since it's a SwiftUI app, testing is done manually.

**Step 1: Create directory structure**

Run:
```bash
mkdir -p Apps/HealthQLPlayground
```

**Step 2: Create the SwiftUI App entry point**

Create `Apps/HealthQLPlayground/HealthQLPlaygroundApp.swift`:
```swift
import SwiftUI
import HealthQLPlayground

@main
struct HealthQLPlaygroundApp: App {
    var body: some Scene {
        WindowGroup {
            REPLView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
```

**Step 3: Create the main REPL View**

Create `Apps/HealthQLPlayground/REPLView.swift`:
```swift
import SwiftUI
import HealthQLPlayground

struct REPLView: View {
    @StateObject private var viewModel = REPLViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.outputLines) { line in
                            Text(line.text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(line.isError ? .red : .primary)
                                .textSelection(.enabled)
                                .id(line.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.outputLines.count) { _ in
                    if let lastLine = viewModel.outputLines.last {
                        proxy.scrollTo(lastLine.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            // Input area
            HStack(spacing: 8) {
                Text("HealthQL>")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)

                TextField("Enter query...", text: $viewModel.inputText)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.executeCommand()
                    }
                    .onKeyPress(.upArrow) {
                        viewModel.historyUp()
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        viewModel.historyDown()
                        return .handled
                    }
            }
            .padding()
            .background(Color(nsColor: .textBackgroundColor))
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

@MainActor
class REPLViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var outputLines: [OutputLine] = []

    private let engine = REPLEngine()

    struct OutputLine: Identifiable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    init() {
        // Welcome message
        outputLines.append(OutputLine(
            text: "HealthQL Playground v1.0\nType .help for available commands.\n",
            isError: false
        ))
    }

    func executeCommand() {
        let command = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        // Echo the command
        outputLines.append(OutputLine(text: "HealthQL> \(command)", isError: false))

        // Clear input
        inputText = ""
        engine.resetHistoryNavigation()

        // Execute asynchronously
        Task {
            let result = await engine.execute(command)

            await MainActor.run {
                let isError = result.contains("Error") || result.contains("Unknown")
                outputLines.append(OutputLine(text: result, isError: isError))
            }
        }
    }

    func historyUp() {
        if let previous = engine.historyUp() {
            inputText = previous
        }
    }

    func historyDown() {
        inputText = engine.historyDown() ?? ""
    }
}

#Preview {
    REPLView()
        .frame(width: 800, height: 600)
}
```

**Step 4: Create entitlements for HealthKit access**

Create `Apps/HealthQLPlayground/HealthQLPlayground.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.developer.healthkit</key>
    <true/>
</dict>
</plist>
```

**Step 5: Create Info.plist**

Create `Apps/HealthQLPlayground/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>HealthQL Playground</string>
    <key>CFBundleIdentifier</key>
    <string>com.healthql.playground</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>NSHealthShareUsageDescription</key>
    <string>HealthQL needs access to your health data to run queries.</string>
    <key>NSHealthUpdateUsageDescription</key>
    <string>HealthQL does not write any health data.</string>
</dict>
</plist>
```

**Step 6: Commit**

```bash
git add -A
git commit -m "feat(playground): add SwiftUI REPL app

- Main app entry point
- REPLView with input/output
- History navigation with arrow keys
- HealthKit entitlements"
```

---

## Task 8: Xcode Project for App

**Note:** Since Swift Package Manager doesn't support app targets, we need to create an Xcode project that references the package.

**Step 1: Create Xcode project instructions**

The app needs to be built in Xcode. Create a README with instructions:

Create `Apps/HealthQLPlayground/README.md`:
```markdown
# HealthQL Playground App

A REPL-style macOS app for querying HealthKit data using SQL-like syntax.

## Building

1. Open Xcode and create a new macOS App project
2. Name it "HealthQL Playground"
3. Add the HealthQL package as a local dependency:
   - File > Add Package Dependencies
   - Click "Add Local..."
   - Select the root HealthQL folder
4. Add `HealthQLPlayground` library to the app target
5. Copy the Swift files from this folder to the project
6. Configure entitlements for HealthKit access
7. Build and run

## Usage

- Type SQL queries at the prompt
- Use up/down arrows to navigate history
- Meta commands start with `.`

### Commands

- `.types` - List available health types
- `.schema <type>` - Show fields for a type
- `.history` - Show query history
- `.export csv` - Export last result
- `.clear` - Clear screen
- `.help` - Show help

### Example Queries

```sql
SELECT sum(count) FROM steps WHERE date > today() - 7d GROUP BY day
SELECT avg(value), min(value), max(value) FROM heart_rate WHERE date > start_of_month()
SELECT * FROM active_calories ORDER BY date DESC LIMIT 10
```
```

**Step 2: Commit**

```bash
git add -A
git commit -m "docs(playground): add app build instructions"
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

## Phase 3 Complete

At the end of Phase 3, you have:

- **ResultFormatter** - Formats query results as ASCII tables
- **MetaCommand** - Parses REPL meta commands (.types, .schema, etc.)
- **History** - Manages command history with navigation
- **SchemaInfo** - Provides type introspection and suggestions
- **REPLEngine** - Core engine that processes commands and queries
- **Autocomplete** - Context-aware autocomplete suggestions
- **SwiftUI App** - macOS REPL interface

**Supported commands:**
```
.types          - List all available health types
.schema <type>  - Show fields and info for a type
.history        - Show query history
.export csv     - Export last result to CSV
.export json    - Export last result to JSON
.clear          - Clear the screen
.help           - Show help message
```

**Next:** Phase 4 adds category types (sleep, symptoms), workouts, clinical records, and statistical functions.
