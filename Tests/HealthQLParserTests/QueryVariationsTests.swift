import Testing
@testable import HealthQLParser
@testable import HealthQL

@Suite("Query Variations - Quantity Types")
struct QuantityQueryVariationsTests {

    // MARK: - Heart Rate Queries

    @Test("Heart rate - simple select all")
    func heartRateSelectAll() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate")
        #expect(query.source == .quantity(.heartRate))
    }

    @Test("Heart rate - select specific fields")
    func heartRateSelectFields() throws {
        let query = try HQL.parse("SELECT value, date FROM heart_rate")
        #expect(query.selections.count == 2)
    }

    @Test("Heart rate - average aggregation")
    func heartRateAvg() throws {
        let query = try HQL.parse("SELECT avg(value) FROM heart_rate")
        #expect(query.selections.count == 1)
        #expect(query.selections[0] == .aggregate(.avg, .value))
    }

    @Test("Heart rate - multiple aggregations")
    func heartRateMultipleAggs() throws {
        let query = try HQL.parse("SELECT avg(value), min(value), max(value) FROM heart_rate")
        #expect(query.selections.count == 3)
    }

    @Test("Heart rate - with date filter")
    func heartRateDateFilter() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE date > today() - 7d")
        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
    }

    @Test("Heart rate - grouped by day")
    func heartRateGroupByDay() throws {
        let query = try HQL.parse("SELECT avg(value) FROM heart_rate GROUP BY day")
        #expect(query.grouping == .day)
    }

    @Test("Heart rate - grouped by hour")
    func heartRateGroupByHour() throws {
        let query = try HQL.parse("SELECT avg(value) FROM heart_rate GROUP BY hour")
        #expect(query.grouping == .hour)
    }

    @Test("Heart rate - grouped by week")
    func heartRateGroupByWeek() throws {
        let query = try HQL.parse("SELECT avg(value) FROM heart_rate GROUP BY week")
        #expect(query.grouping == .week)
    }

    @Test("Heart rate - grouped by month")
    func heartRateGroupByMonth() throws {
        let query = try HQL.parse("SELECT avg(value) FROM heart_rate GROUP BY month")
        #expect(query.grouping == .month)
    }

    @Test("Heart rate - order by date descending")
    func heartRateOrderDesc() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate ORDER BY date DESC")
        #expect(query.ordering?.count == 1)
        #expect(query.ordering?[0].direction == .descending)
    }

    @Test("Heart rate - order by date ascending")
    func heartRateOrderAsc() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate ORDER BY date ASC")
        #expect(query.ordering?[0].direction == .ascending)
    }

    @Test("Heart rate - with limit")
    func heartRateLimit() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate LIMIT 10")
        #expect(query.limit == 10)
    }

    @Test("Heart rate - complex query")
    func heartRateComplex() throws {
        let query = try HQL.parse("""
            SELECT avg(value), min(value), max(value)
            FROM heart_rate
            WHERE date > today() - 30d
            GROUP BY day
            ORDER BY date DESC
            LIMIT 30
        """)
        #expect(query.selections.count == 3)
        #expect(query.predicates.count == 1)
        #expect(query.grouping == .day)
        #expect(query.ordering?.count == 1)
        #expect(query.limit == 30)
    }

    // MARK: - Steps Queries

    @Test("Steps - sum aggregation")
    func stepsSum() throws {
        let query = try HQL.parse("SELECT sum(count) FROM steps")
        #expect(query.source == .quantity(.steps))
        #expect(query.selections[0] == .aggregate(.sum, .value))
    }

    @Test("Steps - count aggregation")
    func stepsCount() throws {
        let query = try HQL.parse("SELECT count(value) FROM steps")
        #expect(query.selections[0] == .aggregate(.count, .value))
    }

    @Test("Steps - daily totals")
    func stepsDailyTotals() throws {
        let query = try HQL.parse("SELECT sum(count) FROM steps WHERE date > today() - 7d GROUP BY day")
        #expect(query.grouping == .day)
    }

    @Test("Steps - weekly totals")
    func stepsWeeklyTotals() throws {
        let query = try HQL.parse("SELECT sum(count) FROM steps WHERE date > today() - 30d GROUP BY week")
        #expect(query.grouping == .week)
    }

    @Test("Steps - monthly totals")
    func stepsMonthlyTotals() throws {
        let query = try HQL.parse("SELECT sum(count) FROM steps WHERE date > start_of_year() GROUP BY month")
        #expect(query.grouping == .month)
    }

    // MARK: - Active Calories Queries

    @Test("Active calories - daily sum")
    func activeCaloriesDailySum() throws {
        let query = try HQL.parse("SELECT sum(value) FROM active_calories WHERE date > today() - 7d GROUP BY day")
        #expect(query.source == .quantity(.activeCalories))
    }

    @Test("Active calories - with date range")
    func activeCaloriesDateRange() throws {
        let query = try HQL.parse("SELECT sum(value) FROM active_calories WHERE date > start_of_month()")
        #expect(query.predicates.count == 1)
    }

    // MARK: - Distance Queries

    @Test("Distance - daily sum")
    func distanceDailySum() throws {
        let query = try HQL.parse("SELECT sum(value) FROM distance WHERE date > today() - 7d GROUP BY day")
        #expect(query.source == .quantity(.distance))
    }

    // MARK: - Other Quantity Types

    @Test("Heart rate variability - average")
    func heartRateVariability() throws {
        let query = try HQL.parse("SELECT avg(value) FROM heart_rate_variability GROUP BY day")
        #expect(query.source == .quantity(.heartRateVariability))
    }

    @Test("Oxygen saturation - select all")
    func oxygenSaturation() throws {
        let query = try HQL.parse("SELECT * FROM oxygen_saturation")
        #expect(query.source == .quantity(.oxygenSaturation))
    }

    @Test("Body mass - latest")
    func bodyMass() throws {
        let query = try HQL.parse("SELECT value, date FROM body_mass ORDER BY date DESC LIMIT 1")
        #expect(query.source == .quantity(.bodyMass))
        #expect(query.limit == 1)
    }

    @Test("Body fat percentage - trend")
    func bodyFatPercentage() throws {
        let query = try HQL.parse("SELECT avg(value) FROM body_fat_percentage GROUP BY week")
        #expect(query.source == .quantity(.bodyFatPercentage))
    }

    @Test("Height - latest reading")
    func height() throws {
        let query = try HQL.parse("SELECT value FROM height ORDER BY date DESC LIMIT 1")
        #expect(query.source == .quantity(.height))
    }

    @Test("Respiratory rate - average")
    func respiratoryRate() throws {
        let query = try HQL.parse("SELECT avg(value) FROM respiratory_rate WHERE date > today() - 7d")
        #expect(query.source == .quantity(.respiratoryRate))
    }

    @Test("Resting calories - daily sum")
    func restingCalories() throws {
        let query = try HQL.parse("SELECT sum(value) FROM resting_calories GROUP BY day")
        #expect(query.source == .quantity(.restingCalories))
    }

    @Test("Flights climbed - sum")
    func flightsClimbed() throws {
        let query = try HQL.parse("SELECT sum(value) FROM flights_climbed WHERE date > today() - 7d GROUP BY day")
        #expect(query.source == .quantity(.flightsClimbed))
    }

    @Test("Stand time - daily")
    func standTime() throws {
        let query = try HQL.parse("SELECT sum(value) FROM stand_time WHERE date > today() - 7d GROUP BY day")
        #expect(query.source == .quantity(.standTime))
    }

    @Test("Exercise minutes - weekly")
    func exerciseMinutes() throws {
        let query = try HQL.parse("SELECT sum(value) FROM exercise_minutes WHERE date > today() - 30d GROUP BY week")
        #expect(query.source == .quantity(.exerciseMinutes))
    }

    @Test("Blood glucose - latest")
    func bloodGlucose() throws {
        let query = try HQL.parse("SELECT value, date FROM blood_glucose ORDER BY date DESC LIMIT 10")
        #expect(query.source == .quantity(.bloodGlucose))
    }

    @Test("Blood pressure systolic - trend")
    func bloodPressureSystolic() throws {
        let query = try HQL.parse("SELECT avg(value) FROM blood_pressure_systolic GROUP BY day")
        #expect(query.source == .quantity(.bloodPressureSystolic))
    }

    @Test("Blood pressure diastolic - trend")
    func bloodPressureDiastolic() throws {
        let query = try HQL.parse("SELECT avg(value) FROM blood_pressure_diastolic GROUP BY day")
        #expect(query.source == .quantity(.bloodPressureDiastolic))
    }

    @Test("Body temperature - latest")
    func bodyTemperature() throws {
        let query = try HQL.parse("SELECT * FROM body_temperature ORDER BY date DESC LIMIT 5")
        #expect(query.source == .quantity(.bodyTemperature))
    }
}

