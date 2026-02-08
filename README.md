# HealthQL

A SQL-like query language for Apple HealthKit. Query your health data using familiar SQL syntax or a type-safe Swift DSL.

```sql
SELECT avg(value), min(value), max(value)
FROM heart_rate
WHERE date > today() - 7d
GROUP BY day
```

## Features

- **SQL-like Syntax** - Query HealthKit with familiar SELECT, FROM, WHERE, GROUP BY, ORDER BY, LIMIT
- **Type-safe Swift DSL** - Fluent API for building queries programmatically
- **React Native / Expo Support** - Use HealthQL in React Native apps with full TypeScript types
- **18 Quantity Types** - Heart rate, steps, calories, distance, weight, and more
- **5 Category Types** - Sleep analysis, headache, fatigue, appetite, menstrual flow
- **Workouts & Sleep Sessions** - Query exercise data and aggregated sleep metrics
- **Date Functions** - `today()`, `start_of_week()`, `start_of_month()`, `start_of_year()`
- **Aggregations** - SUM, AVG, MIN, MAX, COUNT with GROUP BY support
- **Full Predicate Support** - All comparison operators, AND, IS NULL, IS NOT NULL

> **Expanding Coverage**: We're working toward full HealthKit SDK support. See our [Roadmap](docs/roadmap.md) for nutrition, symptoms, and 70+ additional workout types coming soon.

## Installation

### React Native / Expo

```bash
npm install react-native-healthql
```

Add the config plugin to your `app.json`:

```json
{
  "expo": {
    "plugins": [
      [
        "react-native-healthql",
        {
          "healthShareUsageDescription": "Read health data to display insights"
        }
      ]
    ]
  }
}
```

Then rebuild your app:

```bash
npx expo prebuild --clean
npx expo run:ios
```

### Swift Package Manager

Add HealthQL to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/glisom/HealthQL.git", from: "1.0.0")
]
```

Then add the products you need:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "HealthQL",        // Core types and execution
        "HealthQLParser",  // SQL string parsing
    ]
)
```

### CocoaPods

```ruby
pod 'HealthQL', '~> 1.1.0'
```

## Quick Start

### React Native / TypeScript

```typescript
import { HealthQL } from 'react-native-healthql';

// Request authorization first
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'sleep_analysis'],
});

// Execute a SQL query
const results = await HealthQL.query(`
  SELECT avg(value) FROM heart_rate
  WHERE date > today() - 7d
  GROUP BY day
`);

results.forEach(row => {
  console.log(`${row.date}: ${row.avg_value} bpm`);
});
```

### Swift - SQL String Queries

```swift
import HealthQL
import HealthQLParser

// Parse and execute a query
let result = try await HQL.query("""
    SELECT sum(value) FROM steps
    WHERE date > today() - 7d
    GROUP BY day
""")

for row in result.rows {
    print("\(row["date"]!): \(row["sum_value"]!) steps")
}
```

### Swift DSL

```swift
import HealthQL

let result = try await Health.select(.steps, aggregate: .sum)
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .groupBy(.day)
    .execute()
```

## Supported Health Types

### Quantity Types

| Type | SQL Name | Unit |
|------|----------|------|
| Heart Rate | `heart_rate` | bpm |
| Steps | `steps` | count |
| Active Calories | `active_calories` | kcal |
| Resting Calories | `resting_calories` | kcal |
| Distance | `distance` | m |
| Flights Climbed | `flights_climbed` | count |
| Stand Time | `stand_time` | min |
| Exercise Minutes | `exercise_minutes` | min |
| Body Mass | `body_mass` | kg |
| Height | `height` | m |
| Body Fat % | `body_fat_percentage` | % |
| HRV | `heart_rate_variability` | ms |
| Blood Oxygen | `oxygen_saturation` | % |
| Respiratory Rate | `respiratory_rate` | /min |
| Body Temperature | `body_temperature` | °C |
| Blood Pressure (Sys) | `blood_pressure_systolic` | mmHg |
| Blood Pressure (Dia) | `blood_pressure_diastolic` | mmHg |
| Blood Glucose | `blood_glucose` | mg/dL |

### Category Types

