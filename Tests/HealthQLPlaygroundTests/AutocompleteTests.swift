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

    @Test("Suggests heart_rate type after FROM")
    func heartRateType() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM hea", cursorPosition: 17)
        #expect(suggestions.contains("heart_rate"))
    }

    @Test("Suggests category types after FROM")
    func categoryTypesAfterFrom() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM sleep", cursorPosition: 19)

        #expect(suggestions.contains("sleep_analysis") || suggestions.contains("sleep"))
    }

    @Test("Suggests workouts after FROM")
    func workoutsAfterFrom() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT * FROM work", cursorPosition: 18)

        #expect(suggestions.contains("workouts"))
    }

    @Test("Suggests workout fields")
    func workoutFields() {
        let autocomplete = Autocomplete()
        let suggestions = autocomplete.suggest(for: "SELECT dur", cursorPosition: 10)

        #expect(suggestions.contains("duration"))
    }
}
