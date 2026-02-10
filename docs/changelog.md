# Changelog

All notable changes to HealthQL will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.2.1] - 2026-02-10

### Changes

- fix: use macos-26 runner for Swift 6.2 compatibility
- fix: update CI workflow for current runner environments

## [1.2.0] - 2026-02-08

### Added

- **15 New Quantity Types** (Phase 4: Extended Vitals & Fitness)
  - Vitals: `resting_heart_rate`, `walking_heart_rate_average`, `basal_body_temperature`, `peripheral_perfusion_index`, `electrodermal_activity`, `blood_alcohol_content`
  - Fitness: `vo2_max`, `distance_swimming`, `swimming_stroke_count`, `distance_wheelchair`, `push_count`, `distance_downhill_snow_sports`
  - Body: `lean_body_mass`, `body_mass_index`, `waist_circumference`

- **HealthKit Coverage Roadmap**
  - Documentation outlining 8-phase plan to full HealthKit SDK coverage
  - See [docs/roadmap.md](roadmap.md) for details

### Improved

- **Test Coverage**
  - Added comprehensive tests for QuantityQueryHandler helper methods
  - Added compiler tests for all new quantity types
  - Total tests: 326 (up from ~275)

### Technical Details

- Quantity type coverage: 18 → 33 types (22% → 41% of HealthKit)
- All new types fully integrated with SQL compiler

## [1.1.0] - 2026-02-07

### Added

- **React Native / Expo Support**
  - New `react-native-healthql` npm package
  - Expo config plugin for automatic HealthKit setup
  - Full TypeScript types
  - Background delivery support

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
