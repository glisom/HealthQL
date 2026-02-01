import Foundation
import HealthKit

/// Executes category type queries against HealthKit
public actor CategoryQueryHandler {
    private let healthStore: any HealthStoreProtocol
    private let predicateBuilder: PredicateBuilder
    private var authorizedTypes: Set<HKCategoryType> = []

    public init(healthStore: any HealthStoreProtocol) {
        self.healthStore = healthStore
        self.predicateBuilder = PredicateBuilder()
    }

    /// Execute a category query
    public func execute(_ query: HealthQuery, type: CategoryType) async throws -> [ResultRow] {
        let hkType = type.hkType

        // Request authorization if needed
        if !authorizedTypes.contains(hkType) {
            try await healthStore.requestAuthorization(toShare: nil, read: [hkType])
            authorizedTypes.insert(hkType)
        }

        return try await executeSampleQuery(query, type: type)
    }

    private func executeSampleQuery(_ query: HealthQuery, type: CategoryType) async throws -> [ResultRow] {
        let hkType = type.hkType
        let predicate = predicateBuilder.build(from: query.predicates)
        let limit = query.limit ?? HKObjectQueryNoLimit

        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

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

                let rows = self.transformSamples(samples as? [HKCategorySample] ?? [], type: type, selections: query.selections)
                continuation.resume(returning: rows)
            }

            self.healthStore.execute(sampleQuery)
        }
    }

    nonisolated private func transformSamples(_ samples: [HKCategorySample], type: CategoryType, selections: [Selection]) -> [ResultRow] {
        samples.map { sample in
            var values: [String: ResultValue] = [:]

            for selection in selections {
                if case .field(let field) = selection {
                    switch field {
                    case .value:
                        values["value"] = .int(sample.value)
                    case .stage:
                        if type == .sleepAnalysis, let stage = SleepStage(rawValue: sample.value) {
                            values["stage"] = .string(stage.displayName)
                        }
                    case .severity:
                        if let severity = Severity(rawValue: sample.value) {
                            values["severity"] = .string(severity.displayName)
                        }
                    case .date:
                        values["date"] = .date(sample.startDate)
                    case .endDate:
                        values["end_date"] = .date(sample.endDate)
                    case .duration:
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        values["duration"] = .double(duration)
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
}
