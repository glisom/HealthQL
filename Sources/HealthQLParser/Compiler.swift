import Foundation
import HealthQL

// Type aliases to disambiguate from Foundation/local AST types with same names
private typealias IRPredicate = HealthQL.Predicate
private typealias IROperator = HealthQL.Operator
private typealias IROrderDirection = HealthQL.OrderDirection

/// Errors that can occur during compilation
public enum CompilerError: Error, Equatable {
    case unknownTable(String)
    case unknownField(String)
    case invalidExpression(String)
    case unsupportedFeature(String)
}

/// Compiles AST SelectStatement to HealthQuery IR
public final class Compiler: Sendable {

    public init() {}

    /// Compile a SelectStatement to HealthQuery IR
    public func compile(_ stmt: SelectStatement) throws -> HealthQuery {
        let source = try resolveSource(stmt.from)
        let selections = try stmt.selections.map { try compileSelection($0) }
        let predicates = try compileWhere(stmt.whereClause)
        let grouping = try compileGroupBy(stmt.groupBy)
        let ordering = try compileOrderBy(stmt.orderBy)

        return HealthQuery(
            source: source,
            selections: selections,
            predicates: predicates,
            grouping: grouping,
            having: nil,
            ordering: ordering,
            limit: stmt.limit
        )
    }

    // MARK: - Source Resolution

    private func resolveSource(_ tableName: String) throws -> HealthSource {
        // Special case: "workouts" table
        if tableName == WorkoutType.tableName {
            return .workout
        }

        // Special case: "sleep" for aggregated sleep sessions
        if tableName == "sleep" {
            return .sleepSession
        }

        // Try to find matching QuantityType by display name
        if let quantityType = QuantityType.from(displayName: tableName) {
            return .quantity(quantityType)
        }

        // Try to find matching CategoryType by display name
        if let categoryType = CategoryType.from(displayName: tableName) {
            return .category(categoryType)
        }

        // Try camelCase conversion for QuantityType
        let camelCase = tableName
            .split(separator: "_")
            .enumerated()
            .map { $0.offset == 0 ? String($0.element) : String($0.element).capitalized }
            .joined()

        if let quantityType = QuantityType(rawValue: camelCase) {
            return .quantity(quantityType)
        }

        throw CompilerError.unknownTable(tableName)
    }

    // MARK: - Selection Compilation

    private func compileSelection(_ expr: Expression) throws -> Selection {
        switch expr {
        case .star:
            return .field(.value)

        case .identifier(let name):
            let field = try resolveField(name)
            return .field(field)

        case .aggregate(let fn, let inner):
            let aggregate = compileAggregate(fn)
            let field = try resolveFieldFromExpression(inner)
            return .aggregate(aggregate, field)

        default:
            throw CompilerError.invalidExpression("Cannot use complex expression in SELECT")
        }
    }

    private func compileAggregate(_ fn: AggregateFunction) -> Aggregate {
        switch fn {
        case .sum: return .sum
        case .avg: return .avg
        case .min: return .min
        case .max: return .max
        case .count: return .count
        }
    }

    private func resolveField(_ name: String) throws -> Field {
        switch name.lowercased() {
        case "value", "count": return .value
        case "date", "start_date": return .date
        case "end_date": return .endDate
        case "source": return .source
        case "device": return .device
        // Category fields
        case "stage": return .stage
        case "severity": return .severity
        // Workout fields
        case "activity_type": return .activityType
        case "duration": return .duration
        case "total_calories": return .totalCalories
        case "distance": return .distance
        // Sleep session fields
        case "in_bed_duration": return .inBedDuration
        case "rem": return .remDuration
        case "core": return .coreDuration
        case "deep": return .deepDuration
        case "awake": return .awakeDuration
        default:
            throw CompilerError.unknownField(name)
        }
    }

    private func resolveFieldFromExpression(_ expr: Expression) throws -> Field {
        switch expr {
        case .identifier(let name):
            return try resolveField(name)
        case .star:
            return .value
        default:
            throw CompilerError.invalidExpression("Expected field name in aggregate")
        }
    }

    // MARK: - WHERE Compilation

    private func compileWhere(_ expr: Expression?) throws -> [IRPredicate] {
        guard let expr = expr else { return [] }

        // Handle AND at top level
        if case .binary(let left, .and, let right) = expr {
            let leftPredicates = try compileWhere(left)
            let rightPredicates = try compileWhere(right)
            return leftPredicates + rightPredicates
        }

        // Single comparison
        if case .binary(let left, let op, let right) = expr {
            let field = try resolveFieldFromExpression(left)
            let irOp = try compileOperator(op)
            let value = try compileValue(right)
            return [IRPredicate(field: field, op: irOp, value: value)]
        }

        // IS NULL / IS NOT NULL
        if case .isNull(let inner, let negated) = expr {
            let field = try resolveFieldFromExpression(inner)
            let op: IROperator = negated ? .isNotNull : .isNull
            return [IRPredicate(field: field, op: op, value: .null)]
        }

        // BETWEEN low AND high
        if case .between(let fieldExpr, let low, let high) = expr {
            let field = try resolveFieldFromExpression(fieldExpr)
            let lowValue = try compileValue(low)
            let highValue = try compileValue(high)

            // Extract dates for date range
            if case .date(let startDate) = lowValue, case .date(let endDate) = highValue {
                return [IRPredicate(field: field, op: .between, value: .dateRange(start: startDate, end: endDate))]
            }

            // For non-date BETWEEN, expand to >= AND <=
            return [
                IRPredicate(field: field, op: .greaterThanOrEqual, value: lowValue),
                IRPredicate(field: field, op: .lessThanOrEqual, value: highValue)
            ]
        }

        throw CompilerError.invalidExpression("Unsupported WHERE expression")
    }

