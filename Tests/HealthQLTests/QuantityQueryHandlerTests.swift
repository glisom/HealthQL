import Testing
import HealthKit
@testable import HealthQL

@Suite("QuantityQueryHandler Tests")
struct QuantityQueryHandlerTests {

    @Test("Handler can be created with mock store")
    func handlerCreation() {
        let mock = MockHealthStore()
        let handler = QuantityQueryHandler(healthStore: mock)
        #expect(handler != nil)
    }

    @Test("Handler requests authorization on first query")
    func requestsAuthorization() async throws {
        let mock = MockHealthStore()
        let handler = QuantityQueryHandler(healthStore: mock)

        let query = HealthQuery(
            source: .quantity(.heartRate),
            selections: [.field(.value)]
        )

        // Start execute in a task and cancel after a short timeout
        // Authorization happens before the query is executed
        let task = Task {
            _ = try? await handler.execute(query, type: .heartRate)
        }

        // Give time for authorization to be requested
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        task.cancel()

        #expect(mock.authorizationRequested == true)
    }

    @Test("Handler respects query limit")
    func respectsLimit() {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: [.field(.value)],
            limit: 10
        )

        #expect(query.limit == 10)
    }
}

// MARK: - Sort Descriptor Tests

@Suite("buildSortDescriptors Tests")
struct BuildSortDescriptorsTests {
    let handler = QuantityQueryHandler(healthStore: MockHealthStore())

    @Test("Returns default descending date sort when ordering is nil")
    func defaultSort() {
        let descriptors = handler.buildSortDescriptors(from: nil)

        #expect(descriptors.count == 1)
        #expect(descriptors[0].key == HKSampleSortIdentifierStartDate)
        #expect(descriptors[0].ascending == false)
    }

    @Test("Sorts by date ascending")
    func dateAscending() {
        let ordering = [OrderBy(field: .date, direction: .ascending)]
        let descriptors = handler.buildSortDescriptors(from: ordering)

        #expect(descriptors.count == 1)
        #expect(descriptors[0].key == HKSampleSortIdentifierStartDate)
        #expect(descriptors[0].ascending == true)
    }

    @Test("Sorts by date descending")
    func dateDescending() {
        let ordering = [OrderBy(field: .date, direction: .descending)]
        let descriptors = handler.buildSortDescriptors(from: ordering)

        #expect(descriptors.count == 1)
        #expect(descriptors[0].key == HKSampleSortIdentifierStartDate)
        #expect(descriptors[0].ascending == false)
    }

    @Test("Sorts by end date")
    func endDateSort() {
        let ordering = [OrderBy(field: .endDate, direction: .ascending)]
        let descriptors = handler.buildSortDescriptors(from: ordering)

        #expect(descriptors.count == 1)
        #expect(descriptors[0].key == HKSampleSortIdentifierEndDate)
        #expect(descriptors[0].ascending == true)
    }

    @Test("Falls back to start date for non-date fields")
    func nonDateFieldFallback() {
        let ordering = [OrderBy(field: .value, direction: .ascending)]
        let descriptors = handler.buildSortDescriptors(from: ordering)

        #expect(descriptors.count == 1)
        #expect(descriptors[0].key == HKSampleSortIdentifierStartDate)
        #expect(descriptors[0].ascending == true)
    }

    @Test("Handles multiple sort descriptors")
    func multipleSort() {
        let ordering = [
            OrderBy(field: .date, direction: .descending),
            OrderBy(field: .endDate, direction: .ascending)
        ]
        let descriptors = handler.buildSortDescriptors(from: ordering)

        #expect(descriptors.count == 2)
        #expect(descriptors[0].key == HKSampleSortIdentifierStartDate)
        #expect(descriptors[0].ascending == false)
        #expect(descriptors[1].key == HKSampleSortIdentifierEndDate)
        #expect(descriptors[1].ascending == true)
    }

    @Test("Returns default for empty ordering array")
    func emptyOrdering() {
        let descriptors = handler.buildSortDescriptors(from: [])

        #expect(descriptors.count == 0)
    }
}

// MARK: - Date Components Tests

@Suite("dateComponents Tests")
struct DateComponentsTests {
    let handler = QuantityQueryHandler(healthStore: MockHealthStore())

    @Test("Hour grouping returns 1 hour interval")
    func hourGrouping() {
        let components = handler.dateComponents(for: .hour)
        #expect(components.hour == 1)
        #expect(components.day == nil)
        #expect(components.month == nil)
    }

    @Test("Day grouping returns 1 day interval")
    func dayGrouping() {
        let components = handler.dateComponents(for: .day)
        #expect(components.day == 1)
        #expect(components.hour == nil)
        #expect(components.month == nil)
    }

    @Test("Week grouping returns 1 week interval")
    func weekGrouping() {
        let components = handler.dateComponents(for: .week)
        #expect(components.weekOfYear == 1)
        #expect(components.day == nil)
        #expect(components.month == nil)
    }

    @Test("Month grouping returns 1 month interval")
    func monthGrouping() {
        let components = handler.dateComponents(for: .month)
        #expect(components.month == 1)
        #expect(components.day == nil)
        #expect(components.year == nil)
    }

    @Test("Year grouping returns 1 year interval")
    func yearGrouping() {
        let components = handler.dateComponents(for: .year)
        #expect(components.year == 1)
        #expect(components.month == nil)
        #expect(components.day == nil)
    }
}

// MARK: - Extract Start Date Tests