@Suite("Query Variations - Category Types")
struct CategoryQueryVariationsTests {

    @Test("Sleep analysis - select all")
    func sleepAnalysisSelectAll() throws {
        let query = try HQL.parse("SELECT * FROM sleep_analysis")
        #expect(query.source == .category(.sleepAnalysis))
    }

    @Test("Sleep analysis - with date filter")
    func sleepAnalysisDateFilter() throws {
        let query = try HQL.parse("SELECT * FROM sleep_analysis WHERE date > today() - 7d")
        #expect(query.predicates.count == 1)
    }

    @Test("Sleep analysis - ordered by date")
    func sleepAnalysisOrdered() throws {
        let query = try HQL.parse("SELECT * FROM sleep_analysis ORDER BY date DESC LIMIT 10")
        #expect(query.ordering?[0].direction == .descending)
    }

    @Test("Headache - select all")
    func headacheSelectAll() throws {
        let query = try HQL.parse("SELECT * FROM headache")
        #expect(query.source == .category(.headache))
    }

    @Test("Headache - count occurrences")
    func headacheCount() throws {
        let query = try HQL.parse("SELECT count(value) FROM headache WHERE date > today() - 30d")
        #expect(query.selections[0] == .aggregate(.count, .value))
    }

    @Test("Fatigue - recent entries")
    func fatigueRecent() throws {
        let query = try HQL.parse("SELECT * FROM fatigue WHERE date > today() - 14d ORDER BY date DESC")
        #expect(query.source == .category(.fatigue))
    }

