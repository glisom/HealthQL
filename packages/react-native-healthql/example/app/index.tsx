import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { HealthQL, HealthQLError } from 'react-native-healthql';

const EXAMPLE_QUERIES = [
  'SELECT * FROM heart_rate LIMIT 5',
  'SELECT avg(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day',
  'SELECT sum(value) FROM steps WHERE date > today() - 7d GROUP BY day',
  'SELECT * FROM sleep_analysis LIMIT 5',
  'SELECT * FROM workouts LIMIT 5',
];

export default function QueryScreen() {
  const [query, setQuery] = useState(EXAMPLE_QUERIES[0]);
  const [results, setResults] = useState<any[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const executeQuery = async () => {
    setLoading(true);
    setError(null);
    setResults(null);

    try {
      const data = await HealthQL.query(query);
      setResults(data as any[]);
    } catch (e) {
      if (e instanceof HealthQLError) {
        setError(`[${e.code}] ${e.message}`);
        if (e.details?.suggestion) {
          setError((prev) => `${prev}\n${e.details!.suggestion}`);
        }
      } else {
        setError(String(e));
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>SQL Query</Text>

      <TextInput
        style={styles.input}
        value={query}
        onChangeText={setQuery}
        multiline
        numberOfLines={3}
        placeholder="Enter SQL query..."
        autoCapitalize="none"
        autoCorrect={false}
      />

      <TouchableOpacity
        style={styles.button}
        onPress={executeQuery}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.buttonText}>Execute Query</Text>
        )}
      </TouchableOpacity>

      <Text style={styles.sectionTitle}>Example Queries</Text>
      {EXAMPLE_QUERIES.map((q, i) => (
        <TouchableOpacity
          key={i}
          style={styles.exampleQuery}
          onPress={() => setQuery(q)}
        >
          <Text style={styles.exampleQueryText}>{q}</Text>
        </TouchableOpacity>
      ))}

      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorTitle}>Error</Text>
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}

      {results && (
        <View style={styles.resultsContainer}>
          <Text style={styles.resultsTitle}>
            Results ({results.length} rows)
          </Text>
          {results.map((row, i) => (
            <View key={i} style={styles.resultRow}>
              <Text style={styles.resultText}>
                {JSON.stringify(row, null, 2)}
              </Text>
            </View>
          ))}
        </View>
      )}
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
    marginBottom: 16,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    fontFamily: 'Menlo',
    backgroundColor: '#f9f9f9',
    minHeight: 80,
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 12,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 24,
    marginBottom: 8,
    color: '#666',
  },
  exampleQuery: {
    backgroundColor: '#f0f0f0',
    padding: 10,
    borderRadius: 6,
    marginBottom: 8,
  },
  exampleQueryText: {
    fontFamily: 'Menlo',
    fontSize: 12,
    color: '#333',
  },
  errorContainer: {
    backgroundColor: '#fee',
    padding: 12,
    borderRadius: 8,
    marginTop: 16,
  },
  errorTitle: {
    fontWeight: 'bold',
    color: '#c00',
    marginBottom: 4,
  },
  errorText: {
    color: '#900',
    fontFamily: 'Menlo',
    fontSize: 12,
  },
  resultsContainer: {
    marginTop: 16,
  },
  resultsTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
  },
  resultRow: {
    backgroundColor: '#f5f5f5',
    padding: 10,
    borderRadius: 6,
    marginBottom: 8,
  },
  resultText: {
    fontFamily: 'Menlo',
    fontSize: 11,
    color: '#333',
  },
});
