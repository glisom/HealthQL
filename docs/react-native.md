# React Native / Expo

HealthQL provides first-class React Native support through the `react-native-healthql` package, an Expo module with full TypeScript types.

## Installation

```bash
npm install react-native-healthql
```

### Expo Config Plugin

Add the plugin to your `app.json` or `app.config.js`:

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

### Rebuild

```bash
npx expo prebuild --clean
npx expo run:ios
```

## Quick Start

```typescript
import { HealthQL } from 'react-native-healthql';

// 1. Request authorization
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'sleep_analysis'],
});

// 2. Execute SQL queries
const results = await HealthQL.query(`
  SELECT avg(value) FROM heart_rate
  WHERE date > today() - 7d
  GROUP BY day
`);

// 3. Use the results
results.forEach(row => {
  console.log(`${row.date}: ${row.avg_value} bpm`);
});
```

## Authorization

HealthKit requires explicit user authorization before accessing health data.

### Request Authorization

```typescript
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'active_calories', 'workouts'],
});
```

### Check Authorization Status

```typescript
const status = await HealthQL.getAuthorizationStatus('heart_rate');

switch (status) {
  case 'authorized':
    // Can read heart rate data
    break;
  case 'denied':
    // User denied access - show settings prompt
    break;
  case 'notDetermined':
    // Need to request authorization
    break;
}
```

## Query Examples

### Basic Queries

```typescript
// Get recent heart rate readings
const heartRate = await HealthQL.query(
  'SELECT * FROM heart_rate LIMIT 10'
);

// Get today's steps
const steps = await HealthQL.query(
  'SELECT sum(value) FROM steps WHERE date > today()'
);
```

### Aggregations

```typescript
// Daily averages for the past week
const dailyAvg = await HealthQL.query(`
  SELECT avg(value), min(value), max(value)
  FROM heart_rate
  WHERE date > today() - 7d
  GROUP BY day
`);

// Weekly step totals
const weeklySteps = await HealthQL.query(`
  SELECT sum(value) FROM steps
  WHERE date > today() - 30d
  GROUP BY week
`);
```

### Workouts

```typescript
// Recent workouts
const workouts = await HealthQL.query(`
  SELECT duration, total_calories, activity_type
  FROM workouts
  ORDER BY date DESC
  LIMIT 20
`);
```

### Sleep

```typescript
// Sleep sessions for the past week
const sleep = await HealthQL.query(`
  SELECT * FROM sleep_analysis
  WHERE date > today() - 7d
  ORDER BY date DESC
`);
```

## Schema Introspection

Discover available health types programmatically:

```typescript
// Get all available types
const types = HealthQL.getTypes();
// ['heart_rate', 'steps', 'active_calories', ...]

// Get fields for a specific type
const fields = HealthQL.getFields('heart_rate');
// [{ name: 'value', type: 'number' }, { name: 'date', type: 'Date' }, ...]

// Get the full schema
const schema = HealthQL.getSchema();
// { quantityTypes: [...], categoryTypes: [...], specialTypes: [...] }
```

## Error Handling

```typescript
import { HealthQL, HealthQLError } from 'react-native-healthql';

try {
  const results = await HealthQL.query('SELECT * FROM heart_rate');
} catch (error) {
  if (error instanceof HealthQLError) {
    switch (error.code) {
      case 'AUTHORIZATION_DENIED':
        // User denied HealthKit access
        break;
      case 'INVALID_QUERY':
        // SQL syntax error
        console.log(error.details?.suggestion);
        break;
      case 'PLATFORM_NOT_SUPPORTED':
        // Running on Android
        break;
    }
  }
}
```

## Platform Support

| Platform | Support |
|----------|---------|
| iOS | Full support |
| Android | Not supported (throws `PLATFORM_NOT_SUPPORTED`) |

## Example App

The package includes a complete example app demonstrating all features:

```bash
cd packages/react-native-healthql/example
npm install
npx expo run:ios
```
