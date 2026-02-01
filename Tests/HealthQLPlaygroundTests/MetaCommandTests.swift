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

    @Test("Parses .export csv command")
    func exportCsvCommand() {
        let result = MetaCommand.parse(".export csv")

        #expect(result == .export(.csv))
    }

    @Test("Parses .export json command")
    func exportJsonCommand() {
        let result = MetaCommand.parse(".export json")

        #expect(result == .export(.json))
    }

    @Test("Export defaults to CSV when no format specified")
    func exportDefaultsCsv() {
        let result = MetaCommand.parse(".export")

        #expect(result == .export(.csv))
    }
}
