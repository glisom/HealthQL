---
id: TASK-1.1
title: Package scaffolding and build setup
status: Done
assignee: []
created_date: '2026-02-07 03:31'
updated_date: '2026-02-07 03:53'
labels: []
dependencies: []
references:
  - Sources/HealthQL/
  - Package.swift
documentation:
  - docs/plans/2026-02-06-react-native-expo-design.md
parent_task_id: TASK-1
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Set up the npm package structure for react-native-healthql with Expo Modules API configuration.

This creates the foundation that all other subtasks build upon.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create packages/react-native-healthql directory
- [x] #2 package.json with correct expo-modules dependencies
- [x] #3 expo-module.config.json configured for iOS platform
- [x] #4 HealthQL.podspec that vendors the Swift HealthQL core
- [x] #5 tsconfig.json for TypeScript compilation
- [x] #6 Build scripts produce valid JS and .d.ts outputs
- [x] #7 Package can be locally linked for development
<!-- AC:END -->
