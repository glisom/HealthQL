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
        case .int(let i):
            return formatNumber(i)
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
        var line = "|"
        for col in columns {
            let width = widths[col] ?? col.count
            line += " " + col.padding(toLength: width, withPad: " ", startingAt: 0) + " |"
        }
        return line + "\n"
    }

    private func formatTableSeparator(columns: [String], widths: [String: Int]) -> String {
        var line = "+"
        for (i, col) in columns.enumerated() {
            let width = widths[col] ?? col.count
            line += String(repeating: "-", count: width + 2)
            line += i < columns.count - 1 ? "+" : "+"
        }
        return line + "\n"
    }

    private func formatTableRow(row: ResultRow, columns: [String], widths: [String: Int]) -> String {
        var line = "|"
        for col in columns {
            let width = widths[col] ?? col.count
            let value = row.values[col].map { formatValue($0) } ?? ""
            line += " " + value.padding(toLength: width, withPad: " ", startingAt: 0) + " |"
        }
        return line + "\n"
    }

    private func formatTableFooter(columns: [String], widths: [String: Int]) -> String {
        var line = "+"
        for (i, col) in columns.enumerated() {
            let width = widths[col] ?? col.count
            line += String(repeating: "-", count: width + 2)
            line += i < columns.count - 1 ? "+" : "+"
        }
        return line
    }
}
