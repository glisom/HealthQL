# HealthKit SDK Coverage Roadmap

This document outlines HealthQL's plan to achieve comprehensive HealthKit SDK coverage.

## Current Coverage

HealthQL currently supports approximately **15-20%** of HealthKit's data types:

| Data Type Class | Supported | Total | Coverage |
|-----------------|-----------|-------|----------|
| Quantity Types | 18 | ~80+ | 22% |
| Category Types | 5 | 70 | 7% |
| Workout Types | 12 | 84 | 14% |
| Characteristics | 0 | 8 | 0% |
| Clinical Records | 0 | 10+ | 0% |

### Currently Supported

**Quantity Types (18)**
- Activity: `steps`, `distance`, `flights_climbed`, `stand_time`, `exercise_minutes`
- Calories: `active_calories`, `resting_calories`
- Heart: `heart_rate`, `heart_rate_variability`
- Vitals: `oxygen_saturation`, `respiratory_rate`, `body_temperature`
- Blood: `blood_pressure_systolic`, `blood_pressure_diastolic`, `blood_glucose`
- Body: `body_mass`, `height`, `body_fat_percentage`

**Category Types (5)**
- `sleep_analysis`, `appetite_changes`, `headache`, `fatigue`, `menstrual_flow`

**Workout Types (12)**
- `running`, `walking`, `cycling`, `swimming`, `yoga`, `strength_training`
- `hiking`, `elliptical`, `rowing`, `functional_training`, `core_training`, `hiit`

---

## Roadmap Phases

### Phase 1: Nutrition Foundation

**Goal**: Support dietary and nutrition tracking

Add 15 core nutrition quantity types:
- `dietary_energy`, `dietary_protein`, `dietary_carbohydrates`, `dietary_fat_total`
- `dietary_fiber`, `dietary_sugar`, `dietary_sodium`, `dietary_water`
- `dietary_cholesterol`, `dietary_calcium`, `dietary_iron`
- `dietary_potassium`, `dietary_caffeine`
- Vitamins: `dietary_vitamin_c`, `dietary_vitamin_d`

**Example queries after Phase 1:**
```sql
-- Daily calorie intake
SELECT sum(value) FROM dietary_energy WHERE date > today() - 7d GROUP BY day

-- Protein vs carbs ratio
SELECT sum(value) FROM dietary_protein WHERE date > today()
```

---

### Phase 2: Comprehensive Symptoms

**Goal**: Enable full symptom tracking for health monitoring apps

Add 30+ symptom category types:

- **Digestive**: `nausea`, `vomiting`, `diarrhea`, `constipation`, `bloating`, `heartburn`
- **Pain**: `abdominal_cramps`, `chest_pain`, `lower_back_pain`, `pelvic_pain`, `breast_pain`
- **Respiratory**: `coughing`, `wheezing`, `shortness_of_breath`, `sinus_congestion`, `sore_throat`
- **General**: `fever`, `chills`, `dizziness`, `fainting`
- **Neurological**: `memory_lapse`, `mood_changes`
- **Skin**: `acne`, `dry_skin`, `hair_loss`
- **Cardiovascular**: `rapid_heartbeat`, `skipped_heartbeat`

**Example queries after Phase 2:**
```sql
-- Track headache frequency by severity
SELECT severity, count(*) FROM headache WHERE date > today() - 30d GROUP BY day

-- Correlate symptoms
SELECT * FROM fever WHERE date > today() - 7d
```

---

### Phase 3: Reproductive Health

**Goal**: Complete menstrual and reproductive health tracking

Add reproductive category types:
- `cervical_mucus_quality`, `ovulation_test_result`, `intermenstrual_bleeding`
- `sexual_activity`, `pregnancy`, `lactation`, `contraceptive`
- `pregnancy_test_result`, `progesterone_test_result`
- Cycle patterns: `infrequent_menstrual_cycles`, `irregular_menstrual_cycles`, `prolonged_menstrual_periods`

---

### Phase 4: Extended Vitals & Fitness

