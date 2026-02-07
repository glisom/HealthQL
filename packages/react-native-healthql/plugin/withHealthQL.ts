import {
  ConfigPlugin,
  withEntitlementsPlist,
  withInfoPlist,
  IOSConfig,
} from 'expo/config-plugins';

/**
 * Plugin options for react-native-healthql
 */
export interface HealthQLPluginOptions {
  /**
   * The description shown to users when requesting health data access.
   * Required by Apple for HealthKit apps.
   */
  healthShareUsageDescription?: string;

  /**
   * Enable background delivery of health data updates.
   * When true, adds HealthKit background modes.
   * @default false
   */
  backgroundDelivery?: boolean;
}

const DEFAULT_HEALTH_SHARE_DESCRIPTION =
  'This app uses your health data to provide personalized insights.';

/**
 * Expo config plugin for react-native-healthql
 *
 * Automatically configures:
 * - HealthKit entitlement
 * - NSHealthShareUsageDescription in Info.plist
 * - Optional background modes for health data delivery
 */
const withHealthQL: ConfigPlugin<HealthQLPluginOptions | void> = (
  config,
  options = {}
) => {
  const {
    healthShareUsageDescription = DEFAULT_HEALTH_SHARE_DESCRIPTION,
    backgroundDelivery = false,
  } = options ?? {};

  // Add HealthKit entitlement
  config = withEntitlementsPlist(config, (config) => {
    config.modResults['com.apple.developer.healthkit'] = true;

    // Add healthkit capabilities array if using background delivery
    if (backgroundDelivery) {
      config.modResults['com.apple.developer.healthkit.access'] = [];
    }

    return config;
  });

  // Add Info.plist entries
  config = withInfoPlist(config, (config) => {
    // Required: Health share usage description
    config.modResults.NSHealthShareUsageDescription = healthShareUsageDescription;

    // Add UIBackgroundModes for background health delivery
    if (backgroundDelivery) {
      const existingModes = config.modResults.UIBackgroundModes ?? [];
      if (!existingModes.includes('processing')) {
        config.modResults.UIBackgroundModes = [...existingModes, 'processing'];
      }
    }

    return config;
  });

  return config;
};

export default withHealthQL;
