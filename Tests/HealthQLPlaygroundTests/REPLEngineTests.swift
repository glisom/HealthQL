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

        let history = await engine.history
        #expect(history.entries.contains("SELECT * FROM steps"))
    }

    @Test("Meta commands not added to history")
    func metaNotInHistory() async {
        let engine = REPLEngine()
        _ = await engine.execute(".types")

        let history = await engine.history
        #expect(!history.entries.contains(".types"))
    }

    @Test("Executes .clear command")
    func clearCommand() async {
        let engine = REPLEngine()
        let result = await engine.execute(".clear")

        // .clear returns ANSI escape codes to clear screen
        #expect(result.contains("\u{001B}[2J"))
        #expect(result.contains("\u{001B}[H"))
    }

    @Test("Export csv returns message when no results")
    func exportCsvNoResults() async {
        let engine = REPLEngine()
        let result = await engine.execute(".export csv")

        #expect(result.contains("No results to export"))
    }

    @Test("Export json returns message when no results")
    func exportJsonNoResults() async {
        let engine = REPLEngine()
        let result = await engine.execute(".export json")

        #expect(result.contains("No results to export"))
    }

    @Test("History navigation up")
    func historyNavigationUp() async {
        let engine = REPLEngine()

        // Add some queries to history
        _ = await engine.execute("SELECT * FROM steps")
        _ = await engine.execute("SELECT * FROM heart_rate")

        // Navigate up should return most recent
        let recent = await engine.historyUp()
        #expect(recent == "SELECT * FROM heart_rate")

        // Navigate up again should return older entry
        let older = await engine.historyUp()
        #expect(older == "SELECT * FROM steps")
    }

    @Test("History navigation down")
    func historyNavigationDown() async {
        let engine = REPLEngine()

        // Add some queries to history
        _ = await engine.execute("SELECT * FROM steps")
        _ = await engine.execute("SELECT * FROM heart_rate")

        // Navigate up twice
        _ = await engine.historyUp()
        _ = await engine.historyUp()

        // Navigate down should return newer entry
        let newer = await engine.historyDown()
        #expect(newer == "SELECT * FROM heart_rate")

        // Navigate down past end should return nil
        let pastEnd = await engine.historyDown()
        #expect(pastEnd == nil)
    }

    @Test("Reset history navigation")
    func resetHistoryNavigation() async {
        let engine = REPLEngine()

        // Add queries and navigate
        _ = await engine.execute("SELECT * FROM steps")
        _ = await engine.execute("SELECT * FROM heart_rate")
        _ = await engine.historyUp()

        // Reset navigation
        await engine.resetHistoryNavigation()

        // After reset, up should start from end again
        let result = await engine.historyUp()
        #expect(result == "SELECT * FROM heart_rate")
    }

    @Test("Empty input returns empty string")
    func emptyInput() async {
        let engine = REPLEngine()

        let result1 = await engine.execute("")
        #expect(result1 == "")

        let result2 = await engine.execute("   ")
        #expect(result2 == "")

        let result3 = await engine.execute("\n\t")
        #expect(result3 == "")
    }
}
