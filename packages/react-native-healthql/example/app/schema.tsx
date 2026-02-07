import { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
} from 'react-native';
import { HealthQL, HealthType, FieldInfo } from 'react-native-healthql';

type TabType = 'quantity' | 'category' | 'special';

export default function SchemaScreen() {
  const [activeTab, setActiveTab] = useState<TabType>('quantity');
  const [selectedType, setSelectedType] = useState<HealthType | null>(null);

  const schema = HealthQL.getSchema();

  const getTypesForTab = (): HealthType[] => {
    switch (activeTab) {
      case 'quantity':
        return schema.quantityTypes;
      case 'category':
        return schema.categoryTypes;
      case 'special':
        return schema.specialTypes;
    }
  };

  const getFields = (type: HealthType): FieldInfo[] => {
    return HealthQL.getFields(type);
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Schema Introspection</Text>

      <Text style={styles.description}>
        Explore all available health types and their fields. Use{' '}
        <Text style={styles.code}>HealthQL.getSchema()</Text> and{' '}
        <Text style={styles.code}>HealthQL.getFields(type)</Text> to build
        dynamic query UIs.
      </Text>

      {/* Tabs */}
      <View style={styles.tabs}>
        {(['quantity', 'category', 'special'] as TabType[]).map((tab) => (
          <TouchableOpacity
            key={tab}
            style={[styles.tab, activeTab === tab && styles.activeTab]}
            onPress={() => {
              setActiveTab(tab);
              setSelectedType(null);
            }}
          >
            <Text
              style={[styles.tabText, activeTab === tab && styles.activeTabText]}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Type count */}
      <Text style={styles.typeCount}>
        {getTypesForTab().length} types available
      </Text>

      {/* Type list */}
      <View style={styles.typeList}>
        {getTypesForTab().map((type) => (
          <TouchableOpacity
            key={type}
            style={[
              styles.typeItem,
              selectedType === type && styles.selectedTypeItem,
            ]}
            onPress={() =>
              setSelectedType(selectedType === type ? null : type)
            }
          >
            <Text
              style={[
                styles.typeItemText,
                selectedType === type && styles.selectedTypeItemText,
              ]}
            >
              {type}
            </Text>
            {selectedType === type && (
              <View style={styles.fieldsContainer}>
                <Text style={styles.fieldsTitle}>Fields:</Text>
                {getFields(type).map((field) => (
                  <View key={field.name} style={styles.fieldRow}>
                    <Text style={styles.fieldName}>{field.name}</Text>
                    <Text style={styles.fieldType}>{field.type}</Text>
                  </View>
                ))}
              </View>
            )}
          </TouchableOpacity>
        ))}
      </View>

      {/* API Reference */}
      <View style={styles.apiSection}>
        <Text style={styles.apiTitle}>API Reference</Text>

        <View style={styles.apiItem}>
          <Text style={styles.apiMethod}>HealthQL.getTypes()</Text>
          <Text style={styles.apiDesc}>Returns all health type names</Text>
        </View>

        <View style={styles.apiItem}>
          <Text style={styles.apiMethod}>HealthQL.getFields(type)</Text>
          <Text style={styles.apiDesc}>
            Returns field info for a specific type
          </Text>
        </View>

        <View style={styles.apiItem}>
          <Text style={styles.apiMethod}>HealthQL.getSchema()</Text>
          <Text style={styles.apiDesc}>
            Returns full schema with types grouped by category
          </Text>
        </View>
      </View>
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
  code: {
    fontFamily: 'Menlo',
    backgroundColor: '#f0f0f0',
    fontSize: 12,
  },
  tabs: {
    flexDirection: 'row',
    marginBottom: 16,
  },
  tab: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    backgroundColor: '#f0f0f0',
    marginHorizontal: 2,
    borderRadius: 6,
  },
  activeTab: {
    backgroundColor: '#007AFF',
  },
  tabText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  activeTabText: {
    color: '#fff',
  },
  typeCount: {
    fontSize: 12,
    color: '#999',
    marginBottom: 8,
  },
  typeList: {
    marginBottom: 24,
  },
  typeItem: {
    backgroundColor: '#f5f5f5',
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
  },
  selectedTypeItem: {
    backgroundColor: '#e3f2fd',
  },
  typeItemText: {
    fontFamily: 'Menlo',
    fontSize: 14,
    color: '#333',
  },
  selectedTypeItemText: {
    fontWeight: '600',
    color: '#007AFF',
  },
  fieldsContainer: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#ddd',
  },
  fieldsTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
    marginBottom: 8,
  },
  fieldRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 4,
  },
  fieldName: {
    fontFamily: 'Menlo',
    fontSize: 12,
    color: '#333',
  },
  fieldType: {
    fontFamily: 'Menlo',
    fontSize: 12,
    color: '#007AFF',
  },
  apiSection: {
    backgroundColor: '#f9f9f9',
    padding: 16,
    borderRadius: 8,
    marginTop: 8,
  },
  apiTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 12,
  },
  apiItem: {
    marginBottom: 12,
  },
  apiMethod: {
    fontFamily: 'Menlo',
    fontSize: 13,
    color: '#333',
    marginBottom: 2,
  },
  apiDesc: {
    fontSize: 12,
    color: '#666',
  },
});
