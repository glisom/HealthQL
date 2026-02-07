/**
 * Quantity health types that return numeric values with units.
 * These names match the SQL table names used in queries.
 */
export type QuantityType =
  | 'steps'
  | 'heart_rate'
  | 'active_calories'
  | 'resting_calories'
  | 'distance'
  | 'flights_climbed'
  | 'stand_time'
  | 'exercise_minutes'
  | 'body_mass'
  | 'height'
  | 'body_fat_percentage'
  | 'heart_rate_variability'
  | 'oxygen_saturation'
  | 'respiratory_rate'
  | 'body_temperature'
  | 'blood_pressure_systolic'
  | 'blood_pressure_diastolic'
  | 'blood_glucose';

/**
 * Category health types that return discrete values.
 * These names match the SQL table names used in queries.
 */
export type CategoryType =
  | 'sleep_analysis'
  | 'appetite_changes'
  | 'headache'
  | 'fatigue'
  | 'menstrual_flow';

/**
 * Special health types with custom result structures
 */
export type SpecialType = 'workouts' | 'sleep_sessions';

/**
 * All available health types
 */
export type HealthType = QuantityType | CategoryType | SpecialType;

/**
 * Result row for quantity-based queries
 */
export interface QuantityRow {
  /** ISO 8601 date string */
  date: string;
  /** Numeric value */
  value: number;
  /** Unit of measurement (e.g., 'bpm', 'count', 'kg') */
  unit: string;
}

/**
 * Result row for category-based queries
 */
export interface CategoryRow {
  /** ISO 8601 date string */
  date: string;
  /** Category value (e.g., 'asleep', 'mild', 'moderate') */
  value: string;
  /** Duration in seconds, when applicable */
  duration?: number;
}

/**
 * Result row for workout queries
 */
export interface WorkoutRow {
  /** ISO 8601 date string */
  date: string;
  /** Workout type (e.g., 'running', 'cycling') */
  type: string;
  /** Duration in seconds */
  duration: number;
  /** Calories burned */
  calories: number;
  /** Distance in meters, if applicable */
  distance?: number;
}

/**
 * Result row for sleep session queries
 */
export interface SleepSessionRow {
  /** ISO 8601 date string */
  date: string;
  /** Total sleep duration in seconds */
  duration: number;
  /** Time spent in each sleep stage (seconds) */
  stages: {
    awake: number;
    rem: number;
    core: number;
    deep: number;
  };
}

/**
 * Union of all result row types
 */
export type ResultRow = QuantityRow | CategoryRow | WorkoutRow | SleepSessionRow;

/**
 * Columnar result format for performance-critical use cases
 */
export interface ColumnarResult {
  /** Column names */
  columns: string[];
  /** Row data as arrays */
  rows: (string | number | null)[][];
}

/**
 * Query options
 */
export interface QueryOptions {
  /** Result format: 'rows' (default) or 'columnar' */
  format?: 'rows' | 'columnar';
}

/**
 * Authorization request options
 */
export interface AuthorizationOptions {
  /** Health types to request read access for */
  read: HealthType[];
}

/**
 * Authorization status for a health type
 */
export type AuthorizationStatus = 'notDetermined' | 'authorized' | 'denied';

/**
 * Field information for schema introspection
 */
export interface FieldInfo {
  /** Field name */
  name: string;
  /** Field type */
  type: 'number' | 'string' | 'Date' | 'boolean';
}

/**
 * Schema information for all health types
 */
export interface Schema {
  /** Available quantity types */
  quantityTypes: QuantityType[];
  /** Available category types */
  categoryTypes: CategoryType[];
  /** Available special types */
  specialTypes: SpecialType[];
}
