import Foundation
import HealthQL

/// Provides context-aware autocomplete suggestions for HealthQL queries
public struct Autocomplete: Sendable {

    /// The context determined from analyzing the query
    public enum Context: Sendable {
        case start
        case afterSelect
        case afterFrom
        case afterWhere
        case afterGroupBy
        case afterOrderBy
        case afterComparison
        case general
    }

    // MARK: - Static Suggestion Lists

    private static let keywords = ["SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "LIMIT", "ASC", "DESC", "AND", "OR", "NOT"]

    private static let aggregates = ["sum(", "avg(", "min(", "max(", "count("]

    private static let fields = ["value", "date", "end_date", "source", "device", "count"]

    private static let timePeriods = ["hour", "day", "week", "month", "year"]

    private static let dateFunctions = ["today()", "yesterday()", "start_of_week()", "start_of_month()", "start_of_year()"]

    private static let clauses = ["WHERE", "GROUP BY", "ORDER BY", "LIMIT"]

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Generate suggestions for the given query at the specified cursor position
    /// - Parameters:
    ///   - query: The current query text
    ///   - cursorPosition: The cursor position in the query
    /// - Returns: Array of suggestion strings
    public func suggest(for query: String, cursorPosition: Int) -> [String] {
        let textBeforeCursor = String(query.prefix(cursorPosition))
        let context = determineContext(from: textBeforeCursor)
        let partialWord = extractPartialWord(from: textBeforeCursor)

        let suggestions = getSuggestions(for: context)

        return filterSuggestions(suggestions, by: partialWord)
    }

    // MARK: - Private Methods

    /// Determine the query context from the text before cursor
    private func determineContext(from text: String) -> Context {
        let uppercased = text.uppercased()
        let tokens = tokenize(text)

        // Check contexts in order of specificity
        if let lastToken = tokens.last {
            let lastUppercased = lastToken.uppercased()

            // Check for comparison operators (=, >, <, >=, <=, !=)
            if lastUppercased.hasSuffix("=") ||
               lastUppercased.hasSuffix(">") ||
               lastUppercased.hasSuffix("<") ||
               text.trimmingCharacters(in: .whitespaces).hasSuffix("=") ||
               text.trimmingCharacters(in: .whitespaces).hasSuffix(">") ||
               text.trimmingCharacters(in: .whitespaces).hasSuffix("<") {
                return .afterComparison
            }
        }

        // Check for GROUP BY followed by partial input
        if uppercased.contains("GROUP BY") {
            let afterGroupBy = uppercased.components(separatedBy: "GROUP BY").last ?? ""
            // If we're still in the GROUP BY clause (no ORDER BY or LIMIT yet)
            if !afterGroupBy.contains("ORDER BY") && !afterGroupBy.contains("LIMIT") {
                return .afterGroupBy
            }
        }

        // Check for ORDER BY
        if uppercased.contains("ORDER BY") {
            let afterOrderBy = uppercased.components(separatedBy: "ORDER BY").last ?? ""
            if !afterOrderBy.contains("LIMIT") {
                return .afterOrderBy
            }
        }

        // Check for WHERE clause
        if uppercased.contains("WHERE") {
            let afterWhere = uppercased.components(separatedBy: "WHERE").last ?? ""
            // If we're still in the WHERE clause (no GROUP BY or ORDER BY yet)
            if !afterWhere.contains("GROUP BY") && !afterWhere.contains("ORDER BY") && !afterWhere.contains("LIMIT") {
                return .afterWhere
            }
        }

        // Check for FROM (type context)
        if uppercased.contains("FROM") {
            let afterFrom = uppercased.components(separatedBy: "FROM").last ?? ""
            let trimmed = afterFrom.trimmingCharacters(in: .whitespaces)

            // Check if we have a type name followed by a space and more text
            // This means user has completed the type name and is typing next clause
            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 2 {
                // We have a complete type name and are typing something else
                return .general
            }

            // Check if we have a valid type name followed by more clauses
            let hasNextClause = trimmed.contains("WHERE") || trimmed.contains("GROUP BY") || trimmed.contains("ORDER BY") || trimmed.contains("LIMIT")
            if !hasNextClause {
                return .afterFrom
            }
            // We have a complete FROM clause, suggest next clauses
            return .general
        }

        // Check for SELECT
        if uppercased.contains("SELECT") {
            let afterSelect = uppercased.components(separatedBy: "SELECT").last ?? ""
            // If we're still in the SELECT clause (no FROM yet)
            if !afterSelect.contains("FROM") {
                return .afterSelect
            }
        }

        // At the start or general context
        if tokens.isEmpty || text.trimmingCharacters(in: .whitespaces).isEmpty {
            return .start
        }

        // Check if we're at the very beginning typing the first keyword
        let trimmedText = text.trimmingCharacters(in: .whitespaces).uppercased()
        if !trimmedText.contains(" ") {
            return .start
        }

        return .general
    }

    /// Get suggestions for a given context
    private func getSuggestions(for context: Context) -> [String] {
        switch context {
        case .start:
            return ["SELECT"]
        case .afterSelect:
            return Self.aggregates + Self.fields + ["*"]
        case .afterFrom:
            return getTypeNames()
        case .afterWhere:
            return Self.fields + Self.dateFunctions
        case .afterGroupBy:
            return Self.timePeriods
        case .afterOrderBy:
            return Self.fields + ["ASC", "DESC"]
        case .afterComparison:
            return Self.dateFunctions + ["NULL"]
        case .general:
            return Self.clauses + Self.keywords
        }
    }

    /// Get all available type names from QuantityType
    private func getTypeNames() -> [String] {
        QuantityType.allCases.map { $0.rawValue }
    }

    /// Tokenize the input text for analysis
    private func tokenize(_ text: String) -> [String] {
        // Split by whitespace and common delimiters
        let pattern = "[\\s,()=<>!]+"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..., in: text)

        var tokens: [String] = []
        var lastEnd = text.startIndex

        if let regex = regex {
            let matches = regex.matches(in: text, options: [], range: range)
            for match in matches {
                if let matchRange = Range(match.range, in: text) {
                    let token = String(text[lastEnd..<matchRange.lowerBound])
                    if !token.isEmpty {
                        tokens.append(token)
                    }
                    lastEnd = matchRange.upperBound
                }
            }
        }

        // Add the remaining text
        let remaining = String(text[lastEnd...])
        if !remaining.isEmpty {
            tokens.append(remaining)
        }

        return tokens
    }

    /// Extract the partial word being typed at the cursor
    private func extractPartialWord(from text: String) -> String {
        // Find the last word boundary
        let delimiters = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "(),=<>!"))

        var lastIndex = text.endIndex
        for i in text.indices.reversed() {
            if delimiters.contains(text.unicodeScalars[i]) {
                break
            }
            lastIndex = i
        }

        return String(text[lastIndex...])
    }

    /// Filter suggestions by partial word match
    private func filterSuggestions(_ suggestions: [String], by partial: String) -> [String] {
        guard !partial.isEmpty else {
            return suggestions
        }

        let lowercasedPartial = partial.lowercased()

        return suggestions.filter { suggestion in
            suggestion.lowercased().hasPrefix(lowercasedPartial)
        }
    }
}
