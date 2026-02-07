/**
 * Error codes returned by HealthQL operations
 */
export type HealthQLErrorCode =
  | 'AUTHORIZATION_DENIED'
  | 'AUTHORIZATION_REQUIRED'
  | 'PARSE_ERROR'
  | 'UNKNOWN_TYPE'
  | 'UNKNOWN_FIELD'
  | 'INVALID_AGGREGATION'
  | 'HEALTHKIT_ERROR'
  | 'PLATFORM_NOT_SUPPORTED';

/**
 * Additional error details
 */
export interface HealthQLErrorDetails {
  /** Line number for parse errors */
  line?: number;
  /** Column number for parse errors */
  column?: number;
  /** Suggestion for typo corrections */
  suggestion?: string;
}

/**
 * Error class for HealthQL operations
 */
export class HealthQLError extends Error {
  /** Error code for programmatic handling */
  readonly code: HealthQLErrorCode;
  /** Additional error details */
  readonly details?: HealthQLErrorDetails;

  constructor(
    code: HealthQLErrorCode,
    message: string,
    details?: HealthQLErrorDetails
  ) {
    super(message);
    this.name = 'HealthQLError';
    this.code = code;
    this.details = details;

    // Maintains proper stack trace for where error was thrown (V8 only)
    const ErrorWithCapture = Error as typeof Error & {
      captureStackTrace?: (target: object, constructor: Function) => void;
    };
    if (ErrorWithCapture.captureStackTrace) {
      ErrorWithCapture.captureStackTrace(this, HealthQLError);
    }
  }

  /**
   * Create a HealthQLError from a native error object
   */
  static fromNativeError(nativeError: {
    code?: string;
    message?: string;
    details?: HealthQLErrorDetails;
  }): HealthQLError {
    const code = (nativeError.code as HealthQLErrorCode) || 'HEALTHKIT_ERROR';
    const message = nativeError.message || 'An unknown error occurred';
    return new HealthQLError(code, message, nativeError.details);
  }
}
