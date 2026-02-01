import Testing
@testable import HealthQLParser

@Suite("Token Tests")
struct TokenTests {

    @Test("TokenType has all required cases")
    func tokenTypes() {
        // Keywords
        #expect(TokenType.select != TokenType.from)
        #expect(TokenType.where != TokenType.group)
        #expect(TokenType.group != TokenType.by)

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
