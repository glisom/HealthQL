---
id: TASK-1
title: React Native & Expo Support (react-native-healthql)
status: Done
assignee: []
created_date: '2026-02-07 03:30'
updated_date: '2026-02-07 04:08'
labels: []
dependencies: []
documentation:
  - docs/plans/2026-02-06-react-native-expo-design.md
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create a React Native package that exposes HealthQL's Swift core to JavaScript developers via Expo Modules API. This enables React Native and Expo apps to query HealthKit data using familiar SQL syntax.

The package will be published as `react-native-healthql` on npm and include an Expo config plugin for automatic HealthKit entitlement setup.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 JS developers can install via `npx expo install react-native-healthql`
- [x] #2 SQL queries execute and return typed results to JavaScript
- [x] #3 Authorization flow works from JS (request permissions, check status)
- [x] #4 Schema introspection available (getTypes, getFields, getSchema)
- [x] #5 Expo config plugin automatically adds HealthKit entitlements
- [x] #6 Full TypeScript types for all health types and results
- [x] #7 Example app demonstrates all features
- [x] #8 Works with Expo managed workflow and bare React Native
<!-- AC:END -->
