# Quick Start

This guide will have you querying health data in 5 minutes.

## Your First Query

### Using SQL Strings

```swift
import HealthQL
import HealthQLParser

func getHeartRate() async throws {
    let result = try await HQL.query("""
        SELECT avg(value), min(value), max(value)
        FROM heart_rate
        WHERE date > today() - 7d
        GROUP BY day
    """)

    print("Found \(result.rows.count) days of data")

    for row in result.rows {
        if let date = row.date("date"),
           let avg = row.double("avg_value") {
            print("\(date): \(avg) bpm average")
        }
    }
}
```

### Using Swift DSL

```swift
import HealthQL

func getSteps() async throws {
    let result = try await Health.select(.steps, aggregate: .sum)
        .where(.date, .greaterThan, .date(.daysAgo(7)))
        .groupBy(.day)
        .orderBy(.date, .descending)
        .execute()

    for row in result.rows {
        if let date = row.date("date"),
           let steps = row.double("sum_value") {
            print("\(date): \(Int(steps)) steps")
        }
    }
}
```

## Understanding Results

Query results are returned as `QueryResult`:

```swift
let result = try await HQL.query("SELECT * FROM heart_rate LIMIT 10")

// Number of rows
print(result.rows.count)

// Execution time
print("Query took \(result.executionTime)s")

// Access row data
for row in result.rows {
    // Type-safe accessors
    let value = row.double("value")      // Double?
    let date = row.date("date")          // Date?
    let source = row.string("source")    // String?

    // Or use subscript
    let anyValue = row["value"]          // ResultValue?
}
```

## Common Patterns

### Get Latest Reading

```sql
SELECT value, date FROM heart_rate
ORDER BY date DESC
LIMIT 1
```

### Daily Totals

```sql
SELECT sum(value) FROM steps
WHERE date > today() - 7d
GROUP BY day
```

### Weekly Averages

```sql
SELECT avg(value) FROM heart_rate
WHERE date > start_of_month()
GROUP BY week
```

### Filter by Value

```sql
SELECT * FROM heart_rate
WHERE value > 100 AND date > today()
```

## Error Handling

```swift
do {
    let result = try await HQL.query("SELECT * FROM heart_rate")
    // Use result
} catch QueryError.healthKitNotAvailable {
    print("HealthKit is not available on this device")
} catch QueryError.authorizationDenied {
    print("User denied HealthKit access")
} catch let error as ParserError {
    print("SQL syntax error: \(error)")
} catch let error as CompilerError {
    print("Query error: \(error)")
}
```

## Next Steps

- [SQL Syntax](sql-syntax.md) - Full query language reference
- [Quantity Types](quantity-types.md) - All available health types
- [Examples](examples.md) - More query patterns
