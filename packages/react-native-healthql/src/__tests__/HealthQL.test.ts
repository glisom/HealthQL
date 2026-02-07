import {
  mockHealthQLModule,
  resetMocks,
  setPlatform,
} from './__mocks__/expo-modules-core';
import { HealthQL } from '../HealthQL';
import { HealthQLError } from '../errors';

describe('HealthQL', () => {
  beforeEach(() => {
    resetMocks();
    setPlatform('ios');
  });

  describe('query', () => {
    it('executes a query and returns results', async () => {
      const mockResults = [
        { date: '2024-01-15T00:00:00Z', value: 72, unit: 'bpm' },
        { date: '2024-01-16T00:00:00Z', value: 68, unit: 'bpm' },
      ];
      mockHealthQLModule.query.mockResolvedValue(mockResults);

      const results = await HealthQL.query('SELECT * FROM heart_rate LIMIT 2');

      expect(mockHealthQLModule.query).toHaveBeenCalledWith(
        'SELECT * FROM heart_rate LIMIT 2',
        {}
      );
      expect(results).toEqual(mockResults);
    });

    it('passes format option to native module', async () => {
      mockHealthQLModule.query.mockResolvedValue({
        columns: ['date', 'value'],
        rows: [],
      });

      await HealthQL.query('SELECT * FROM steps', { format: 'columnar' });

      expect(mockHealthQLModule.query).toHaveBeenCalledWith(
        'SELECT * FROM steps',
        { format: 'columnar' }
      );
    });

    it('throws HealthQLError on native error', async () => {
      mockHealthQLModule.query.mockRejectedValue({
        code: 'PARSE_ERROR',
        message: 'Invalid syntax',
      });

      await expect(HealthQL.query('SELECT * FROM invalid')).rejects.toThrow(
        HealthQLError
      );
    });

    it('throws PLATFORM_NOT_SUPPORTED on Android', async () => {
      setPlatform('android');

      await expect(HealthQL.query('SELECT * FROM steps')).rejects.toThrow(
        HealthQLError
      );

      try {
        await HealthQL.query('SELECT * FROM steps');
      } catch (error) {
        expect((error as HealthQLError).code).toBe('PLATFORM_NOT_SUPPORTED');
      }
    });
  });

  describe('requestAuthorization', () => {
    it('requests authorization for specified types', async () => {
      mockHealthQLModule.requestAuthorization.mockResolvedValue(undefined);

      await HealthQL.requestAuthorization({
        read: ['heart_rate', 'steps'],
      });

      expect(mockHealthQLModule.requestAuthorization).toHaveBeenCalledWith([
        'heart_rate',
        'steps',
      ]);
    });

    it('throws HealthQLError on authorization failure', async () => {
      mockHealthQLModule.requestAuthorization.mockRejectedValue({
        code: 'AUTHORIZATION_DENIED',
        message: 'User denied access',
      });

      await expect(
        HealthQL.requestAuthorization({ read: ['heart_rate'] })
      ).rejects.toThrow(HealthQLError);
    });
  });

  describe('getAuthorizationStatus', () => {
    it('returns authorization status for a type', async () => {
      mockHealthQLModule.getAuthorizationStatus.mockResolvedValue('authorized');

      const status = await HealthQL.getAuthorizationStatus('heart_rate');

      expect(mockHealthQLModule.getAuthorizationStatus).toHaveBeenCalledWith(
        'heart_rate'
      );
      expect(status).toBe('authorized');
    });

    it.each(['notDetermined', 'authorized', 'denied'] as const)(
      'returns %s status',
      async (expectedStatus) => {
        mockHealthQLModule.getAuthorizationStatus.mockResolvedValue(expectedStatus);

        const status = await HealthQL.getAuthorizationStatus('steps');

        expect(status).toBe(expectedStatus);
      }
    );
  });

  describe('getTypes', () => {
    it('returns all health types', () => {
      const types = HealthQL.getTypes();

      expect(types).toContain('heart_rate');
      expect(types).toContain('steps');
      expect(types).toContain('sleep_analysis');
      expect(types).toContain('workouts');
      expect(types.length).toBeGreaterThan(0);
    });

    it('is a synchronous function', () => {
      // Should not return a Promise
      const result = HealthQL.getTypes();
      expect(result).not.toBeInstanceOf(Promise);
      expect(Array.isArray(result)).toBe(true);
    });
  });

  describe('getFields', () => {
    it('returns fields for quantity types', () => {
      const fields = HealthQL.getFields('heart_rate');

      expect(fields).toContainEqual({ name: 'date', type: 'Date' });
      expect(fields).toContainEqual({ name: 'value', type: 'number' });
      expect(fields).toContainEqual({ name: 'unit', type: 'string' });
    });

    it('returns fields for category types', () => {
      const fields = HealthQL.getFields('sleep_analysis');

      expect(fields).toContainEqual({ name: 'date', type: 'Date' });
      expect(fields).toContainEqual({ name: 'value', type: 'string' });
    });

    it('returns fields for workouts', () => {
      const fields = HealthQL.getFields('workouts');

      expect(fields).toContainEqual({ name: 'duration', type: 'number' });
      expect(fields).toContainEqual({ name: 'calories', type: 'number' });
      expect(fields).toContainEqual({ name: 'type', type: 'string' });
    });

    it('returns empty array for unknown type', () => {
      const fields = HealthQL.getFields('unknown_type' as any);
      expect(fields).toEqual([]);
    });
  });

  describe('getSchema', () => {
    it('returns schema with all type categories', () => {
      const schema = HealthQL.getSchema();

      expect(schema.quantityTypes).toContain('heart_rate');
      expect(schema.quantityTypes).toContain('steps');
      expect(schema.categoryTypes).toContain('sleep_analysis');
      expect(schema.specialTypes).toContain('workouts');
      expect(schema.specialTypes).toContain('sleep_sessions');
    });

    it('returns arrays that are not the same reference as internal state', () => {
      const schema1 = HealthQL.getSchema();
      const schema2 = HealthQL.getSchema();

      expect(schema1.quantityTypes).not.toBe(schema2.quantityTypes);
      expect(schema1.categoryTypes).not.toBe(schema2.categoryTypes);
      expect(schema1.specialTypes).not.toBe(schema2.specialTypes);
    });
  });
});
