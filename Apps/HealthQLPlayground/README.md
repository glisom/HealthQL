# HealthQL Playground App

A REPL-style macOS app for querying HealthKit data using SQL-like syntax.

## Building

1. Open Xcode and create a new macOS App project
2. Name it "HealthQL Playground"
3. Add the HealthQL package as a local dependency:
   - File > Add Package Dependencies
   - Click "Add Local..."
   - Select the root HealthQL folder
4. Add `HealthQLPlayground` library to the app target
5. Copy the Swift files from this folder to the project
6. Configure entitlements for HealthKit access
7. Build and run

## Usage

- Type SQL queries at the prompt
- Use up/down arrows to navigate history
- Meta commands start with `.`

### Commands

- `.types` - List available health types
- `.schema <type>` - Show fields for a type
- `.history` - Show query history
- `.export csv` - Export last result
- `.clear` - Clear screen
- `.help` - Show help

### Example Queries

```sql
SELECT sum(count) FROM steps WHERE date > today() - 7d GROUP BY day
SELECT avg(value), min(value), max(value) FROM heart_rate WHERE date > start_of_month()
SELECT * FROM active_calories ORDER BY date DESC LIMIT 10
```
