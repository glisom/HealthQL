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
                case .int(let i): return "\(i)"
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
                case .int(let i): obj[key] = i
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
