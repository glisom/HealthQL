<!-- _coverpage.md -->

![logo](/_media/logo.svg ':size=120')

# HealthQL

> SQL for Apple HealthKit

- Query health data with familiar SQL syntax
- Type-safe Swift DSL alternative
- 18 quantity types, 5 category types, workouts & sleep

```sql
SELECT avg(value) FROM heart_rate
WHERE date > today() - 7d
GROUP BY day
```

[Get Started](#quick-start)
[GitHub](https://github.com/glisom/HealthQL)
