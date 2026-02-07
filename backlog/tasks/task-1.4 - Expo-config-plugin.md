---
id: TASK-1.4
title: Expo config plugin
status: Done
assignee: []
created_date: '2026-02-07 03:31'
updated_date: '2026-02-07 04:00'
labels: []
dependencies:
  - TASK-1.1
documentation:
  - docs/plans/2026-02-06-react-native-expo-design.md
parent_task_id: TASK-1
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create the Expo config plugin that automatically configures HealthKit entitlements and Info.plist entries.

This enables zero-config setup for Expo managed workflow users.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 plugin/withHealthQL.ts implements Expo config plugin
- [x] #2 Plugin adds com.apple.developer.healthkit entitlement
- [x] #3 Plugin adds NSHealthShareUsageDescription to Info.plist
- [x] #4 healthShareUsageDescription is configurable via plugin options
- [x] #5 Optional backgroundDelivery option adds background modes
- [x] #6 Plugin works with npx expo prebuild
- [x] #7 Plugin documented in package README
<!-- AC:END -->
