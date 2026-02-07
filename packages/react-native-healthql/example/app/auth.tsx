import { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import {
  HealthQL,
  HealthQLError,
  HealthType,
  AuthorizationStatus,
} from 'react-native-healthql';

const HEALTH_TYPES: HealthType[] = [
  'heart_rate',
  'steps',
  'active_calories',
  'distance',
  'body_mass',
  'sleep_analysis',
  'workouts',
];

export default function AuthScreen() {
  const [statuses, setStatuses] = useState<Record<string, AuthorizationStatus>>(
    {}
  );
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const checkAllStatuses = async () => {
    const newStatuses: Record<string, AuthorizationStatus> = {};
    for (const type of HEALTH_TYPES) {
      try {
        newStatuses[type] = await HealthQL.getAuthorizationStatus(type);
      } catch {
        newStatuses[type] = 'notDetermined';
      }
    }
    setStatuses(newStatuses);
  };

  useEffect(() => {
    checkAllStatuses();
  }, []);

  const requestAllAuthorization = async () => {
    setLoading(true);
    setError(null);

    try {
      await HealthQL.requestAuthorization({
        read: HEALTH_TYPES,
      });
      // Refresh statuses after authorization
      await checkAllStatuses();
    } catch (e) {
      if (e instanceof HealthQLError) {
        setError(`[${e.code}] ${e.message}`);
      } else {
        setError(String(e));
      }
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: AuthorizationStatus) => {
    switch (status) {
      case 'authorized':
        return '#4CAF50';
      case 'denied':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  };

  const getStatusIcon = (status: AuthorizationStatus) => {
    switch (status) {
      case 'authorized':
        return '✓';
      case 'denied':
        return '✗';
      default:
        return '?';
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>HealthKit Authorization</Text>

      <Text style={styles.description}>
        Request permission to read health data. iOS will show a system prompt
        where users can select which data types to share.
      </Text>

      <TouchableOpacity
        style={styles.button}
        onPress={requestAllAuthorization}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.buttonText}>Request Authorization</Text>
        )}
      </TouchableOpacity>

      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}

      <Text style={styles.sectionTitle}>Authorization Status</Text>

      {HEALTH_TYPES.map((type) => (
        <View key={type} style={styles.statusRow}>
          <Text style={styles.typeName}>{type}</Text>
          <View
            style={[
              styles.statusBadge,
              { backgroundColor: getStatusColor(statuses[type] || 'notDetermined') },
            ]}
          >
            <Text style={styles.statusIcon}>
              {getStatusIcon(statuses[type] || 'notDetermined')}
            </Text>
            <Text style={styles.statusText}>
              {statuses[type] || 'notDetermined'}
            </Text>
          </View>
        </View>
      ))}

      <TouchableOpacity style={styles.refreshButton} onPress={checkAllStatuses}>
        <Text style={styles.refreshButtonText}>Refresh Statuses</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  description: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
    lineHeight: 20,
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  errorContainer: {
    backgroundColor: '#fee',
    padding: 12,
    borderRadius: 8,
    marginTop: 12,
  },
  errorText: {
    color: '#900',
    fontSize: 14,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginTop: 24,
    marginBottom: 12,
  },
  statusRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  typeName: {
    fontSize: 14,
    fontFamily: 'Menlo',
    color: '#333',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusIcon: {
    color: '#fff',
    fontSize: 12,
    marginRight: 4,
  },
  statusText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '500',
  },
  refreshButton: {
    marginTop: 16,
    padding: 12,
    alignItems: 'center',
  },
  refreshButtonText: {
    color: '#007AFF',
    fontSize: 14,
  },
});
