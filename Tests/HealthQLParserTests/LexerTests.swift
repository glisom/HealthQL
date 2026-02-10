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

    // MARK: - String Literal Tests

    @Test("Lexer tokenizes string literals")
    func stringLiterals() throws {
        let lexer = Lexer("WHERE name = 'John Doe'")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .where)
        #expect(tokens[1].type == .identifier)
        #expect(tokens[1].value == "name")
        #expect(tokens[2].type == .equal)
        #expect(tokens[3].type == .string)
        #expect(tokens[3].value == "John Doe")
        #expect(tokens[4].type == .eof)
    }

    @Test("Lexer tokenizes empty string literal")
    func emptyStringLiteral() throws {
        let lexer = Lexer("''")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .string)
        #expect(tokens[0].value == "")
        #expect(tokens[1].type == .eof)
    }

    @Test("Lexer throws error for unterminated string")
    func unterminatedString() throws {
        let lexer = Lexer("'unterminated")

        #expect(throws: LexerError.self) {
            _ = try lexer.tokenize()
        }
    }

    @Test("Lexer reports correct position for unterminated string")
    func unterminatedStringPosition() throws {
        let lexer = Lexer("SELECT 'unterminated")

        do {
            _ = try lexer.tokenize()
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as LexerError {
            if case .unterminatedString(let line, let column) = error {
                #expect(line == 1)
                #expect(column == 8)  // Position of opening quote
            } else {
                #expect(Bool(false), "Wrong error type")
            }
        }
    }

    // MARK: - Comparison Operator Tests

    @Test("Lexer tokenizes greater than operator")
    func greaterThan() throws {
        let lexer = Lexer("value > 100")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .greaterThan)
        #expect(tokens[1].value == ">")
    }

    @Test("Lexer tokenizes less than operator")
    func lessThan() throws {
        let lexer = Lexer("value < 100")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .lessThan)
        #expect(tokens[1].value == "<")
    }

    @Test("Lexer tokenizes greater than or equal operator")
    func greaterThanOrEqual() throws {
        let lexer = Lexer("value >= 100")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .greaterThanOrEqual)
        #expect(tokens[1].value == ">=")
    }

    @Test("Lexer tokenizes less than or equal operator")
    func lessThanOrEqual() throws {
        let lexer = Lexer("value <= 100")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .lessThanOrEqual)
        #expect(tokens[1].value == "<=")
    }

    @Test("Lexer tokenizes not equal operator with !=")
    func notEqualBang() throws {
        let lexer = Lexer("value != 100")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .notEqual)
        #expect(tokens[1].value == "!=")
    }

    @Test("Lexer tokenizes not equal operator with <>")
    func notEqualAngleBrackets() throws {
        let lexer = Lexer("value <> 100")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .notEqual)
        #expect(tokens[1].value == "<>")
    }

    @Test("Lexer tokenizes equal operator")
    func equalOperator() throws {
        let lexer = Lexer("value = 100")
        let tokens = try lexer.tokenize()

        #expect(tokens[1].type == .equal)
        #expect(tokens[1].value == "=")
    }

    // MARK: - Duration Token Tests

    @Test("Lexer tokenizes day duration")
    func dayDuration() throws {
        let lexer = Lexer("7d")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .duration)
        #expect(tokens[0].value == "7d")
    }

    @Test("Lexer tokenizes week duration")
    func weekDuration() throws {
        let lexer = Lexer("2w")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .duration)
        #expect(tokens[0].value == "2w")
    }

    @Test("Lexer tokenizes month duration")
    func monthDuration() throws {
        let lexer = Lexer("3mo")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .duration)
        #expect(tokens[0].value == "3mo")
    }

    @Test("Lexer tokenizes year duration")
    func yearDuration() throws {
        let lexer = Lexer("1y")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .duration)
        #expect(tokens[0].value == "1y")
    }

    @Test("Lexer tokenizes duration in WHERE clause")
    func durationInWhereClause() throws {
        let lexer = Lexer("WHERE date > today - 7d")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .where)
        #expect(tokens[1].type == .identifier)
        #expect(tokens[2].type == .greaterThan)
        #expect(tokens[3].type == .today)
        #expect(tokens[4].type == .minus)
        #expect(tokens[5].type == .duration)
        #expect(tokens[5].value == "7d")
    }

    // MARK: - GROUP BY / ORDER BY Tests

    @Test("Lexer tokenizes GROUP BY as separate tokens")
    func groupByAsSeparateTokens() throws {
        let lexer = Lexer("GROUP BY category")
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 4) // GROUP, BY, category, EOF
        #expect(tokens[0].type == .group)
        #expect(tokens[0].value == "GROUP")
        #expect(tokens[1].type == .by)
        #expect(tokens[1].value == "BY")
        #expect(tokens[2].type == .identifier)
        #expect(tokens[2].value == "category")
        #expect(tokens[3].type == .eof)
    }

    @Test("Lexer tokenizes ORDER BY as separate tokens")
    func orderByAsSeparateTokens() throws {
        let lexer = Lexer("ORDER BY date DESC")
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 5) // ORDER, BY, date, DESC, EOF
        #expect(tokens[0].type == .order)
        #expect(tokens[0].value == "ORDER")
        #expect(tokens[1].type == .by)
        #expect(tokens[1].value == "BY")
        #expect(tokens[2].type == .identifier)
        #expect(tokens[2].value == "date")
        #expect(tokens[3].type == .desc)
        #expect(tokens[4].type == .eof)
    }

    @Test("Lexer tokenizes GROUP BY and ORDER BY in full query")
    func groupByAndOrderByInQuery() throws {
        let lexer = Lexer("SELECT COUNT(*) FROM steps GROUP BY day ORDER BY day ASC")
        let tokens = try lexer.tokenize()

        // SELECT, COUNT, (, *, ), FROM, steps, GROUP, BY, day, ORDER, BY, day, ASC, EOF
        #expect(tokens.count == 15)
        #expect(tokens[7].type == .group)
        #expect(tokens[8].type == .by)
        #expect(tokens[10].type == .order)
        #expect(tokens[11].type == .by)
        #expect(tokens[13].type == .asc)
    }

    @Test("Lexer handles lowercase group by")
    func lowercaseGroupBy() throws {
        let lexer = Lexer("group by name")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .group)
        #expect(tokens[1].type == .by)
        #expect(tokens[2].type == .identifier)
    }

    // MARK: - BETWEEN Keyword Tests

    @Test("Lexer tokenizes BETWEEN keyword")
    func betweenKeyword() throws {
        let lexer = Lexer("date BETWEEN '2026-02-05' AND '2026-02-06'")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .identifier)
        #expect(tokens[0].value == "date")
        #expect(tokens[1].type == .between)
        #expect(tokens[2].type == .string)
        #expect(tokens[2].value == "2026-02-05")
        #expect(tokens[3].type == .and)
        #expect(tokens[4].type == .string)
        #expect(tokens[4].value == "2026-02-06")
    }

    @Test("Lexer tokenizes BETWEEN case insensitively")
    func betweenCaseInsensitive() throws {
        let lexer = Lexer("between")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .between)
    }

    // MARK: - Hour Duration Tests

    @Test("Lexer tokenizes hour duration")
    func hourDuration() throws {
        let lexer = Lexer("2h")
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .duration)
        #expect(tokens[0].value == "2h")
    }

    @Test("Lexer tokenizes hour duration in WHERE clause")
    func hourDurationInWhereClause() throws {
        let lexer = Lexer("WHERE date > today() - 4h")
        let tokens = try lexer.tokenize()

        #expect(tokens[5].type == .duration)
        #expect(tokens[5].value == "4h")
    }

    // MARK: - Error Cases

    @Test("Lexer throws error for unexpected character")
    func unexpectedCharacter() throws {
        let lexer = Lexer("SELECT @invalid")

        #expect(throws: LexerError.self) {
            _ = try lexer.tokenize()
        }
    }

    @Test("Lexer throws error for standalone exclamation")
    func standaloneExclamation() throws {
        let lexer = Lexer("! value")

        #expect(throws: LexerError.self) {
            _ = try lexer.tokenize()
        }
    }
}
