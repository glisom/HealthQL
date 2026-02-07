---
id: TASK-3
title: Add CocoaPods support to HealthQL for React Native real data
status: Done
assignee: []
created_date: '2026-02-07 22:41'
updated_date: '2026-02-07 23:06'
labels:
  - cocoapods
  - react-native
  - infrastructure
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add CocoaPods distribution support to the main HealthQL Swift package so the react-native-healthql Expo module can use real HealthKit data instead of mock data.

## Background
Currently react-native-healthql uses mock data because HealthQL is an SPM-only package and Expo modules use CocoaPods. By adding a podspec to HealthQL, we can bridge this gap.

## Approach
- Add CocoaPods support alongside existing SPM (dual distribution)
- Single flat pod containing HealthQL + HealthQLParser sources
- Use local path reference for development (can publish to Trunk later)
- Update the Expo module to depend on and use real HealthQL
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 HealthQL.podspec exists and validates with `pod lib lint`
- [x] #2 react-native-healthql depends on HealthQL pod
- [x] #3 HealthQLBridge uses real HealthQL parser and executor
- [x] #4 Example app executes real SQL queries against HealthKit
- [x] #5 SPM support continues to work (no regression)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Plan

### Step 1: Create HealthQL.podspec
**Location:** `/HealthQL.podspec` (package root)

```ruby
Pod::Spec.new do |s|
  s.name             = 'HealthQL'
  s.version          = '0.1.0'
  s.summary          = 'SQL-like query interface for Apple HealthKit'
  s.homepage         = 'https://github.com/grantisimo/HealthQL'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Grant Isom' => 'glisom@icloud.com' }
  s.source           = { :git => 'https://github.com/grantisimo/HealthQL.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.9'
  
  # Include both HealthQL and HealthQLParser sources
  s.source_files = 'Sources/HealthQL/**/*.swift', 
                   'Sources/HealthQLParser/**/*.swift'
  
  s.frameworks = 'HealthKit'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
end
```

### Step 2: Update react-native-healthql.podspec
**Location:** `packages/react-native-healthql/ios/react-native-healthql.podspec`

Add dependency:
```ruby
s.dependency 'HealthQL'
```

### Step 3: Update example app Podfile
**Location:** `packages/react-native-healthql/example/ios/Podfile`

Add after `use_expo_modules!`:
```ruby
pod 'HealthQL', :path => '../../../..'
```

### Step 4: Update HealthQLBridge.swift
**Location:** `packages/react-native-healthql/ios/HealthQLBridge.swift`

- Import `HealthQL` and `HealthQLParser`
- Create `Executor` instance with health store
- Replace mock data call with real parser + executor
- Convert results to JS-friendly format

### Step 5: Test
1. Run `pod install` in example/ios
2. Build the app
3. Request HealthKit authorization
4. Execute real query
5. Verify SPM still works (`swift build`)
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## Summary

Added CocoaPods support to HealthQL enabling the React Native/Expo module to use the real HealthQL core library instead of mock data.

## Changes Made

1. **Created `/HealthQL.podspec`** - New podspec combining HealthQL and HealthQLParser sources into a single CocoaPods-compatible module

2. **Fixed naming collision in `/Sources/HealthQLParser/AST.swift`** - Renamed `OrderDirection` to `ASTOrderDirection` to avoid conflict with IR.swift's version when both are compiled together in CocoaPods

3. **Updated `/Sources/HealthQLParser/Parser.swift`** - Updated references to use `ASTOrderDirection`

4. **Updated `/packages/react-native-healthql/ios/react-native-healthql.podspec`** - Added dependency on HealthQL pod

5. **Updated `/packages/react-native-healthql/ios/HealthQLBridge.swift`** - Changed from mock data to real `HQL.query()` API calls

6. **Updated `/packages/react-native-healthql/example/ios/Podfile`** - Added local path reference to HealthQL pod for development

## Verification

- SPM build still works (`swift build` succeeds)
- CocoaPods build succeeds
- Example app now uses real HealthKit queries (returns empty results without authorization, as expected)
- No more mock data - app properly respects HealthKit authorization status
<!-- SECTION:FINAL_SUMMARY:END -->
