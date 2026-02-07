import { Tabs } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function Layout() {
  return (
    <>
      <StatusBar style="auto" />
      <Tabs
        screenOptions={{
          tabBarActiveTintColor: '#007AFF',
          headerStyle: { backgroundColor: '#f5f5f5' },
        }}
      >
        <Tabs.Screen
          name="index"
          options={{
            title: 'Query',
            tabBarLabel: 'Query',
          }}
        />
        <Tabs.Screen
          name="auth"
          options={{
            title: 'Authorization',
            tabBarLabel: 'Auth',
          }}
        />
        <Tabs.Screen
          name="schema"
          options={{
            title: 'Schema',
            tabBarLabel: 'Schema',
          }}
        />
      </Tabs>
    </>
  );
}
