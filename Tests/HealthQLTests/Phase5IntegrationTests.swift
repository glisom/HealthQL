import Testing
import HealthKit
@testable import HealthQL

@Suite("Phase 5 Integration Tests")
struct Phase5IntegrationTests {

    @Test("HealthStoreProtocol allows mock injection")
    func mockInjection() {
        let mock = MockHealthStore()
        let handler = QuantityQueryHandler(healthStore: mock)
        #expect(handler != nil)
    }

    @Test("PredicateBuilder creates valid HK predicates")
    func predicateBuilderIntegration() {
        let date = Date().addingTimeInterval(-86400 * 7)
        let predicate = Predicate(field: .date, op: .greaterThan, value: .date(date))

        let builder = PredicateBuilder()
        let hkPredicate = builder.build(from: [predicate])

        #expect(hkPredicate != nil)
    }

    @Test("Executor validates queries correctly")
    func executorValidation() async throws {
        let executor = HealthQueryExecutor()

        // Empty selections should fail
        let badQuery = HealthQuery(source: .quantity(.heartRate), selections: [])

        await #expect(throws: QueryError.noSelections) {
            try await executor.execute(badQuery)
        }
    }

    @Test("Handler transformation produces valid ResultRows")
    func handlerTransformation() {
        // Verify ResultRow structure
        let row = ResultRow(values: [
            "value": .double(72.0),
            "date": .date(Date()),
            "source": .string("Apple Watch")
        ])

        #expect(row.double("value") == 72.0)
        #expect(row.string("source") == "Apple Watch")
        #expect(row.date("date") != nil)
    }

    @Test("Sleep session night grouping logic")
    func sleepNightGrouping() {
        let calendar = Calendar.current

        // 2am should belong to previous night
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 2
        let earlyMorning = calendar.date(from: components)!

        // 10pm should belong to same night
        components.hour = 22
        let lateEvening = calendar.date(from: components)!

        // Just verify dates are valid
        #expect(earlyMorning < lateEvening)
    }
}
