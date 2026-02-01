import Testing
@testable import HealthQLPlayground

@Suite("History Tests")
struct HistoryTests {

    @Test("History starts empty")
    func startsEmpty() {
        let history = History()

        #expect(history.entries.isEmpty)
        #expect(history.current == nil)
    }

    @Test("Adding entry updates history")
    func addEntry() {
        var history = History()
        history.add("SELECT * FROM steps")

        #expect(history.entries.count == 1)
        #expect(history.entries[0] == "SELECT * FROM steps")
    }

    @Test("Navigate up returns previous entry")
    func navigateUp() {
        var history = History()
        history.add("query1")
        history.add("query2")

        let result = history.up()

        #expect(result == "query2")
    }

    @Test("Navigate up twice returns older entry")
    func navigateUpTwice() {
        var history = History()
        history.add("query1")
        history.add("query2")

        _ = history.up()
        let result = history.up()

        #expect(result == "query1")
    }

    @Test("Navigate down returns newer entry")
    func navigateDown() {
        var history = History()
        history.add("query1")
        history.add("query2")

        _ = history.up() // query2
        _ = history.up() // query1
        let result = history.down()

        #expect(result == "query2")
    }

    @Test("Navigate down at end returns nil")
    func navigateDownAtEnd() {
        var history = History()
        history.add("query1")

        _ = history.up()
        _ = history.down()
        let result = history.down()

        #expect(result == nil)
    }

    @Test("Reset clears navigation position")
    func reset() {
        var history = History()
        history.add("query1")
        history.add("query2")

        _ = history.up()
        history.reset()
        let result = history.up()

        #expect(result == "query2")
    }

    @Test("Does not add duplicate consecutive entries")
    func noDuplicates() {
        var history = History()
        history.add("query1")
        history.add("query1")

        #expect(history.entries.count == 1)
    }
}
