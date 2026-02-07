# React Native & Expo Support Design

**Date:** 2026-02-06
**Status:** Approved

## Overview

Add React Native and Expo support to HealthQL via a native module bridge that exposes the existing Swift core to JavaScript developers.

## Key Decisions

| Decision | Choice |
|----------|--------|
| **Approach** | Native module bridge (Swift core stays) |
| **Module system** | Expo Modules API |
| **API surface** | SQL queries + schema introspection + authorization |
| **Result format** | Row objects (default) + columnar option |
| **Error handling** | Promise rejections with typed errors |
| **TypeScript** | Full generated types for all health types |
| **Package** | Single `react-native-healthql` package |
| **Config** | Expo plugin for automatic entitlements |
| **Testing** | Jest + Detox + example app |

## Package Overview & User Experience

**Package:** `react-native-healthql`

**Installation:**
```bash
npx expo install react-native-healthql
```

The Expo config plugin automatically handles:
- HealthKit entitlement in `ios/[app].entitlements`
- `NSHealthShareUsageDescription` in Info.plist (customizable)
- Required Swift/bridging header setup

**Basic usage:**
```typescript
import { HealthQL } from 'react-native-healthql';

// Request authorization first
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'sleep_analysis'],
});

// Query with familiar SQL syntax
const results = await HealthQL.query(
  'SELECT avg(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day'
);

// Results as typed objects
results.forEach(row => {
  console.log(`${row.date}: ${row.value} ${row.unit}`);
});
```

**Platform behavior:**
- iOS: Full HealthKit integration via Swift HealthQL core
- Android: Throws `PLATFORM_NOT_SUPPORTED` error (clear messaging, no silent failures)

Future Android support could integrate Health Connect, but that's out of scope for v1.

## Full API Surface

### Core Query Function

```typescript
// Default: array of row objects
const rows = await HealthQL.query('SELECT * FROM steps LIMIT 10');

// Columnar format for performance
const columnar = await HealthQL.query(
  'SELECT * FROM steps LIMIT 1000',
  { format: 'columnar' }
);
// { columns: ['date', 'value', 'unit'], rows: [...] }
```

### Authorization API

```typescript
// Request permissions (shows iOS health access prompt)
await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'weight', 'sleep_analysis'],
});

// Check current status for a specific type
const status = await HealthQL.getAuthorizationStatus('heart_rate');
// Returns: 'notDetermined' | 'authorized' | 'denied'
```

### Schema Introspection API

```typescript
// List all available health types
const types = HealthQL.getTypes();
// ['heart_rate', 'steps', 'weight', 'blood_pressure', ...]

// Get fields for a specific type
const fields = HealthQL.getFields('heart_rate');
// [{ name: 'value', type: 'number' }, { name: 'date', type: 'Date' }, ...]

// Full schema (for building query UIs)
const schema = HealthQL.getSchema();
// { quantityTypes: [...], categoryTypes: [...], specialTypes: [...] }
```

Schema introspection methods are synchronous since they return static metadata, not HealthKit data.

## TypeScript Types

### Generated type definitions for all health types

```typescript
// Health type literals for autocomplete
type QuantityType =
  | 'heart_rate' | 'steps' | 'weight' | 'height'
  | 'active_calories' | 'resting_calories' | 'distance'
  | 'blood_pressure_systolic' | 'blood_pressure_diastolic'
  | 'blood_glucose' | 'body_temperature' | 'hrv'
  | 'oxygen_saturation' | 'respiratory_rate'
  | 'body_fat' | 'bmi' | 'water' | 'caffeine';

type CategoryType =
  | 'sleep_analysis' | 'headache' | 'fatigue'
  | 'appetite' | 'menstrual_flow';

type SpecialType = 'workouts' | 'sleep_sessions';

type HealthType = QuantityType | CategoryType | SpecialType;
```

### Result row types

```typescript
interface QuantityRow {
  date: string;      // ISO 8601
  value: number;
  unit: string;
}

interface CategoryRow {
  date: string;
  value: string;     // e.g., 'asleep', 'mild', 'moderate'
  duration?: number; // seconds, when applicable
}

interface WorkoutRow {
  date: string;
  type: string;      // 'running', 'cycling', etc.
  duration: number;  // seconds
  calories: number;
  distance?: number;
}

// Query returns union type
type ResultRow = QuantityRow | CategoryRow | WorkoutRow;
```

Types are generated from the Swift HealthQL core's type definitions to stay in sync.

## Error Handling

### Typed error codes

