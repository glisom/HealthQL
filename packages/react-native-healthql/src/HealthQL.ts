import { requireNativeModule, Platform } from 'expo-modules-core';
import { HealthQLError } from './errors';
import type {
  HealthType,
  QuantityType,
  CategoryType,
  SpecialType,
  ResultRow,
  ColumnarResult,
  QueryOptions,
  AuthorizationOptions,
  AuthorizationStatus,
  FieldInfo,
  Schema,
} from './types';

// Native module (only available on iOS)
const HealthQLModule = Platform.OS === 'ios'
  ? requireNativeModule('HealthQL')
  : null;

/**
 * All available quantity types (matches Swift QuantityType.displayName)
 */
const QUANTITY_TYPES: QuantityType[] = [
  'steps',
  'heart_rate',
  'active_calories',
  'resting_calories',
  'distance',
  'flights_climbed',
  'stand_time',
  'exercise_minutes',
  'body_mass',
  'height',
  'body_fat_percentage',
  'heart_rate_variability',
  'oxygen_saturation',
  'respiratory_rate',
  'body_temperature',
  'blood_pressure_systolic',
  'blood_pressure_diastolic',
  'blood_glucose',
];

/**
 * All available category types (matches Swift CategoryType.displayName)
 */
const CATEGORY_TYPES: CategoryType[] = [
  'sleep_analysis',
  'appetite_changes',
  'headache',
  'fatigue',
  'menstrual_flow',
];

/**
 * All available special types
 */
const SPECIAL_TYPES: SpecialType[] = ['workouts', 'sleep_sessions'];

/**
 * Field definitions for each health type
 */
const TYPE_FIELDS: Record<HealthType, FieldInfo[]> = {
  // Quantity types share common fields
  ...Object.fromEntries(
    QUANTITY_TYPES.map((type) => [
      type,
      [
        { name: 'date', type: 'Date' as const },
        { name: 'value', type: 'number' as const },
        { name: 'unit', type: 'string' as const },
      ],
    ])
  ),
  // Category types
  ...Object.fromEntries(
    CATEGORY_TYPES.map((type) => [
      type,
      [
        { name: 'date', type: 'Date' as const },
        { name: 'value', type: 'string' as const },
        { name: 'duration', type: 'number' as const },
      ],
    ])
  ),
  // Special types
  workouts: [
    { name: 'date', type: 'Date' as const },
    { name: 'type', type: 'string' as const },
    { name: 'duration', type: 'number' as const },
    { name: 'calories', type: 'number' as const },
    { name: 'distance', type: 'number' as const },
  ],
  sleep_sessions: [
    { name: 'date', type: 'Date' as const },
    { name: 'duration', type: 'number' as const },
    { name: 'stages', type: 'string' as const },
  ],
} as Record<HealthType, FieldInfo[]>;

/**
 * Throws PLATFORM_NOT_SUPPORTED error for non-iOS platforms
 */
function assertiOS(): void {
  if (Platform.OS !== 'ios') {
    throw new HealthQLError(
      'PLATFORM_NOT_SUPPORTED',
      'HealthQL is only available on iOS. Android support is not yet implemented.'
    );
  }
}

/**
 * HealthQL - SQL-like query interface for Apple HealthKit
 */
export const HealthQL = {
  /**
   * Execute a SQL-like query against HealthKit data
   *
   * @param sql - SQL query string (e.g., "SELECT avg(value) FROM heart_rate WHERE date > today() - 7d")
   * @param options - Query options
   * @returns Promise resolving to query results
   *
   * @example
   * ```typescript
   * const results = await HealthQL.query(
   *   'SELECT avg(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day'
   * );
   * ```
   */
  async query(
    sql: string,
    options?: QueryOptions
  ): Promise<ResultRow[] | ColumnarResult> {
    assertiOS();
    try {
      return await HealthQLModule!.query(sql, options ?? {});
    } catch (error: unknown) {
      throw HealthQLError.fromNativeError(error as Record<string, unknown>);
    }
  },

  /**
   * Request authorization to read health data
   *
   * @param options - Authorization options specifying which types to request
   * @returns Promise that resolves when the authorization prompt completes
   *
   * @example
   * ```typescript
   * await HealthQL.requestAuthorization({
   *   read: ['heart_rate', 'steps', 'sleep_analysis'],
   * });
   * ```
   */
  async requestAuthorization(options: AuthorizationOptions): Promise<void> {
    assertiOS();
    try {
      await HealthQLModule!.requestAuthorization(options.read);
    } catch (error: unknown) {
      throw HealthQLError.fromNativeError(error as Record<string, unknown>);
    }
  },

  /**
   * Check the authorization status for a specific health type
   *
   * @param type - Health type to check
   * @returns Promise resolving to the authorization status
   *
   * @example
   * ```typescript
   * const status = await HealthQL.getAuthorizationStatus('heart_rate');
   * if (status === 'denied') {
   *   // Show prompt to enable in Settings
   * }
   * ```
   */
  async getAuthorizationStatus(type: HealthType): Promise<AuthorizationStatus> {
    assertiOS();
    try {
      return await HealthQLModule!.getAuthorizationStatus(type);
    } catch (error: unknown) {
      throw HealthQLError.fromNativeError(error as Record<string, unknown>);
    }
  },

  /**
   * Get all available health types
   *
   * @returns Array of all health type identifiers
   *
   * @example
   * ```typescript
   * const types = HealthQL.getTypes();
   * // ['heart_rate', 'steps', 'weight', ...]
   * ```
   */
  getTypes(): HealthType[] {
    return [...QUANTITY_TYPES, ...CATEGORY_TYPES, ...SPECIAL_TYPES];
  },

  /**
   * Get field information for a specific health type
   *
   * @param type - Health type to get fields for
   * @returns Array of field information objects
   *
   * @example
   * ```typescript
   * const fields = HealthQL.getFields('heart_rate');
   * // [{ name: 'value', type: 'number' }, { name: 'date', type: 'Date' }, ...]
   * ```
   */
  getFields(type: HealthType): FieldInfo[] {
    return TYPE_FIELDS[type] ?? [];
  },

  /**
   * Get the full schema for all health types
   *
   * @returns Schema object with all type information
   *
   * @example
   * ```typescript
   * const schema = HealthQL.getSchema();
   * // { quantityTypes: [...], categoryTypes: [...], specialTypes: [...] }
   * ```
   */
  getSchema(): Schema {
    return {
      quantityTypes: [...QUANTITY_TYPES],
      categoryTypes: [...CATEGORY_TYPES],
      specialTypes: [...SPECIAL_TYPES],
    };
  },
};
