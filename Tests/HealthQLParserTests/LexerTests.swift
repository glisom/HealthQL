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
