# Quantity Types

HealthQL supports 33 quantity types from HealthKit.

## Available Types

### Activity & Fitness

| SQL Name | Description | Default Unit |
|----------|-------------|--------------|
| `steps` | Step count | count |
| `distance` | Walking + running distance | meters |
| `flights_climbed` | Floors climbed | count |
| `stand_time` | Stand time | minutes |
| `exercise_minutes` | Exercise time | minutes |
| `active_calories` | Active energy burned | kcal |
| `resting_calories` | Basal energy burned | kcal |
| `vo2_max` | VO2 max | mL/(kg·min) |
| `distance_swimming` | Swimming distance | meters |
| `swimming_stroke_count` | Swimming strokes | count |
| `distance_wheelchair` | Wheelchair distance | meters |
| `push_count` | Wheelchair pushes | count |
| `distance_downhill_snow_sports` | Skiing/snowboarding distance | meters |

### Heart & Vitals

| SQL Name | Description | Default Unit |
|----------|-------------|--------------|
| `heart_rate` | Heart rate | bpm |
| `resting_heart_rate` | Resting heart rate | bpm |
| `walking_heart_rate_average` | Walking heart rate average | bpm |
| `heart_rate_variability` | HRV (SDNN) | ms |
| `oxygen_saturation` | Blood oxygen (SpO2) | % |
| `respiratory_rate` | Breathing rate | /min |
| `body_temperature` | Body temperature | °C |
| `basal_body_temperature` | Basal body temperature | °C |
| `blood_pressure_systolic` | Systolic BP | mmHg |
| `blood_pressure_diastolic` | Diastolic BP | mmHg |
| `blood_glucose` | Blood sugar | mg/dL |
| `peripheral_perfusion_index` | Peripheral perfusion | % |
| `electrodermal_activity` | Electrodermal activity | siemens |
| `blood_alcohol_content` | Blood alcohol | % |

### Body Measurements

| SQL Name | Description | Default Unit |
|----------|-------------|--------------|
| `body_mass` | Body weight | kg |
| `height` | Height | meters |
| `body_fat_percentage` | Body fat | % |
| `lean_body_mass` | Lean body mass | kg |
| `body_mass_index` | BMI | count |
| `waist_circumference` | Waist circumference | meters |

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

### VO2 Max & Fitness

```sql
-- VO2 max trend over 90 days
SELECT avg(value) FROM vo2_max
WHERE date > today() - 90d
GROUP BY month

-- Resting heart rate trend
SELECT avg(value) FROM resting_heart_rate
WHERE date > today() - 30d
GROUP BY week

-- Walking heart rate average
SELECT avg(value) FROM walking_heart_rate_average
WHERE date > today() - 7d
GROUP BY day
```

### Swimming

```sql
-- Swimming distance by week
SELECT sum(value) FROM distance_swimming
WHERE date > today() - 30d
GROUP BY week

-- Stroke count per session
SELECT value, date FROM swimming_stroke_count
ORDER BY date DESC LIMIT 10
```

### Body Composition

```sql
-- BMI trend
SELECT value, date FROM body_mass_index
ORDER BY date DESC LIMIT 30

-- Lean body mass tracking
SELECT value, date FROM lean_body_mass
WHERE date > today() - 90d
ORDER BY date DESC
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
