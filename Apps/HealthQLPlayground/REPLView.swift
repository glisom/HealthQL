import SwiftUI
import HealthQLPlayground

struct REPLView: View {
    @StateObject private var viewModel = REPLViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.outputLines) { line in
                            Text(line.text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(line.isError ? .red : .primary)
                                .textSelection(.enabled)
                                .id(line.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.outputLines.count) { _, _ in
                    if let lastLine = viewModel.outputLines.last {
                        proxy.scrollTo(lastLine.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            // Input area
            HStack(spacing: 8) {
                Text("HealthQL>")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)

                TextField("Enter query...", text: $viewModel.inputText)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.executeCommand()
                    }
                    .onKeyPress(.upArrow) {
                        viewModel.historyUp()
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        viewModel.historyDown()
                        return .handled
                    }
            }
            .padding()
            .background(Color(nsColor: .textBackgroundColor))
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

@MainActor
class REPLViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var outputLines: [OutputLine] = []

    private let engine = REPLEngine()

    struct OutputLine: Identifiable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    init() {
        // Welcome message
        outputLines.append(OutputLine(
            text: "HealthQL Playground v1.0\nType .help for available commands.\n",
            isError: false
        ))
    }

    func executeCommand() {
        let command = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        // Echo the command
        outputLines.append(OutputLine(text: "HealthQL> \(command)", isError: false))

        // Clear input
        inputText = ""
        Task {
            await engine.resetHistoryNavigation()
        }

        // Execute asynchronously
        Task {
            let result = await engine.execute(command)
            let isError = result.contains("Error") || result.contains("Unknown")
            outputLines.append(OutputLine(text: result, isError: isError))
        }
    }

    func historyUp() {
        Task {
            if let previous = await engine.historyUp() {
                inputText = previous
            }
        }
    }

    func historyDown() {
        Task {
            let next = await engine.historyDown()
            inputText = next ?? ""
        }
    }
}

#Preview {
    REPLView()
        .frame(width: 800, height: 600)
}