    @Test("Appetite changes - monthly count")
    func appetiteChangesMonthly() throws {
        let query = try HQL.parse("SELECT count(value) FROM appetite_changes WHERE date > start_of_year() GROUP BY month")
        #expect(query.source == .category(.appetiteChanges))
        #expect(query.grouping == .month)
    }

    @Test("Menstrual flow - select all")
    func menstrualFlow() throws {
        let query = try HQL.parse("SELECT * FROM menstrual_flow WHERE date > today() - 30d")
        #expect(query.source == .category(.menstrualFlow))
    }
}

@Suite("Query Variations - Workout Types")
struct WorkoutQueryVariationsTests {

    @Test("Workouts - select all")
    func workoutsSelectAll() throws {
        let query = try HQL.parse("SELECT * FROM workouts")
        #expect(query.source == .workout)
    }

    @Test("Workouts - specific fields")
    func workoutsSpecificFields() throws {
        let query = try HQL.parse("SELECT duration, total_calories, activity_type FROM workouts")
        #expect(query.selections.count == 3)
    }

    @Test("Workouts - with limit")
    func workoutsWithLimit() throws {
        let query = try HQL.parse("SELECT * FROM workouts LIMIT 20")
        #expect(query.limit == 20)
    }

    @Test("Workouts - ordered descending")
    func workoutsOrderedDesc() throws {
        let query = try HQL.parse("SELECT duration, total_calories FROM workouts ORDER BY date DESC LIMIT 10")
        #expect(query.ordering?[0].direction == .descending)
    }

    @Test("Workouts - recent month")
    func workoutsRecentMonth() throws {
        let query = try HQL.parse("SELECT * FROM workouts WHERE date > today() - 30d ORDER BY date DESC")
        #expect(query.predicates.count == 1)
    }

    @Test("Workouts - sum calories")
    func workoutsSumCalories() throws {
        let query = try HQL.parse("SELECT sum(total_calories) FROM workouts WHERE date > today() - 7d")
        #expect(query.selections[0] == .aggregate(.sum, .totalCalories))
    }

    @Test("Workouts - sum duration")
    func workoutsSumDuration() throws {
        let query = try HQL.parse("SELECT sum(duration) FROM workouts WHERE date > start_of_month()")
        #expect(query.selections[0] == .aggregate(.sum, .duration))
    }

    @Test("Workouts - weekly aggregation")
    func workoutsWeeklyAgg() throws {
        let query = try HQL.parse("SELECT sum(total_calories), sum(duration) FROM workouts WHERE date > today() - 30d GROUP BY week")
        #expect(query.selections.count == 2)
        #expect(query.grouping == .week)
    }
}

@Suite("Query Variations - Sleep Sessions")
struct SleepSessionQueryVariationsTests {

    @Test("Sleep - select all")
    func sleepSelectAll() throws {
        let query = try HQL.parse("SELECT * FROM sleep")
        #expect(query.source == .sleepSession)
    }

    @Test("Sleep - with date filter")
    func sleepDateFilter() throws {
        let query = try HQL.parse("SELECT * FROM sleep WHERE date > today() - 7d")
        #expect(query.predicates.count == 1)
    }

    @Test("Sleep - ordered by date")
    func sleepOrdered() throws {
        let query = try HQL.parse("SELECT * FROM sleep ORDER BY date DESC LIMIT 30")
        #expect(query.limit == 30)
    }

    @Test("Sleep - duration field")
    func sleepDuration() throws {
        let query = try HQL.parse("SELECT duration FROM sleep WHERE date > today() - 30d")
        #expect(query.selections[0] == .field(.duration))
    }
}

@Suite("Query Variations - Date Functions")
struct DateFunctionQueryVariationsTests {

