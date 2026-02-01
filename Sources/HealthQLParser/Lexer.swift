import Foundation

/// Errors that can occur during lexical analysis
public enum LexerError: Error, Equatable {
    case unexpectedCharacter(Character, line: Int, column: Int)
    case unterminatedString(line: Int, column: Int)
}

/// Tokenizes a HealthQL query string
public final class Lexer {
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
        "group": .group,
        "by": .by,
        "having": .having,
        "order": .order,
        "limit": .limit,
        "asc": .asc,
        "desc": .desc,
        "and": .and,
        "or": .or,
        "not": .not,
        "is": .is,
        "null": .null,
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
