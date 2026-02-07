---
id: TASK-1.3
title: TypeScript API and type definitions
status: Done
assignee: []
created_date: '2026-02-07 03:31'
updated_date: '2026-02-07 04:02'
labels: []
dependencies:
  - TASK-1.2
documentation:
  - docs/plans/2026-02-06-react-native-expo-design.md
parent_task_id: TASK-1
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the TypeScript wrapper that provides the public API and full type definitions.

Types should be generated/derived from Swift HealthQL core definitions to stay in sync.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 types.ts exports QuantityType, CategoryType, SpecialType, HealthType unions
- [x] #2 types.ts exports QuantityRow, CategoryRow, WorkoutRow, ResultRow interfaces
- [x] #3 errors.ts exports HealthQLError class with code, message, details
- [x] #4 errors.ts exports HealthQLErrorCode type with all error codes
- [x] #5 HealthQL.ts wraps native module with typed async methods
- [x] #6 index.ts exports public API (HealthQL, types, errors)
- [x] #7 Synchronous schema methods (getTypes, getFields, getSchema) work correctly
- [x] #8 All exports have JSDoc documentation
<!-- AC:END -->
