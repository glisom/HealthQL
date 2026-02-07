// Mock for expo-modules-core used in unit tests

export const Platform = {
  OS: 'ios',
};

// Mock native module that can be configured in tests
export const mockHealthQLModule = {
  query: jest.fn(),
  requestAuthorization: jest.fn(),
  getAuthorizationStatus: jest.fn(),
};

export const requireNativeModule = jest.fn((name: string) => {
  if (name === 'HealthQL') {
    return mockHealthQLModule;
  }
  throw new Error(`Unknown native module: ${name}`);
});

// Helper to reset all mocks between tests
export const resetMocks = () => {
  mockHealthQLModule.query.mockReset();
  mockHealthQLModule.requestAuthorization.mockReset();
  mockHealthQLModule.getAuthorizationStatus.mockReset();
};

// Helper to simulate Android platform
export const setPlatform = (os: 'ios' | 'android') => {
  (Platform as any).OS = os;
};
