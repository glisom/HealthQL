import Testing
@testable import HealthQLPlayground
@testable import HealthQL

@Suite("REPL Engine Tests")
struct REPLEngineTests {

    @Test("Executes .types command")
    func typesCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".types")

        #expect(result.contains("steps"))
        #expect(result.contains("heart_rate"))
    }

    @Test("Executes .schema command")
    func schemaCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".schema steps")

        #expect(result.contains("value"))
        #expect(result.contains("date"))
    }

    @Test("Executes .help command")
    func helpCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".help")

        #expect(result.contains(".types"))
        #expect(result.contains(".schema"))
    }

    @Test("Returns error for unknown command")
    func unknownCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".invalid")

        #expect(result.contains("Unknown command"))
    }

    @Test("Executes SQL query")
    func sqlQuery() async {
        let engine = REPLEngine()
        let result = await engine.execute("SELECT sum(count) FROM steps")

        // Should either show results or error (no HealthKit access in tests)
        #expect(!result.isEmpty)
    }

    @Test("History is updated after SQL query")
    func historyUpdated() async {
        let engine = REPLEngine()
        _ = await engine.execute("SELECT * FROM steps")

        #expect(engine.history.entries.contains("SELECT * FROM steps"))
    }

    @Test("Meta commands not added to history")
    func metaNotInHistory() async {
        let engine = REPLEngine()
        _ = await engine.execute(".types")

        #expect(!engine.history.entries.contains(".types"))
    }
}
