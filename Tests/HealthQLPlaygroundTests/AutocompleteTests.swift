import Testing
@testable import HealthQLPlayground

@Suite("Autocomplete Tests")
struct AutocompleteTests {

    @Test("Suggests keywords at start")
    func keywordsAtStart() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SEL", cursorPosition: 3)
        #expect(suggestions.contains("SELECT"))
    }

    @Test("Suggests types after FROM")
    func typesAfterFrom() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM st", cursorPosition: 16)
        #expect(suggestions.contains("steps"))
    }

    @Test("Suggests fields after SELECT")
    func fieldsAfterSelect() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT va", cursorPosition: 9)
        #expect(suggestions.contains("value"))
    }

    @Test("Suggests aggregates after SELECT")
    func aggregatesAfterSelect() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT su", cursorPosition: 9)
        #expect(suggestions.contains("sum("))
    }

    @Test("Suggests clauses after type")
    func clausesAfterType() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM steps WH", cursorPosition: 22)
        #expect(suggestions.contains("WHERE"))
    }

    @Test("Suggests time periods after GROUP BY")
    func timePeriodsAfterGroupBy() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT sum(count) FROM steps GROUP BY d", cursorPosition: 39)
        #expect(suggestions.contains("day"))
    }

    @Test("Suggests date functions")
    func dateFunctions() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM steps WHERE date > to", cursorPosition: 35)
        #expect(suggestions.contains("today()"))
    }
}
