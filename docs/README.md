# HealthQL

HealthQL is a SQL-like query language for Apple HealthKit. Query your health data using familiar SQL syntax or a type-safe Swift DSL.

## Why HealthQL?

Working with HealthKit can be complex:
- Callback-based APIs that need wrapping in async/await
- Complex predicate building for queries
- Type-specific query objects (HKSampleQuery, HKStatisticsQuery, etc.)
- Manual result transformation

HealthQL simplifies this with a familiar interface:

```sql
SELECT avg(value), min(value), max(value)
FROM heart_rate
WHERE date > today() - 7d
GROUP BY day
```

## Features

| Feature | Description |
|---------|-------------|
| **SQL Syntax** | SELECT, FROM, WHERE, GROUP BY, ORDER BY, LIMIT |
| **Swift DSL** | Type-safe fluent API for query building |
| **18 Quantity Types** | Heart rate, steps, calories, weight, and more |
| **5 Category Types** | Sleep, headache, fatigue, appetite, menstrual |
| **Workouts** | Exercise sessions with duration, calories, type |
| **Sleep Sessions** | Aggregated nightly sleep with stage breakdown |
| **Date Functions** | today(), start_of_week/month/year(), date literals |
| **BETWEEN Operator** | `WHERE date BETWEEN '...' AND '...'` |
| **Aggregations** | SUM, AVG, MIN, MAX, COUNT |

## Quick Start

<!-- tabs:start -->

#### **SQL**

```swift
import HealthQL
import HealthQLParser

let result = try await HQL.query("""
    SELECT sum(value) FROM steps
    WHERE date > today() - 7d
    GROUP BY day
""")

for row in result.rows {
    print("\(row["date"]!): \(row["sum_value"]!) steps")
}
```

#### **Swift DSL**

```swift
import HealthQL

let result = try await Health.select(.steps, aggregate: .sum)
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .groupBy(.day)
    .execute()

for row in result.rows {
    print("\(row["date"]!): \(row["sum_value"]!) steps")
}
```

<!-- tabs:end -->

## Requirements

- iOS 15.0+ / macOS 13.0+
- Swift 6.0+
- Xcode 15.0+
- HealthKit entitlement

## Next Steps

- [Installation](installation.md) - Add HealthQL to your project
- [Quick Start](quickstart.md) - Write your first query
- [SQL Syntax](sql-syntax.md) - Full SQL reference
- [Examples](examples.md) - Common query patterns
