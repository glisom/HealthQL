# HealthQL Example App

A demo Expo app showing how to use `react-native-healthql` for querying Apple HealthKit data.

## Features

- **Query Tab**: Execute SQL-like queries and view results
- **Auth Tab**: Request HealthKit permissions and view authorization status
- **Schema Tab**: Explore available health types and their fields

## Running the Example

### Prerequisites

- Node.js 18+
- iOS Simulator or physical iOS device
- Xcode 15+

### Setup

1. Install dependencies:

```bash
cd example
npm install
```

2. Generate native projects:

```bash
npx expo prebuild
```

3. Run on iOS:

```bash
npx expo run:ios
```

## Testing on Simulator

HealthKit has limited functionality on the iOS Simulator:
- Authorization prompts will appear but data won't be available
- Use a physical device to test with real health data

For development testing without a device, the library includes a mock mode that returns sample data.

## Screenshots

The app has three main screens:

### Query Screen
Enter SQL queries and see results. Includes example queries to get started.

### Authorization Screen
Request read permissions for health data types. Shows current authorization status for each type.

### Schema Screen
Browse all available health types (quantity, category, special) and their fields. Useful for building dynamic query UIs.

## Example Queries

```sql
-- Get recent heart rate readings
SELECT * FROM heart_rate LIMIT 10

-- Average heart rate over the last 7 days, grouped by day
SELECT avg(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day

-- Total steps per day
SELECT sum(value) FROM steps WHERE date > today() - 7d GROUP BY day

-- Recent workouts
SELECT * FROM workouts LIMIT 5

-- Sleep data
SELECT * FROM sleep_analysis LIMIT 5
```

## Troubleshooting

### "HealthKit not available"
HealthKit is only available on iOS devices. The simulator has limited support.

### Authorization denied
Go to Settings > Health > Data Access & Devices > HealthQL Example to manage permissions.

### Build errors
Make sure you've run `npx expo prebuild` after installing dependencies.
