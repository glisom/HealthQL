# react-native-healthql

SQL-like query language for Apple HealthKit in React Native and Expo.

Part of the [HealthQL](https://github.com/glisom/HealthQL) project - see [full documentation](https://glisom.github.io/HealthQL/).

## Installation

```bash
npx expo install react-native-healthql
```

Or with npm/yarn:

```bash
npm install react-native-healthql
# or
yarn add react-native-healthql
```

## Configuration

### Expo (Managed Workflow)

Add the plugin to your `app.json` or `app.config.js`:

```json
{
  "expo": {
    "plugins": [
      ["react-native-healthql", {
        "healthShareUsageDescription": "This app uses your health data to show fitness insights."
      }]
    ]
  }
}
```

Then run prebuild:

```bash
npx expo prebuild
```

#### Plugin Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `healthShareUsageDescription` | string | "This app uses your health data to provide personalized insights." | The description shown to users when requesting health data access. Required by Apple. |
| `backgroundDelivery` | boolean | false | Enable background delivery of health data updates. |

### Bare React Native

For bare React Native projects, you'll need to manually configure:

1. Add HealthKit capability in Xcode
2. Add `NSHealthShareUsageDescription` to your `Info.plist`
3. Run `pod install`

## Usage

### Basic Query

```typescript
import { HealthQL } from 'react-native-healthql';

// Request authorization first
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'sleep_analysis'],
});

// Execute a SQL-like query
const results = await HealthQL.query(
  'SELECT avg(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day'
);

// Results are typed objects
results.forEach(row => {
  console.log(`${row.date}: ${row.value} ${row.unit}`);
});
```

### Authorization

```typescript
// Request permission to read specific health types
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'weight', 'sleep_analysis'],
});

// Check authorization status for a specific type
const status = await HealthQL.getAuthorizationStatus('heart_rate');
// Returns: 'notDetermined' | 'authorized' | 'denied'
```

### Query Options

```typescript
// Default: array of row objects
const rows = await HealthQL.query('SELECT * FROM steps LIMIT 10');

// Columnar format for performance with large datasets
const columnar = await HealthQL.query(
  'SELECT * FROM steps LIMIT 1000',
  { format: 'columnar' }
);
// Returns: { columns: ['date', 'value', 'unit'], rows: [...] }
```

### Schema Introspection

```typescript
// List all available health types
const types = HealthQL.getTypes();
// ['heart_rate', 'steps', 'weight', ...]

// Get fields for a specific type
const fields = HealthQL.getFields('heart_rate');
// [{ name: 'value', type: 'number' }, { name: 'date', type: 'Date' }, ...]

// Full schema for building query UIs
const schema = HealthQL.getSchema();
// { quantityTypes: [...], categoryTypes: [...], specialTypes: [...] }
```

## Available Health Types

### Quantity Types
- `steps`, `heart_rate`, `active_calories`, `resting_calories`
- `distance`, `flights_climbed`, `stand_time`, `exercise_minutes`
- `body_mass`, `height`, `body_fat_percentage`
- `heart_rate_variability`, `oxygen_saturation`, `respiratory_rate`
- `body_temperature`, `blood_pressure_systolic`, `blood_pressure_diastolic`
- `blood_glucose`

### Category Types
- `sleep_analysis`, `appetite_changes`, `headache`
- `fatigue`, `menstrual_flow`

### Special Types
- `workouts` - Exercise sessions with duration, calories, distance
- `sleep_sessions` - Aggregated sleep data with stage breakdowns

## SQL Syntax

HealthQL supports a subset of SQL:

```sql
SELECT [field | aggregate(field), ...]
FROM health_type
WHERE predicate [AND|OR predicate, ...]
GROUP BY period
ORDER BY field [ASC|DESC]
LIMIT n
```

### Aggregates
`SUM`, `AVG`, `MIN`, `MAX`, `COUNT`

### Date Functions
- `today()` - Current date at midnight
- `start_of_week()` - Start of current week
- `start_of_month()` - Start of current month
- `start_of_year()` - Start of current year

### Duration Syntax
- `7d` - 7 days
- `2w` - 2 weeks
- `3mo` - 3 months
- `1y` - 1 year

## Error Handling

```typescript
import { HealthQL, HealthQLError } from 'react-native-healthql';

try {
  const results = await HealthQL.query('SELECT * FROM invalid_type');
} catch (error) {
  if (error instanceof HealthQLError) {
    switch (error.code) {
      case 'UNKNOWN_TYPE':
        console.log(error.details?.suggestion); // "Did you mean 'heart_rate'?"
        break;
      case 'AUTHORIZATION_DENIED':
        // Prompt user to enable in Settings
        break;
      case 'PARSE_ERROR':
        console.log(`Error at line ${error.details?.line}`);
        break;
    }
  }
}
```

### Error Codes

| Code | Description |
|------|-------------|
| `AUTHORIZATION_DENIED` | User declined health access |
| `AUTHORIZATION_REQUIRED` | Query attempted before authorization |
| `PARSE_ERROR` | Invalid SQL syntax |
| `UNKNOWN_TYPE` | Unknown health type name |
| `UNKNOWN_FIELD` | Invalid field in query |
| `INVALID_AGGREGATION` | Invalid aggregate usage |
| `HEALTHKIT_ERROR` | Underlying HealthKit failure |
| `PLATFORM_NOT_SUPPORTED` | Called on non-iOS platform |

## Platform Support

- **iOS**: Full HealthKit integration
- **Android**: Throws `PLATFORM_NOT_SUPPORTED` error (Health Connect support planned for future)

## Example App

See the [example/](./example) directory for a complete Expo app demonstrating all features:

```bash
cd example
npm install
npx expo prebuild
npx expo run:ios
```

## License

MIT
