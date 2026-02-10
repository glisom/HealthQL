# Swift DSL

HealthQL provides a type-safe Swift DSL as an alternative to SQL strings.

## Basic Usage

```swift
import HealthQL

let result = try await Health.select(.heartRate)
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .execute()
```

## Building Queries

### Select a Type

```swift
// Single type
Health.select(.steps)
Health.select(.heartRate)
Health.select(.activeCalories)
```

### Add Aggregation

```swift
// Single aggregation
Health.select(.steps, aggregate: .sum)
Health.select(.heartRate, aggregate: .avg)

// Multiple aggregations
Health.select(.heartRate, aggregates: [.avg, .min, .max])
```

### Filter with WHERE

```swift
.where(.date, .greaterThan, .date(.daysAgo(7)))
.where(.value, .greaterThan, .double(100))
.where(.date, .greaterThan, .date(.startOfMonth))
```

### Group Results

```swift
.groupBy(.hour)
.groupBy(.day)
.groupBy(.week)
.groupBy(.month)
```

### Order Results

```swift
.orderBy(.date, .ascending)
.orderBy(.date, .descending)
.orderBy(.value, .descending)
```

### Limit Results

```swift
.limit(10)
.limit(100)
```

### Execute

```swift
let result = try await builder.execute()
```

## Complete Examples

### Daily Step Totals

```swift
let result = try await Health.select(.steps, aggregate: .sum)
    .where(.date, .greaterThan, .date(.daysAgo(30)))
    .groupBy(.day)
    .orderBy(.date, .descending)
    .execute()
```

### Heart Rate Statistics

```swift
let result = try await Health.select(.heartRate, aggregates: [.avg, .min, .max])
    .where(.date, .greaterThan, .date(.startOfWeek))
    .groupBy(.day)
    .execute()
```

### Latest Weight

```swift
let result = try await Health.select(.bodyMass)
    .orderBy(.date, .descending)
    .limit(1)
    .execute()

if let weight = result.rows.first?.double("value") {
    print("Current weight: \(weight) kg")
}
```

### High Heart Rate Alerts

```swift
let result = try await Health.select(.heartRate)
    .where(.value, .greaterThan, .double(100))
    .where(.date, .greaterThan, .date(.today))
    .orderBy(.value, .descending)
    .execute()
```

## Date References

```swift
DateReference.today           // Start of today
DateReference.hoursAgo(4)     // 4 hours ago
DateReference.daysAgo(7)      // 7 days ago
DateReference.weeksAgo(4)     // 4 weeks ago
DateReference.monthsAgo(3)    // 3 months ago
DateReference.startOfWeek     // Start of current week
DateReference.startOfMonth    // Start of current month
DateReference.startOfYear     // Start of current year
DateReference.exact(someDate) // Specific Date object
```

## Operators

```swift
Operator.equal
Operator.notEqual
Operator.greaterThan
Operator.greaterThanOrEqual
Operator.lessThan
Operator.lessThanOrEqual
Operator.between
Operator.isNull
Operator.isNotNull
```

## Accessing the IR

You can access the intermediate representation without executing:

```swift
let builder = Health.select(.steps, aggregate: .sum)
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .groupBy(.day)

let query: HealthQuery = builder.buildQuery()

print(query.source)      // .quantity(.steps)
print(query.grouping)    // .day
print(query.predicates)  // [Predicate(...)]
```

## SQL vs DSL Comparison

<!-- tabs:start -->

#### **SQL**

```swift
let result = try await HQL.query("""
    SELECT sum(value)
    FROM steps
    WHERE date > today() - 7d
    GROUP BY day
    ORDER BY date DESC
    LIMIT 7
""")
```

#### **DSL**

```swift
let result = try await Health.select(.steps, aggregate: .sum)
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .groupBy(.day)
    .orderBy(.date, .descending)
    .limit(7)
    .execute()
```

<!-- tabs:end -->
