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
