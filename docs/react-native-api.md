# TypeScript API Reference

Complete API reference for `react-native-healthql`.

## HealthQL

The main module export with all query and authorization methods.

### `query(sql, options?)`

Execute a SQL query against HealthKit.

```typescript
async query(
  sql: string,
  options?: QueryOptions
): Promise<ResultRow[] | ColumnarResult>
```

**Parameters:**
- `sql` - SQL query string
- `options` - Optional query options

**Returns:** Array of result rows

**Example:**
```typescript
const results = await HealthQL.query(
  'SELECT avg(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day'
);
```

---

### `requestAuthorization(options)`

Request HealthKit authorization for the specified health types.

```typescript
async requestAuthorization(options: AuthorizationOptions): Promise<void>
```

**Parameters:**
- `options.read` - Array of health type identifiers to request read access

**Example:**
```typescript
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'sleep_analysis'],
});
```

---

### `getAuthorizationStatus(type)`

Check the current authorization status for a health type.

```typescript
async getAuthorizationStatus(type: HealthType): Promise<AuthorizationStatus>
```

**Returns:** `'authorized'` | `'denied'` | `'notDetermined'`

**Example:**
```typescript
const status = await HealthQL.getAuthorizationStatus('heart_rate');
```

---

### `getTypes()`

Get all available health type identifiers.

```typescript
getTypes(): HealthType[]
```

**Returns:** Array of all health type strings

---

### `getFields(type)`

Get field information for a specific health type.

```typescript
getFields(type: HealthType): FieldInfo[]
```

**Returns:** Array of field definitions

**Example:**
```typescript
const fields = HealthQL.getFields('heart_rate');
// [{ name: 'value', type: 'number' }, { name: 'date', type: 'Date' }, ...]
```

---

### `getSchema()`

Get the complete schema for all health types.

```typescript
getSchema(): Schema
```

**Returns:**
```typescript
{
  quantityTypes: QuantityType[];
  categoryTypes: CategoryType[];
  specialTypes: SpecialType[];
}
```

---

## Types

### HealthType

Union of all health type identifiers:

```typescript
type HealthType = QuantityType | CategoryType | SpecialType;
```

### QuantityType

```typescript
type QuantityType =
  | 'steps'
  | 'heart_rate'
  | 'active_calories'
  | 'resting_calories'
  | 'distance'
  | 'flights_climbed'
  | 'stand_time'
  | 'exercise_minutes'
  | 'body_mass'
  | 'height'
  | 'body_fat_percentage'
  | 'heart_rate_variability'
  | 'oxygen_saturation'
  | 'respiratory_rate'
  | 'body_temperature'
  | 'blood_pressure_systolic'
  | 'blood_pressure_diastolic'
  | 'blood_glucose';
```

### CategoryType

```typescript
type CategoryType =
  | 'sleep_analysis'
  | 'appetite_changes'
  | 'headache'
  | 'fatigue'
  | 'menstrual_flow';
```

### SpecialType

```typescript
type SpecialType = 'workouts' | 'sleep_sessions';
```

### AuthorizationStatus

```typescript
type AuthorizationStatus = 'authorized' | 'denied' | 'notDetermined';
```

### ResultRow

```typescript
type ResultRow = Record<string, string | number | null>;
```

### FieldInfo

```typescript
interface FieldInfo {
  name: string;
  type: 'string' | 'number' | 'Date';
}
```

---

## HealthQLError

Custom error class for HealthQL-specific errors.

### Properties

- `code` - Error code string
- `message` - Human-readable error message
- `details` - Optional additional details
  - `suggestion` - Suggested fix for the error

### Error Codes

| Code | Description |
|------|-------------|
| `PLATFORM_NOT_SUPPORTED` | Called on Android (iOS only) |
| `HEALTHKIT_NOT_AVAILABLE` | HealthKit unavailable on device |
| `AUTHORIZATION_DENIED` | User denied HealthKit access |
| `INVALID_QUERY` | SQL syntax or semantic error |
| `UNKNOWN_TYPE` | Unrecognized health type identifier |
| `EXECUTION_ERROR` | Error during query execution |

### Example

```typescript
import { HealthQL, HealthQLError } from 'react-native-healthql';

try {
  await HealthQL.query('INVALID SQL');
} catch (error) {
  if (error instanceof HealthQLError) {
    console.log(`Error [${error.code}]: ${error.message}`);
    if (error.details?.suggestion) {
      console.log(`Suggestion: ${error.details.suggestion}`);
    }
  }
}
```