```typescript
type HealthQLErrorCode =
  | 'AUTHORIZATION_DENIED'      // User declined health access
  | 'AUTHORIZATION_REQUIRED'    // Query attempted before authorization
  | 'PARSE_ERROR'               // Invalid SQL syntax
  | 'UNKNOWN_TYPE'              // e.g., "SELECT * FROM invalid_type"
  | 'UNKNOWN_FIELD'             // Invalid field in SELECT/WHERE
  | 'INVALID_AGGREGATION'       // e.g., "avg()" on category type
  | 'HEALTHKIT_ERROR'           // Underlying HealthKit failure
  | 'PLATFORM_NOT_SUPPORTED';   // Called on Android

interface HealthQLError extends Error {
  code: HealthQLErrorCode;
  message: string;
  details?: {
    line?: number;      // For parse errors
    column?: number;
    suggestion?: string; // "Did you mean 'heart_rate'?"
  };
}
```

### Usage pattern

```typescript
try {
  const results = await HealthQL.query('SELECT * FROM hart_rate');
} catch (error) {
  if (error instanceof HealthQLError) {
    switch (error.code) {
      case 'UNKNOWN_TYPE':
        console.log(error.details?.suggestion); // "Did you mean 'heart_rate'?"
        break;
      case 'AUTHORIZATION_DENIED':
        showPermissionsPrompt();
        break;
    }
  }
}
```

Parse errors include line/column info for highlighting in query builder UIs. The `suggestion` field provides typo corrections using fuzzy matching.

## Internal Architecture

### Module structure

```
react-native-healthql/
├── src/                          # TypeScript source
│   ├── index.ts                  # Public API exports
│   ├── HealthQL.ts               # Main class wrapping native module
│   ├── types.ts                  # Generated type definitions
│   └── errors.ts                 # HealthQLError class
├── ios/                          # Native Swift code
│   ├── HealthQLModule.swift      # Expo module definition
│   ├── HealthQLBridge.swift      # Bridges to Swift HealthQL core
│   └── ResultConverter.swift     # Converts Swift results to JS-friendly format
├── plugin/                       # Expo config plugin
│   └── withHealthQL.ts           # Adds entitlements & Info.plist
├── HealthQL.podspec              # CocoaPods spec (vendors Swift core)
├── expo-module.config.json       # Expo modules configuration
└── package.json
```

### Data flow

```
JS: HealthQL.query("SELECT...")
        ↓
Native: HealthQLModule.query(sql, options)
        ↓
Swift: HealthQL core (Lexer → Parser → Compiler → Executor)
        ↓
Native: ResultConverter transforms ResultRow[] to NSDictionary[]
        ↓
JS: Promise resolves with typed results
```

The Swift HealthQL package is vendored via CocoaPods, pointing to a specific release tag for version stability.

## Expo Config Plugin

### Auto-configuration via `app.json`

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

### What the plugin does automatically

1. **Entitlements** - Adds `com.apple.developer.healthkit` to iOS entitlements
2. **Info.plist** - Sets `NSHealthShareUsageDescription` with custom or default text
3. **Background modes** (optional) - If configured, adds background health delivery:
   ```json
   ["react-native-healthql", {
     "healthShareUsageDescription": "...",
     "backgroundDelivery": true
   }]
   ```

**No manual Xcode configuration required.** Works with:
- `npx expo prebuild` for managed workflow
- `npx expo run:ios` for development builds
- EAS Build for production

For bare React Native (non-Expo), the README will document manual entitlement setup, but autolinking handles the native module registration automatically.

## Testing Strategy

### Three test layers

1. **TypeScript unit tests** (Jest)
   - Error class construction and serialization
   - Type guard functions
   - Result format conversions
   - No native code involved

2. **Native module integration tests** (Detox + Expo)
   - Run on iOS simulator with mock HealthKit data
   - Test authorization flow
   - Verify query execution and result parsing
   - Test error propagation from Swift to JS

3. **Example app for manual testing**
   - Simple Expo app in `example/` directory
   - Query input with results display
   - Authorization status indicator
   - Useful for development and as documentation

### HealthKit mocking approach

Since HealthKit doesn't work in simulators with real data, integration tests use:
- `HKHealthStore` stubbing in Swift for controlled test data
- A `__DEV__` mode that returns predictable mock results
- Real device testing for final validation

## Out of Scope for v1

- Android Health Connect integration
- Write access to HealthKit (read-only for v1)
- Background data delivery/sync
- Streaming/observable query results