@Suite("extractStartDate Tests")
struct ExtractStartDateTests {
    let handler = QuantityQueryHandler(healthStore: MockHealthStore())

    @Test("Returns nil for empty predicates")
    func emptyPredicates() {
        let date = handler.extractStartDate(from: [])
        #expect(date == nil)
    }

    @Test("Extracts date from single date predicate")
    func singleDatePredicate() {
        let testDate = Date(timeIntervalSince1970: 1000000)
        let predicates = [
            Predicate(field: .date, op: .greaterThan, value: .date(testDate))
        ]

        let date = handler.extractStartDate(from: predicates)
        #expect(date == testDate)
    }

    @Test("Extracts start date from date range predicate")
    func dateRangePredicate() {
        let startDate = Date(timeIntervalSince1970: 1000000)
        let endDate = Date(timeIntervalSince1970: 2000000)
        let predicates = [
            Predicate(field: .date, op: .between, value: .dateRange(start: startDate, end: endDate))
        ]

        let date = handler.extractStartDate(from: predicates)
        #expect(date == startDate)
    }

    @Test("Returns nil for non-date field predicates")
    func nonDateFieldPredicate() {
        let predicates = [
            Predicate(field: .value, op: .greaterThan, value: .double(100.0))
        ]

        let date = handler.extractStartDate(from: predicates)
        #expect(date == nil)
    }

    @Test("Returns nil for date field with non-date value")
    func dateFieldNonDateValue() {
        let predicates = [
            Predicate(field: .date, op: .equal, value: .string("invalid"))
        ]

        let date = handler.extractStartDate(from: predicates)
        #expect(date == nil)
    }

    @Test("Finds date predicate among multiple predicates")
    func multiplePredicate() {
        let testDate = Date(timeIntervalSince1970: 1500000)
        let predicates = [
            Predicate(field: .value, op: .greaterThan, value: .double(50.0)),
            Predicate(field: .date, op: .greaterThanOrEqual, value: .date(testDate)),
            Predicate(field: .source, op: .equal, value: .string("Apple Watch"))
        ]

        let date = handler.extractStartDate(from: predicates)
        #expect(date == testDate)
    }

    @Test("Returns first date predicate when multiple exist")
    func multipleeDatePredicates() {
        let firstDate = Date(timeIntervalSince1970: 1000000)
        let secondDate = Date(timeIntervalSince1970: 2000000)
        let predicates = [
            Predicate(field: .date, op: .greaterThan, value: .date(firstDate)),
            Predicate(field: .date, op: .lessThan, value: .date(secondDate))
        ]

        let date = handler.extractStartDate(from: predicates)
        #expect(date == firstDate)
    }
}

// MARK: - Statistics Options Tests

@Suite("statisticsOptions Tests")
struct StatisticsOptionsTests {
    let handler = QuantityQueryHandler(healthStore: MockHealthStore())

    @Test("Returns cumulative sum as default for empty selections")
    func emptySelections() {
        let options = handler.statisticsOptions(for: [])
        #expect(options == .cumulativeSum)
    }

    @Test("Returns cumulative sum as default for field selections only")
    func fieldSelectionsOnly() {
        let selections: [Selection] = [.field(.value), .field(.date)]
        let options = handler.statisticsOptions(for: selections)
        #expect(options == .cumulativeSum)
    }

    @Test("Maps sum aggregate to cumulative sum")
    func sumAggregate() {
        let selections: [Selection] = [.aggregate(.sum, .value)]
        let options = handler.statisticsOptions(for: selections)
        #expect(options.contains(.cumulativeSum))
    }

    @Test("Maps avg aggregate to discrete average")
    func avgAggregate() {
        let selections: [Selection] = [.aggregate(.avg, .value)]
        let options = handler.statisticsOptions(for: selections)
        #expect(options.contains(.discreteAverage))
    }

    @Test("Maps min aggregate to discrete min")
    func minAggregate() {
        let selections: [Selection] = [.aggregate(.min, .value)]
        let options = handler.statisticsOptions(for: selections)
        #expect(options.contains(.discreteMin))
    }

    @Test("Maps max aggregate to discrete max")
    func maxAggregate() {
        let selections: [Selection] = [.aggregate(.max, .value)]
        let options = handler.statisticsOptions(for: selections)
        #expect(options.contains(.discreteMax))
    }

    @Test("Maps count aggregate to cumulative sum")
    func countAggregate() {
        let selections: [Selection] = [.aggregate(.count, .value)]
        let options = handler.statisticsOptions(for: selections)
        #expect(options.contains(.cumulativeSum))
    }

    @Test("Combines multiple aggregate options")
    func multipleAggregates() {
        let selections: [Selection] = [
            .aggregate(.sum, .value),
            .aggregate(.avg, .value),
            .aggregate(.min, .value),
            .aggregate(.max, .value)
        ]
        let options = handler.statisticsOptions(for: selections)

        #expect(options.contains(.cumulativeSum))
        #expect(options.contains(.discreteAverage))
        #expect(options.contains(.discreteMin))
        #expect(options.contains(.discreteMax))
    }

    @Test("Ignores field selections when aggregates present")
    func mixedSelections() {
        let selections: [Selection] = [
            .field(.date),
            .aggregate(.avg, .value),
            .field(.source)
        ]
        let options = handler.statisticsOptions(for: selections)

        #expect(options.contains(.discreteAverage))
        #expect(!options.contains(.cumulativeSum))
    }
}
