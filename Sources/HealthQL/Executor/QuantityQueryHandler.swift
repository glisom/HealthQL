import Foundation
import HealthKit

/// Executes quantity type queries against HealthKit
public actor QuantityQueryHandler {
    private let healthStore: any HealthStoreProtocol
    private let predicateBuilder: PredicateBuilder
    private var authorizedTypes: Set<HKQuantityType> = []

    public init(healthStore: any HealthStoreProtocol) {
        self.healthStore = healthStore
        self.predicateBuilder = PredicateBuilder()
    }

    /// Execute a quantity query
    public func execute(_ query: HealthQuery, type: QuantityType) async throws -> [ResultRow] {
        let hkType = type.hkType

        // Request authorization if needed
        if !authorizedTypes.contains(hkType) {
            try await healthStore.requestAuthorization(toShare: nil, read: [hkType])
            authorizedTypes.insert(hkType)
        }

        // Check for aggregation
        if query.grouping != nil {
            return try await executeStatisticsQuery(query, type: type)
        } else {
            return try await executeSampleQuery(query, type: type)
        }
    }

    /// Execute a simple sample query
    private func executeSampleQuery(_ query: HealthQuery, type: QuantityType) async throws -> [ResultRow] {
        let hkType = type.hkType
        let predicate = predicateBuilder.build(from: query.predicates)
        let limit = query.limit ?? HKObjectQueryNoLimit

        let sortDescriptors = buildSortDescriptors(from: query.ordering)

        return try await withCheckedThrowingContinuation { continuation in
            let sampleQuery = HKSampleQuery(
                sampleType: hkType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let rows = self.transformSamples(samples as? [HKQuantitySample] ?? [], type: type, selections: query.selections)
                continuation.resume(returning: rows)
            }

            self.healthStore.execute(sampleQuery)
        }
    }

    /// Execute an aggregation query with statistics
    private func executeStatisticsQuery(_ query: HealthQuery, type: QuantityType) async throws -> [ResultRow] {
        let hkType = type.hkType
        let predicate = predicateBuilder.build(from: query.predicates)

        guard let grouping = query.grouping else {
            return []
        }

        let interval = dateComponents(for: grouping)
        let anchorDate = Calendar.current.startOfDay(for: Date())

        // Extract start date from predicates, default to 30 days ago
        let startDate = extractStartDate(from: query.predicates) ?? Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let options = statisticsOptions(for: query.selections)

        return try await withCheckedThrowingContinuation { continuation in
            let statsQuery = HKStatisticsCollectionQuery(
                quantityType: hkType,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            statsQuery.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let rows = self.transformStatistics(results, type: type, selections: query.selections, startDate: startDate)
                continuation.resume(returning: rows)
            }

            self.healthStore.execute(statsQuery)
        }
    }

    private func buildSortDescriptors(from ordering: [OrderBy]?) -> [NSSortDescriptor] {
        guard let ordering = ordering else {
            return [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        }

        return ordering.map { order in
            let key: String
            switch order.field {
            case .date: key = HKSampleSortIdentifierStartDate
            case .endDate: key = HKSampleSortIdentifierEndDate
            default: key = HKSampleSortIdentifierStartDate
            }
            return NSSortDescriptor(key: key, ascending: order.direction == .ascending)
        }
    }

    private func dateComponents(for grouping: GroupBy) -> DateComponents {
        switch grouping {
        case .hour: return DateComponents(hour: 1)
        case .day: return DateComponents(day: 1)
        case .week: return DateComponents(weekOfYear: 1)
        case .month: return DateComponents(month: 1)
        case .year: return DateComponents(year: 1)
        }
    }

    private func extractStartDate(from predicates: [Predicate]) -> Date? {
        for predicate in predicates {
            if predicate.field == .date {
                switch predicate.value {
                case .date(let date):
                    return date
                case .dateRange(let start, _):
                    return start
                default:
                    continue
                }
            }
        }
        return nil
    }

    private func statisticsOptions(for selections: [Selection]) -> HKStatisticsOptions {
        var options: HKStatisticsOptions = []

        for selection in selections {
            if case .aggregate(let agg, _) = selection {
                switch agg {
                case .sum: options.insert(.cumulativeSum)
                case .avg: options.insert(.discreteAverage)
                case .min: options.insert(.discreteMin)
                case .max: options.insert(.discreteMax)
                case .count: options.insert(.cumulativeSum)
                }
            }
        }

        return options.isEmpty ? .cumulativeSum : options
    }

    private nonisolated func transformSamples(_ samples: [HKQuantitySample], type: QuantityType, selections: [Selection]) -> [ResultRow] {
        samples.map { sample in
            var values: [String: ResultValue] = [:]
            let unit = type.defaultUnit

            for selection in selections {
                if case .field(let field) = selection {
                    switch field {
                    case .value:
                        values["value"] = .double(sample.quantity.doubleValue(for: unit))
                    case .date:
                        values["date"] = .date(sample.startDate)
                    case .endDate:
                        values["end_date"] = .date(sample.endDate)
                    case .source:
                        values["source"] = .string(sample.sourceRevision.source.name)
                    case .device:
                        if let device = sample.device {
                            values["device"] = .string(device.name ?? "Unknown")
                        } else {
                            values["device"] = .null
                        }
                    default:
                        break
                    }
                }
            }

            return ResultRow(values: values)
        }
    }

    private nonisolated func transformStatistics(_ collection: HKStatisticsCollection?, type: QuantityType, selections: [Selection], startDate: Date) -> [ResultRow] {
        guard let collection = collection else { return [] }

        var rows: [ResultRow] = []
        let unit = type.defaultUnit

        collection.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
            var values: [String: ResultValue] = [:]
            values["date"] = .date(statistics.startDate)

            for selection in selections {
                if case .aggregate(let agg, _) = selection {
                    let quantity: HKQuantity?
                    switch agg {
                    case .sum: quantity = statistics.sumQuantity()
                    case .avg: quantity = statistics.averageQuantity()
                    case .min: quantity = statistics.minimumQuantity()
                    case .max: quantity = statistics.maximumQuantity()
                    case .count: quantity = statistics.sumQuantity()
                    }

                    if let q = quantity {
                        let key = "\(agg)_value"
                        values[key] = .double(q.doubleValue(for: unit))
                    }
                }
            }

            if !values.isEmpty {
                rows.append(ResultRow(values: values))
            }
        }

        return rows
    }
}
