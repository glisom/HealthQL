# Quantity Types

HealthQL supports 18 quantity types from HealthKit.

## Available Types

| SQL Name | Description | Default Unit |
|----------|-------------|--------------|
| `heart_rate` | Heart rate | bpm |
| `steps` | Step count | count |
| `active_calories` | Active energy burned | kcal |
| `resting_calories` | Basal energy burned | kcal |
| `distance` | Walking + running distance | meters |
| `flights_climbed` | Floors climbed | count |
| `stand_time` | Stand time | minutes |
| `exercise_minutes` | Exercise time | minutes |
| `body_mass` | Body weight | kg |
| `height` | Height | meters |
| `body_fat_percentage` | Body fat | % |
| `heart_rate_variability` | HRV (SDNN) | ms |
| `oxygen_saturation` | Blood oxygen (SpO2) | % |
| `respiratory_rate` | Breathing rate | /min |
| `body_temperature` | Body temperature | °C |
| `blood_pressure_systolic` | Systolic BP | mmHg |
| `blood_pressure_diastolic` | Diastolic BP | mmHg |
| `blood_glucose` | Blood sugar | mg/dL |

## Available Fields

All quantity types support:

| Field | Type | Description |
|-------|------|-------------|
| `value` | Double | The measured value |
| `date` | Date | Start date of measurement |
| `end_date` | Date | End date (usually same as date) |
| `source` | String | App/device that recorded |
| `device` | String | Physical device name |

## Examples

### Heart Rate

```sql
-- Average heart rate by day
SELECT avg(value), min(value), max(value)
FROM heart_rate
WHERE date > today() - 7d
GROUP BY day

-- Latest reading
SELECT value, date FROM heart_rate
ORDER BY date DESC LIMIT 1

-- High heart rate events
SELECT value, date, source FROM heart_rate
WHERE value > 100 AND date > today() - 24h
```

### Steps

```sql
-- Daily step count
SELECT sum(value) FROM steps
WHERE date > today() - 30d
GROUP BY day

-- Weekly totals
SELECT sum(value) FROM steps
WHERE date > start_of_year()
GROUP BY week

-- Today's steps by source
SELECT sum(value), source FROM steps
WHERE date > today()
GROUP BY day
```

### Active Calories

```sql
-- Daily calorie burn
SELECT sum(value) FROM active_calories
WHERE date > today() - 7d
GROUP BY day

-- Monthly totals
SELECT sum(value) FROM active_calories
WHERE date > start_of_year()
GROUP BY month
```

### Body Measurements

```sql
-- Weight trend
SELECT value, date FROM body_mass
ORDER BY date DESC
LIMIT 30

-- Body fat trend
SELECT avg(value) FROM body_fat_percentage
WHERE date > today() - 3mo
GROUP BY week

-- Latest height
SELECT value FROM height
ORDER BY date DESC LIMIT 1
```

### Vitals

```sql
-- Blood oxygen readings
SELECT avg(value), min(value) FROM oxygen_saturation
WHERE date > today() - 7d
GROUP BY day

-- Respiratory rate
SELECT avg(value) FROM respiratory_rate
WHERE date > today() - 7d
GROUP BY day

-- HRV trend
SELECT avg(value) FROM heart_rate_variability
WHERE date > today() - 30d
GROUP BY day
```

### Blood Pressure

```sql
-- Recent BP readings
SELECT value, date FROM blood_pressure_systolic
ORDER BY date DESC LIMIT 10

-- Average BP by week
SELECT avg(value) FROM blood_pressure_systolic
WHERE date > today() - 30d
GROUP BY week
```

## Swift DSL

```swift
// Using QuantityType enum
Health.select(.heartRate)
Health.select(.steps, aggregate: .sum)
Health.select(.activeCalories, aggregates: [.sum, .avg])
Health.select(.bodyMass)
Health.select(.oxygenSaturation)
```
