# Changelog

All notable changes to HealthQL will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-31

### Added

- **SQL Query Language**
  - Full SELECT statement support with WHERE, GROUP BY, ORDER BY, LIMIT
  - Aggregate functions: SUM, AVG, MIN, MAX, COUNT
  - Comparison operators: =, !=, <, >, <=, >=, BETWEEN, IS NULL, IS NOT NULL
  - Logical operators: AND, OR

- **Swift DSL**
  - Fluent QueryBuilder API
  - Type-safe field and operator enums
  - Async/await execution

- **Health Data Types**
  - 18 quantity types (steps, heart rate, calories, etc.)
  - 5 category types (sleep analysis, headache, fatigue, etc.)
  - Workout sessions with activity types
  - Sleep sessions with stage durations

- **Date Functions**
  - Relative dates: `today()`, `now()`
  - Period starts: `start_of_week()`, `start_of_month()`, `start_of_year()`
  - Duration arithmetic: `today() - 7d`, `today() - 3mo`

- **Grouping**
  - Time-based grouping: hour, day, week, month, year
  - Automatic date bucketing for aggregations

- **Documentation**
  - Comprehensive README
  - API reference
  - Query examples
  - GitHub Pages documentation site

### Technical Details

- Swift 6.0 with strict concurrency
- iOS 18.0+ / macOS 15.0+
- Zero external dependencies
- 194 unit tests