| Type | SQL Name |
|------|----------|
| Sleep Analysis | `sleep_analysis` |
| Appetite Changes | `appetite_changes` |
| Headache | `headache` |
| Fatigue | `fatigue` |
| Menstrual Flow | `menstrual_flow` |

### Special Types

| Type | SQL Name | Description |
|------|----------|-------------|
| Workouts | `workouts` | Exercise sessions with duration, calories, type |
| Sleep Sessions | `sleep` | Aggregated nightly sleep with stage breakdown |

## Query Examples

### Basic Queries

```sql
-- All heart rate readings from today
SELECT * FROM heart_rate WHERE date > today()

-- Latest 10 weight measurements
SELECT value, date FROM body_mass ORDER BY date DESC LIMIT 10

-- Steps with source device info
SELECT value, date, source, device FROM steps WHERE date > today() - 7d
```

### Aggregations

```sql
-- Daily step totals for the past month
SELECT sum(value) FROM steps WHERE date > today() - 30d GROUP BY day

-- Weekly average heart rate
SELECT avg(value), min(value), max(value) FROM heart_rate
WHERE date > start_of_month() GROUP BY week

-- Monthly calorie burn
SELECT sum(value) FROM active_calories WHERE date > start_of_year() GROUP BY month
```

### Workouts

```sql
-- Recent workouts with details
SELECT duration, total_calories, activity_type FROM workouts
ORDER BY date DESC LIMIT 20

-- Weekly workout summary
SELECT sum(duration), sum(total_calories) FROM workouts
WHERE date > today() - 30d GROUP BY week
```

### Sleep

```sql
-- Sleep sessions for the past week
SELECT * FROM sleep WHERE date > today() - 7d ORDER BY date DESC

-- Raw sleep analysis data
SELECT * FROM sleep_analysis WHERE date > today() - 7d
```

### Filtering

```sql
-- High heart rate readings
SELECT * FROM heart_rate WHERE value > 100

-- Heart rate in normal range
SELECT * FROM heart_rate WHERE value > 60 AND value < 100

-- Readings with device info
SELECT * FROM heart_rate WHERE device IS NOT NULL
```

## Date Functions

| Function | Description |
|----------|-------------|
| `today()` | Start of current day |
| `start_of_week()` | Start of current week |
| `start_of_month()` | Start of current month |
| `start_of_year()` | Start of current year |

### Duration Syntax

| Unit | Syntax | Example |
|------|--------|---------|
| Days | `d` | `7d` |
| Weeks | `w` | `4w` |
| Months | `mo` | `3mo` |
| Years | `y` | `1y` |

```sql
-- Last 7 days
WHERE date > today() - 7d

-- Last 4 weeks
WHERE date > today() - 4w

-- Last 3 months
WHERE date > today() - 3mo
```

## Architecture

HealthQL uses a multi-stage architecture:

```
SQL String → Lexer → Parser → AST → Compiler → HealthQuery IR → Executor → Results
                                                      ↑
Swift DSL → QueryBuilder ──────────────────────────────┘
```

### Modules

| Module | Purpose |
|--------|---------|
| `HealthQL` | Core types, IR, DSL, HealthKit execution |
| `HealthQLParser` | SQL lexer, parser, compiler |
| `HealthQLPlayground` | REPL engine, formatting, autocomplete |

## Requirements

- iOS 15.0+ / macOS 13.0+
- Swift 6.0+
- HealthKit entitlement

## HealthKit Setup

1. Add HealthKit capability to your app
2. Add usage descriptions to Info.plist:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Read health data to display query results</string>
```

3. Request authorization (HealthQL requests automatically on first query, or manually):

```swift
let store = HKHealthStore()
try await store.requestAuthorization(toShare: [], read: [
    HKQuantityType(.heartRate),
    HKQuantityType(.stepCount),
    // ... other types
])
```

## Example App

The `HealthQLApp` directory contains a sample iOS app demonstrating:
- Query input with syntax highlighting
- Demo query buttons for common queries
- Result display with formatting
- HealthKit authorization flow

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions welcome! Please read the contributing guidelines before submitting PRs.

---

Built with Swift and HealthKit.