    private func compileOperator(_ op: BinaryOperator) throws -> IROperator {
        switch op {
        case .equal: return .equal
        case .notEqual: return .notEqual
        case .greaterThan: return .greaterThan
        case .greaterThanOrEqual: return .greaterThanOrEqual
        case .lessThan: return .lessThan
        case .lessThanOrEqual: return .lessThanOrEqual
        default:
            throw CompilerError.unsupportedFeature("Operator \(op) not supported in WHERE")
        }
    }

    private func compileValue(_ expr: Expression) throws -> PredicateValue {
        switch expr {
        case .number(let n):
            return .double(n)

        case .string(let s):
            // Try to parse as date/datetime string
            if let date = parseDateTime(s) {
                return .date(date)
            }
            return .string(s)

        case .function(let fn, _):
            let date = resolveDateFunction(fn)
            return .date(date)

        case .binary(let left, .minus, let right):
            // Handle date arithmetic: today() - 7d
            if case .function(let fn, _) = left,
               case .duration(let num, let unit) = right {
                let baseDate = resolveDateFunction(fn)
                let resultDate = subtractDuration(from: baseDate, amount: num, unit: unit)
                return .date(resultDate)
            }
            throw CompilerError.invalidExpression("Unsupported arithmetic in value")

        case .duration(let num, let unit):
            // Duration alone - calculate from today
            let resultDate = subtractDuration(from: Date(), amount: num, unit: unit)
            return .date(resultDate)

        default:
            throw CompilerError.invalidExpression("Cannot use expression as predicate value")
        }
    }

    private func resolveDateFunction(_ fn: DateFunction) -> Date {
        let calendar = Calendar.current
        let now = Date()

        switch fn {
        case .today:
            return calendar.startOfDay(for: now)
        case .startOfWeek:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return calendar.date(from: components) ?? now
        case .startOfMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components) ?? now
        case .startOfYear:
            let components = calendar.dateComponents([.year], from: now)
            return calendar.date(from: components) ?? now
        }
    }

    private func subtractDuration(from date: Date, amount: Int, unit: DurationUnit) -> Date {
        let calendar = Calendar.current

        switch unit {
        case .hours:
            return calendar.date(byAdding: .hour, value: -amount, to: date) ?? date
        case .days:
            return calendar.date(byAdding: .day, value: -amount, to: date) ?? date
        case .weeks:
            return calendar.date(byAdding: .weekOfYear, value: -amount, to: date) ?? date
        case .months:
            return calendar.date(byAdding: .month, value: -amount, to: date) ?? date
        case .years:
            return calendar.date(byAdding: .year, value: -amount, to: date) ?? date
        }
    }

    /// Parse a date or datetime string literal
    /// Supported formats: 'YYYY-MM-DD', 'YYYY-MM-DD HH:mm', 'YYYY-MM-DD HH:mm:ss'
    private func parseDateTime(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone

        // Try datetime with seconds: 'YYYY-MM-DD HH:mm:ss'
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: string) {
            return date
        }

        // Try datetime: 'YYYY-MM-DD HH:mm'
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let date = formatter.date(from: string) {
            return date
        }

        // Try date only: 'YYYY-MM-DD'
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: string) {
            return date
        }

        return nil
    }

    // MARK: - GROUP BY Compilation

    private func compileGroupBy(_ groupBy: GroupByClause?) throws -> GroupBy? {
        guard let groupBy = groupBy else { return nil }

        switch groupBy {
        case .timePeriod(let period):
            switch period {
            case .hour: return .hour
            case .day: return .day
            case .week: return .week
            case .month: return .month
            case .year: return .year
            }
        case .expression:
            throw CompilerError.unsupportedFeature("GROUP BY expression not yet supported")
        }
    }

    // MARK: - ORDER BY Compilation

    private func compileOrderBy(_ orderBy: [OrderByItem]?) throws -> [OrderBy]? {
        guard let orderBy = orderBy else { return nil }

        return try orderBy.map { item in
            let field = try resolveFieldFromExpression(item.expression)
            let direction: IROrderDirection = item.direction == .asc ? .ascending : .descending
            return OrderBy(field: field, direction: direction)
        }
    }
}
