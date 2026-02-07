# Installation

## React Native / Expo

### Install the package

```bash
npm install react-native-healthql
# or
yarn add react-native-healthql
```

### Add the Expo config plugin

In your `app.json` or `app.config.js`:

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

### Rebuild your app

```bash
npx expo prebuild --clean
npx expo run:ios
```

> **Note:** HealthQL only supports iOS. On Android, API calls will throw a `PLATFORM_NOT_SUPPORTED` error.

### Request Authorization

Before querying health data, request user authorization:

```typescript
import { HealthQL } from 'react-native-healthql';

await HealthQL.requestAuthorization({
  read: ['heart_rate', 'steps', 'sleep_analysis', 'workouts'],
});
```

### Execute Queries

```typescript
const results = await HealthQL.query(`
  SELECT avg(value) FROM heart_rate
  WHERE date > today() - 7d
  GROUP BY day
`);
```

---

## Swift Package Manager

### Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/glisom/HealthQL.git
   ```
4. Select version rule: **Up to Next Major** from `1.0.0`
5. Choose the libraries to add:

| Library | Purpose |
|---------|---------|
| **HealthQL** | Core types, DSL, HealthKit execution |
| **HealthQLParser** | SQL string parsing and compilation |
| **HealthQLPlayground** | REPL engine, formatting (optional) |

### Package.swift

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/glisom/HealthQL.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "HealthQL", package: "HealthQL"),
            .product(name: "HealthQLParser", package: "HealthQL"),
        ]
    )
]
```

## CocoaPods

Add to your `Podfile`:

```ruby
pod 'HealthQL', '~> 1.1.0'
```

Then run:

```bash
pod install
```

---

## HealthKit Setup

### 1. Enable HealthKit Capability

In Xcode:
1. Select your target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **HealthKit**

### 2. Add Usage Descriptions

Add to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Read health data to display query results</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Write health data (if needed)</string>
```

### 3. Request Authorization

HealthQL automatically requests authorization on first query, but you can also request it manually:

```swift
import HealthKit

let store = HKHealthStore()

let typesToRead: Set<HKObjectType> = [
    HKQuantityType(.heartRate),
    HKQuantityType(.stepCount),
    HKQuantityType(.activeEnergyBurned),
    HKCategoryType(.sleepAnalysis),
    HKWorkoutType.workoutType()
]

try await store.requestAuthorization(toShare: [], read: typesToRead)
```

## Verify Installation

```swift
import HealthQL
import HealthQLParser

// This should compile and run
let query = try HQL.parse("SELECT * FROM heart_rate LIMIT 1")
print("HealthQL installed successfully!")
```
