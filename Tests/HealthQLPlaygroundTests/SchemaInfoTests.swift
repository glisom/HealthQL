import Testing
@testable import HealthQLPlayground
@testable import HealthQL

@Suite("Schema Info Tests")
struct SchemaInfoTests {

    @Test("Lists all available types")
    func allTypes() {
        let info = SchemaInfo()
        let types = info.allTypes()

        #expect(types.contains("steps"))
        #expect(types.contains("heart_rate"))
        #expect(types.contains("active_calories"))
    }

    @Test("Returns schema for valid type")
    func schemaForType() {
        let info = SchemaInfo()
        let schema = info.schema(for: "steps")

        #expect(schema != nil)
        #expect(schema!.fields.contains("value"))
        #expect(schema!.fields.contains("date"))
    }

    @Test("Returns nil for invalid type")
    func schemaForInvalidType() {
        let info = SchemaInfo()
        let schema = info.schema(for: "invalid_type")

        #expect(schema == nil)
    }

    @Test("Suggests similar type names")
    func suggestsSimilar() {
        let info = SchemaInfo()
        let suggestions = info.suggest(for: "stepz")

        #expect(suggestions.contains("steps"))
    }

    @Test("Returns type display info")
    func typeDisplayInfo() {
        let info = SchemaInfo()
        let schema = info.schema(for: "heart_rate")

        #expect(schema?.unit == "count/min")
    }
}
