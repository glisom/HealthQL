import Testing
@testable import HealthQLParser

@Suite("Parser Tests")
struct ParserTests {

    @Test("Parser parses SELECT * FROM table")
    func selectStarFrom() throws {
        let parser = try Parser("SELECT * FROM steps")
        let stmt = try parser.parse()

        #expect(stmt.from == "steps")
        #expect(stmt.selections.count == 1)
        #expect(stmt.selections[0] == .star)
    }

    @Test("Parser parses SELECT column FROM table")
    func selectColumnFrom() throws {
        let parser = try Parser("SELECT value FROM heart_rate")
        let stmt = try parser.parse()

        #expect(stmt.from == "heart_rate")
        #expect(stmt.selections[0] == .identifier("value"))
    }

    @Test("Parser parses SELECT with aggregate")
    func selectAggregate() throws {
        let parser = try Parser("SELECT sum(count) FROM steps")
        let stmt = try parser.parse()

        #expect(stmt.selections[0] == .aggregate(.sum, .identifier("count")))
    }

    @Test("Parser parses multiple selections")
    func multipleSelections() throws {
        let parser = try Parser("SELECT avg(value), min(value), max(value) FROM heart_rate")
        let stmt = try parser.parse()

        #expect(stmt.selections.count == 3)
    }
}