    @Test("today() function")
    func todayFunction() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE date > today()")
        #expect(query.predicates.count == 1)
    }

    @Test("today() minus days")
    func todayMinusDays() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE date > today() - 7d")
        #expect(query.predicates.count == 1)
    }

    @Test("today() minus weeks")
    func todayMinusWeeks() throws {
        let query = try HQL.parse("SELECT * FROM steps WHERE date > today() - 4w")
        #expect(query.predicates.count == 1)
    }

    @Test("today() minus months")
    func todayMinusMonths() throws {
        let query = try HQL.parse("SELECT * FROM active_calories WHERE date > today() - 3mo")
        #expect(query.predicates.count == 1)
    }

    @Test("today() minus years")
    func todayMinusYears() throws {
        let query = try HQL.parse("SELECT * FROM body_mass WHERE date > today() - 1y")
        #expect(query.predicates.count == 1)
    }

    @Test("today() as start of day")
    func todayAsStartOfDay() throws {
        // today() returns start of current day
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE date > today()")
        #expect(query.predicates.count == 1)
    }

    @Test("start_of_week() function")
    func startOfWeek() throws {
        let query = try HQL.parse("SELECT * FROM steps WHERE date > start_of_week()")
        #expect(query.predicates.count == 1)
    }

    @Test("start_of_month() function")
    func startOfMonth() throws {
        let query = try HQL.parse("SELECT * FROM active_calories WHERE date > start_of_month()")
        #expect(query.predicates.count == 1)
    }

    @Test("start_of_year() function")
    func startOfYear() throws {
        let query = try HQL.parse("SELECT * FROM workouts WHERE date > start_of_year()")
        #expect(query.predicates.count == 1)
    }
}

@Suite("Query Variations - Operators")
struct OperatorQueryVariationsTests {

    @Test("Greater than operator")
    func greaterThan() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value > 100")
        #expect(query.predicates[0].op == .greaterThan)
    }

    @Test("Greater than or equal operator")
    func greaterThanOrEqual() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value >= 100")
        #expect(query.predicates[0].op == .greaterThanOrEqual)
    }

    @Test("Less than operator")
    func lessThan() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value < 60")
        #expect(query.predicates[0].op == .lessThan)
    }

    @Test("Less than or equal operator")
    func lessThanOrEqual() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value <= 60")
        #expect(query.predicates[0].op == .lessThanOrEqual)
    }

    @Test("Equal operator")
    func equal() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value = 72")
        #expect(query.predicates[0].op == .equal)
    }

    @Test("Not equal operator with !=")
    func notEqualBang() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value != 0")
        #expect(query.predicates[0].op == .notEqual)
    }

    @Test("Not equal operator with <>")
    func notEqualAngle() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value <> 0")
        #expect(query.predicates[0].op == .notEqual)
    }

    @Test("IS NULL operator")
    func isNull() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE device IS NULL")
        #expect(query.predicates[0].op == .isNull)
    }

    @Test("IS NOT NULL operator")
    func isNotNull() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE device IS NOT NULL")
        #expect(query.predicates[0].op == .isNotNull)
    }

    @Test("AND in WHERE clause")
    func andOperator() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate WHERE value > 60 AND value < 100")
        #expect(query.predicates.count == 2)
    }
}

@Suite("Query Variations - Edge Cases")
struct EdgeCaseQueryVariationsTests {

    @Test("Case insensitive keywords - lowercase")
    func lowercaseKeywords() throws {
        let query = try HQL.parse("select * from heart_rate where date > today() - 7d group by day order by date desc limit 10")
        #expect(query.source == .quantity(.heartRate))
        #expect(query.grouping == .day)
    }

    @Test("Case insensitive keywords - SQL keywords only")
    func mixedCaseKeywords() throws {
        // SQL keywords are case-insensitive, but table names must match exactly
        let query = try HQL.parse("Select Avg(value) From heart_rate Group By Day")
        #expect(query.source == .quantity(.heartRate))
    }

    @Test("Large limit value")
    func largeLimitValue() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate LIMIT 10000")
        #expect(query.limit == 10000)
    }

    @Test("Zero limit value")
    func zeroLimitValue() throws {
        let query = try HQL.parse("SELECT * FROM heart_rate LIMIT 0")
        #expect(query.limit == 0)
    }

    @Test("Multiple spaces between keywords")
    func multipleSpaces() throws {
        let query = try HQL.parse("SELECT    *    FROM    heart_rate    LIMIT   10")
        #expect(query.source == .quantity(.heartRate))
    }

    @Test("Newlines in query")
    func newlinesInQuery() throws {
        let query = try HQL.parse("""
            SELECT *
            FROM heart_rate
            LIMIT 10
        """)
        #expect(query.source == .quantity(.heartRate))
    }

    @Test("All aggregation types in one query")
    func allAggregations() throws {
        let query = try HQL.parse("SELECT sum(value), avg(value), min(value), max(value), count(value) FROM steps GROUP BY day")
        #expect(query.selections.count == 5)
    }
}
