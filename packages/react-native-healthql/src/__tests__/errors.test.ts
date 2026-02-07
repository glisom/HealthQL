import { HealthQLError } from '../errors';
import type { HealthQLErrorCode } from '../errors';

describe('HealthQLError', () => {
  describe('constructor', () => {
    it('creates an error with code and message', () => {
      const error = new HealthQLError('PARSE_ERROR', 'Invalid syntax');

      expect(error).toBeInstanceOf(Error);
      expect(error).toBeInstanceOf(HealthQLError);
      expect(error.code).toBe('PARSE_ERROR');
      expect(error.message).toBe('Invalid syntax');
      expect(error.name).toBe('HealthQLError');
    });

    it('creates an error with details', () => {
      const error = new HealthQLError('PARSE_ERROR', 'Unexpected token', {
        line: 1,
        column: 15,
      });

      expect(error.details).toEqual({ line: 1, column: 15 });
    });

    it('creates an error with suggestion in details', () => {
      const error = new HealthQLError('UNKNOWN_TYPE', "Unknown type 'hart_rate'", {
        suggestion: "Did you mean 'heart_rate'?",
      });

      expect(error.details?.suggestion).toBe("Did you mean 'heart_rate'?");
    });
  });

  describe('fromNativeError', () => {
    it('converts a native error object', () => {
      const nativeError = {
        code: 'AUTHORIZATION_DENIED',
        message: 'User denied access',
      };

      const error = HealthQLError.fromNativeError(nativeError);

      expect(error.code).toBe('AUTHORIZATION_DENIED');
      expect(error.message).toBe('User denied access');
    });

    it('handles missing code with fallback', () => {
      const nativeError = {
        message: 'Something went wrong',
      };

      const error = HealthQLError.fromNativeError(nativeError);

      expect(error.code).toBe('HEALTHKIT_ERROR');
    });

    it('handles missing message with fallback', () => {
      const nativeError = {
        code: 'PARSE_ERROR',
      };

      const error = HealthQLError.fromNativeError(nativeError);

      expect(error.message).toBe('An unknown error occurred');
    });

    it('preserves details from native error', () => {
      const nativeError = {
        code: 'PARSE_ERROR',
        message: 'Syntax error',
        details: { line: 2, column: 10 },
      };

      const error = HealthQLError.fromNativeError(nativeError);

      expect(error.details).toEqual({ line: 2, column: 10 });
    });
  });

  describe('error codes', () => {
    const errorCodes: HealthQLErrorCode[] = [
      'AUTHORIZATION_DENIED',
      'AUTHORIZATION_REQUIRED',
      'PARSE_ERROR',
      'UNKNOWN_TYPE',
      'UNKNOWN_FIELD',
      'INVALID_AGGREGATION',
      'HEALTHKIT_ERROR',
      'PLATFORM_NOT_SUPPORTED',
    ];

    it.each(errorCodes)('accepts %s as a valid error code', (code) => {
      const error = new HealthQLError(code, 'Test message');
      expect(error.code).toBe(code);
    });
  });
});
