import SwiftUI
import HealthKit
import HealthQL
import HealthQLParser
import HealthQLPlayground

struct DemoQuery: Identifiable {
    let id = UUID()
    let label: String
    let query: String
    let icon: String
}

let demoQueries: [DemoQuery] = [
    // Quantity types
    DemoQuery(label: "Heart Rate (7d)", query: "SELECT avg(value), min(value), max(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day", icon: "heart.fill"),
    DemoQuery(label: "Steps (30d)", query: "SELECT sum(value) FROM steps WHERE date > today() - 30d GROUP BY day", icon: "figure.walk"),
    DemoQuery(label: "Calories (week)", query: "SELECT sum(value) FROM active_calories WHERE date > start_of_week() GROUP BY day", icon: "bolt.fill"),
    DemoQuery(label: "Distance (month)", query: "SELECT sum(value) FROM distance WHERE date > start_of_month() GROUP BY week", icon: "map.fill"),

    // Workouts
    DemoQuery(label: "Workouts (10)", query: "SELECT duration, total_calories, activity_type FROM workouts ORDER BY date DESC LIMIT 10", icon: "flame.fill"),
    DemoQuery(label: "Workout Stats", query: "SELECT sum(duration), sum(total_calories) FROM workouts WHERE date > today() - 30d GROUP BY week", icon: "chart.bar.fill"),

    // Sleep
    DemoQuery(label: "Sleep (7d)", query: "SELECT * FROM sleep WHERE date > today() - 7d ORDER BY date DESC", icon: "bed.double.fill"),
    DemoQuery(label: "Sleep Analysis", query: "SELECT * FROM sleep_analysis WHERE date > today() - 7d ORDER BY date DESC LIMIT 20", icon: "moon.fill"),

    // Body metrics
    DemoQuery(label: "Weight", query: "SELECT value, date FROM body_mass ORDER BY date DESC LIMIT 10", icon: "scalemass.fill"),
    DemoQuery(label: "Body Fat %", query: "SELECT avg(value) FROM body_fat_percentage WHERE date > today() - 30d GROUP BY week", icon: "percent"),

    // Vitals
    DemoQuery(label: "Blood O2", query: "SELECT avg(value), min(value) FROM oxygen_saturation WHERE date > today() - 7d GROUP BY day", icon: "lungs.fill"),
    DemoQuery(label: "Respiratory", query: "SELECT avg(value) FROM respiratory_rate WHERE date > today() - 7d GROUP BY day", icon: "wind"),

    // Activity
    DemoQuery(label: "Flights", query: "SELECT sum(value) FROM flights_climbed WHERE date > today() - 7d GROUP BY day", icon: "arrow.up.right"),
    DemoQuery(label: "Exercise Min", query: "SELECT sum(value) FROM exercise_minutes WHERE date > today() - 7d GROUP BY day", icon: "figure.run"),

    // Category types
    DemoQuery(label: "Headaches", query: "SELECT * FROM headache WHERE date > today() - 30d ORDER BY date DESC", icon: "brain.head.profile"),
    DemoQuery(label: "Fatigue", query: "SELECT * FROM fatigue WHERE date > today() - 14d ORDER BY date DESC", icon: "battery.25"),

    // Commands
    DemoQuery(label: "All Types", query: ".types", icon: "list.bullet"),
    DemoQuery(label: "Help", query: ".help", icon: "questionmark.circle"),
]

struct ContentView: View {
    @StateObject private var viewModel = QueryViewModel()
    @State private var showDemoQueries = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Results area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.history) { entry in
                                HistoryEntryView(entry: entry)
                                    .id(entry.id)
                            }

                            // Loading indicator
                            if viewModel.isExecuting {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Executing...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.history.count) { _, _ in
                        if let last = viewModel.history.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isExecuting) { _, isExecuting in
                        if isExecuting {
                            withAnimation {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Demo queries section
                if showDemoQueries {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Demo Queries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                withAnimation { showDemoQueries = false }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: [
                                GridItem(.fixed(36)),
                                GridItem(.fixed(36))
                            ], spacing: 8) {
                                ForEach(demoQueries) { demo in
                                    Button {
                                        viewModel.executeQuery(demo.query)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: demo.icon)
                                                .font(.caption2)
                                            Text(demo.label)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 10)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(viewModel.isExecuting)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                }

                // Query input
                HStack {
                    TextField("Enter query...", text: $viewModel.queryText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onSubmit {
                            viewModel.executeQuery()
                        }

                    if !showDemoQueries {
                        Button {
                            withAnimation { showDemoQueries = true }
                        } label: {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                        }
                    }

                    Button(action: { viewModel.executeQuery() }) {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.queryText.isEmpty || viewModel.isExecuting)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("HealthQL")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(".help") { viewModel.executeQuery(".help") }
                        Button(".types") { viewModel.executeQuery(".types") }
                        Button(".schema heart_rate") { viewModel.executeQuery(".schema heart_rate") }
                        Button(".schema steps") { viewModel.executeQuery(".schema steps") }
                        Button(".schema workouts") { viewModel.executeQuery(".schema workouts") }
                        Divider()
                        Button("Clear History", role: .destructive) {
                            viewModel.history.removeAll()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            await viewModel.setup()
        }
    }
}

struct HistoryEntryView: View {
    let entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Query
            HStack {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(entry.query)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
            }

            // Result
            if let error = entry.error {
                Text(error)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.red)
            } else {
                Text(entry.result)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct HistoryEntry: Identifiable {
    let id = UUID()
    let query: String
    let result: String
    let error: String?
}

@MainActor
class QueryViewModel: ObservableObject {
    @Published var queryText = ""
    @Published var history: [HistoryEntry] = []
    @Published var isExecuting = false

    private let repl = REPLEngine()
    private let healthStore = HKHealthStore()

    func setup() async {
        // Request HealthKit authorization upfront for common types
        await requestHealthKitAuthorization()

        // Add welcome message
        history.append(HistoryEntry(
            query: "Welcome to HealthQL",
            result: "Tap a demo query below or type your own.\nExample: SELECT avg(value) FROM heart_rate WHERE date > today() - 7d GROUP BY day",
            error: nil
        ))
    }

    private func requestHealthKitAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // Request authorization for common types
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKCategoryType(.sleepAnalysis),
            HKWorkoutType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            print("HealthKit authorization error: \(error)")
        }
    }

    func executeQuery(_ directQuery: String? = nil) {
        let query = (directQuery ?? queryText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        if directQuery == nil {
            queryText = ""
        }
        isExecuting = true

        Task {
            // Add timeout to prevent hanging
            let result = await withTaskGroup(of: String.self) { group in
                group.addTask {
                    await self.repl.execute(query)
                }
                group.addTask {
                    try? await Task.sleep(for: .seconds(10))
                    return "Error: Query timed out after 10 seconds"
                }

                // Return whichever finishes first
                let first = await group.next() ?? "Error: Unknown"
                group.cancelAll()
                return first
            }

            await MainActor.run {
                self.history.append(HistoryEntry(query: query, result: result, error: nil))
                self.isExecuting = false
            }
        }
    }
}

#Preview {
    ContentView()
}
