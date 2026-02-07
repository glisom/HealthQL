import ExpoModulesCore
import HealthKit

public class HealthQLModule: Module {
    private let bridge = HealthQLBridge()

    public func definition() -> ModuleDefinition {
        Name("HealthQL")

        // Execute a SQL-like query against HealthKit
        AsyncFunction("query") { (sql: String, options: [String: Any]) async throws -> Any in
            let format = options["format"] as? String ?? "rows"
            return try await self.bridge.query(sql: sql, format: format)
        }

        // Request authorization to read health data types
        AsyncFunction("requestAuthorization") { (types: [String]) async throws in
            try await self.bridge.requestAuthorization(types: types)
        }

        // Get authorization status for a specific health type
        AsyncFunction("getAuthorizationStatus") { (type: String) async throws -> String in
            return try await self.bridge.getAuthorizationStatus(type: type)
        }
    }
}