**Goal**: Round out vital signs and fitness metrics

Add quantity types:
- **Vitals**: `resting_heart_rate`, `walking_heart_rate_average`, `basal_body_temperature`
- **Fitness**: `vo2_max`, `distance_swimming`, `swimming_stroke_count`
- **Body**: `lean_body_mass`, `body_mass_index`, `waist_circumference`

**Example queries after Phase 4:**
```sql
-- VO2 Max trend over time
SELECT avg(value) FROM vo2_max WHERE date > today() - 90d GROUP BY month

-- Resting heart rate trend
SELECT avg(value) FROM resting_heart_rate WHERE date > today() - 30d GROUP BY week
```

---

### Phase 5: Complete Workout Types

**Goal**: Support all 84 HealthKit workout activity types

Add remaining ~70 workout types:
- **Ball Sports**: `tennis`, `golf`, `basketball`, `soccer`, `volleyball`, `baseball`
- **Combat**: `boxing`, `martial_arts`, `wrestling`, `fencing`, `kickboxing`
- **Water**: `water_polo`, `water_fitness`, `sailing`, `surfing`, `underwater_diving`
- **Winter**: `skiing`, `snowboarding`, `cross_country_skiing`
- **Mind/Body**: `pilates`, `tai_chi`, `barre`, `flexibility`
- **Other**: `climbing`, `fishing`, `golf`, `equestrian_sports`, `fitness_gaming`

---

### Phase 6: Health Events & Alerts

**Goal**: Support HealthKit event notifications

Add event category types:
- `high_heart_rate_event`, `low_heart_rate_event`, `irregular_heart_rhythm_event`
- `low_cardio_fitness_event`, `apple_walking_steadiness_event`
- `audio_exposure_event`, `headphone_audio_exposure_event`
- `sleep_apnea_event` (iOS 18+)

---

### Phase 7: Characteristics

**Goal**: Support read-only user characteristics

Add characteristic types:
- `biological_sex`, `blood_type`, `date_of_birth`
- `fitzpatrick_skin_type`, `wheelchair_use`

**Example query after Phase 7:**
```sql
SELECT * FROM characteristics
```

---

### Phase 8: Advanced Data Types

**Goal**: Support complex HealthKit data structures

- **Electrocardiogram**: ECG waveform data and classifications
- **Clinical Records**: FHIR-based health records (requires special entitlements)
- **Correlations**: Grouped samples (e.g., blood pressure readings)

---

## Coverage Targets by Phase

| Phase | Quantity Types | Category Types | Workout Types |
|-------|---------------|----------------|---------------|
| Current | 18 (22%) | 5 (7%) | 12 (14%) |
| Phase 1 | 33 (41%) | 5 (7%) | 12 (14%) |
| Phase 2 | 33 (41%) | 35 (50%) | 12 (14%) |
| Phase 3 | 33 (41%) | 50 (71%) | 12 (14%) |
| Phase 4 | 50 (63%) | 50 (71%) | 12 (14%) |
| Phase 5 | 50 (63%) | 50 (71%) | 84 (100%) |
| Phase 6 | 50 (63%) | 60 (86%) | 84 (100%) |
| Phase 7 | 50 (63%) | 60 (86%) | 84 (100%) |
| Phase 8 | 60+ (75%) | 65+ (93%) | 84 (100%) |

---

## Contributing

Want to help expand HealthKit coverage? Contributions are welcome! See the [Contributing Guide](contributing.md) for details.

Priority areas for contribution:
1. Adding new quantity types to `QuantityType.swift`
2. Adding new category types to `CategoryType.swift`
3. Adding new workout types to `WorkoutType.swift`
4. Writing tests for new types

---

## Sources

- [HKQuantityTypeIdentifier - Apple Developer](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier)
- [HKCategoryTypeIdentifier - Apple Developer](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier)
- [HKWorkoutActivityType - Apple Developer](https://developer.apple.com/documentation/healthkit/hkworkoutactivitytype)
