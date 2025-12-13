import SwiftUI

struct ContentView: View {
    @State private var selectedAlgorithm: SchedulingAlgorithm = .fcfs
    @State private var processes: [Process] = [Process(pid: 1, arrivalTime: 0, burstTime: 5, priority: 1)]
    @State private var quantum: String = "2"
    @State private var results: SchedulingResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showGanttChart = false
    
    enum SchedulingAlgorithm: String, CaseIterable {
        case fcfs = "FCFS"
        case sjf = "SJF"
        case pri = "Priority"
        case rr = "Round Robin"
        
        var endpoint: String {
            switch self {
            case .fcfs: return "/schedule/fcfs"
            case .sjf: return "/schedule/sjf"
            case .pri: return "/schedule/pri"
            case .rr: return "/schedule/rr"
            }
        }
        
        var description: String {
            switch self {
            case .fcfs: return "First-Come, First-Served"
            case .sjf: return "Shortest Job First"
            case .pri: return "Priority Scheduling"
            case .rr: return "Round Robin"
            }
        }
        
        var icon: String {
            switch self {
            case .fcfs: return "arrow.right.circle.fill"
            case .sjf: return "bolt.circle.fill"
            case .pri: return "star.circle.fill"
            case .rr: return "clock.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .fcfs: return .blue
            case .sjf: return .green
            case .pri: return .orange
            case .rr: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("CPU Scheduling")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Visualize process scheduling algorithms")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                        
                        // Algorithm Selection Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "cpu")
                                    .font(.title3)
                                    .foregroundColor(selectedAlgorithm.color)
                                Text("Algorithm")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(SchedulingAlgorithm.allCases, id: \.self) { algorithm in
                                    AlgorithmCard(
                                        algorithm: algorithm,
                                        isSelected: selectedAlgorithm == algorithm,
                                        action: { selectedAlgorithm = algorithm }
                                    )
                                }
                            }
                            
                            if selectedAlgorithm == .rr {
                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundColor(.purple)
                                    Text("Time Quantum")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    TextField("Quantum", text: $quantum)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Processes Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                Text("Processes")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                Text("PID | AT | BT | Pri")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            
                            LazyVStack(spacing: 12) {
                                ForEach($processes) { $process in
                                    ModernProcessRow(process: $process, onDelete: {
                                        if let index = processes.firstIndex(where: { $0.id == process.id }) {
                                            processes.remove(at: index)
                                        }
                                    })
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: addProcess) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Process")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                }
                                .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
                                
                                Button("Clear All") {
                                    withAnimation(.spring()) {
                                        processes.removeAll()
                                        clearResults()
                                    }
                                }
                                .buttonStyle(ModernButtonStyle(backgroundColor: .red))
                                .disabled(processes.isEmpty)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Calculate Button
                        Button(action: calculateSchedule) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                                Text(isLoading ? "Calculating..." : "Calculate Schedule")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [selectedAlgorithm.color, selectedAlgorithm.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: selectedAlgorithm.color.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(processes.isEmpty || isLoading)
                        .padding(.horizontal)
                        
                        // Results Section
                        if let results = results {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                    Text("Results")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    
                                    Button(showGanttChart ? "Hide Chart" : "Show Chart") {
                                        withAnimation(.spring()) {
                                            showGanttChart.toggle()
                                        }
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                                }
                                
                                // Execution Order
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Execution Order")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(Array(results.order.enumerated()), id: \.offset) { index, pid in
                                                HStack(spacing: 4) {
                                                    ProcessBadge(pid: pid, color: colorForProcess(pid: pid))
                                                    
                                                    if index < results.order.count - 1 {
                                                        Image(systemName: "arrow.right")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Finish Times
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Completion Times")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(Array(results.finish.enumerated()), id: \.offset) { index, finishTime in
                                            HStack {
                                                ProcessBadge(pid: results.order[index], color: colorForProcess(pid: results.order[index]))
                                                Text("completes at")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text("\(finishTime)")
                                                    .font(.system(.body, design: .monospaced))
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.primary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.green.opacity(0.1))
                                                    .cornerRadius(6)
                                            }
                                            .padding(12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                
                                // Gantt Chart
                                if showGanttChart {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Gantt Chart")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        ModernGanttChartView(results: results, processes: processes)
                                            .frame(height: 100)
                                            .padding(.vertical, 8)
                                    }
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: selectedAlgorithm) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                clearResults()
            }
        }
    }
    
    private func addProcess() {
        withAnimation(.spring()) {
            let newPID = (processes.map { $0.pid }.max() ?? 0) + 1
            processes.append(Process(pid: newPID, arrivalTime: 0, burstTime: 1, priority: 1))
        }
    }
    
    private func calculateSchedule() {
        isLoading = true
        errorMessage = nil
        results = nil
        
        // Validate inputs
        guard !processes.isEmpty else {
            errorMessage = "Please add at least one process"
            isLoading = false
            return
        }
        
        // Validate process data
        for process in processes {
            if process.arrivalTime < 0 {
                errorMessage = "Arrival time cannot be negative"
                isLoading = false
                return
            }
            if process.burstTime <= 0 {
                errorMessage = "Burst time must be positive"
                isLoading = false
                return
            }
        }
        
        if selectedAlgorithm == .rr {
            guard let quantumValue = Int(quantum), quantumValue > 0 else {
                errorMessage = "Please enter a valid quantum value (positive integer)"
                isLoading = false
                return
            }
        }
        
        // Prepare request data - match backend format exactly
        let processData = processes.map { process in
            [process.pid, process.arrivalTime, process.burstTime, process.priority]
        }
        
        var requestData: [String: Any] = [
            "processes": processData
        ]
        
        // Add quantum only for Round Robin
        if selectedAlgorithm == .rr, let quantumValue = Int(quantum) {
            requestData["quantum"] = quantumValue
        }
        
        // Make API call
        guard let url = URL(string: "http://localhost:8000\(selectedAlgorithm.endpoint)") else {
            errorMessage = "Invalid server URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestData)
            request.httpBody = jsonData
        } catch {
            errorMessage = "Error preparing request data: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid server response"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received from server"
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    
                    if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                        errorMessage = errorResponse.error
                        return
                    }
                    
                    let apiResult = try decoder.decode(APIResult.self, from: data)
                    
                    guard !apiResult.order.isEmpty, !apiResult.finish.isEmpty else {
                        errorMessage = "Invalid response from server: empty results"
                        return
                    }
                    
                    guard apiResult.order.count == apiResult.finish.count else {
                        errorMessage = "Invalid response from server: order and finish arrays have different lengths"
                        return
                    }
                    
                    withAnimation(.spring()) {
                        self.results = SchedulingResult(
                            order: apiResult.order,
                            finish: apiResult.finish
                        )
                        self.errorMessage = nil
                    }
                    
                } catch {
                    errorMessage = "Error parsing response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func clearResults() {
        withAnimation(.easeInOut(duration: 0.2)) {
            results = nil
            errorMessage = nil
            showGanttChart = false
        }
    }
    
    private func colorForProcess(pid: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .teal, .indigo, .brown, .mint]
        return colors[pid % colors.count]
    }
}

// Modern Algorithm Card
struct AlgorithmCard: View {
    let algorithm: ContentView.SchedulingAlgorithm
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: algorithm.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : algorithm.color)
                
                Text(algorithm.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(algorithm.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ?
                LinearGradient(
                    colors: [algorithm.color, algorithm.color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? algorithm.color : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: isSelected ? algorithm.color.opacity(0.3) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Modern Process Row
struct ModernProcessRow: View {
    @Binding var process: Process
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Process ID Badge
            ProcessBadge(pid: process.pid, color: .blue)
            
            // Input Fields
            HStack(spacing:5){
                InputField(title: "", value: $process.arrivalTime)
                InputField(title: "", value: $process.burstTime)
                InputField(title: "", value: $process.priority)
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Input Field Component
struct InputField: View {
    let title: String
    @Binding var value: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextField("", value: $value, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .frame(width: 60)
        }
    }
}

// Process Badge Component
struct ProcessBadge: View {
    let pid: Int
    let color: Color
    
    var body: some View {
        Text("P\(pid)")
            .font(.system(.caption, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
}

// Modern Gantt Chart
struct ModernGanttChartView: View {
    let results: SchedulingResult
    let processes: [Process]
    
    private var maxFinishTime: Int {
        results.finish.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(results.order.enumerated()), id: \.offset) { index, pid in
                        let width = calculateWidth(for: index)
                        
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorForProcess(pid: pid))
                                .frame(width: width, height: 35)
                                .overlay(
                                    Text("P\(pid)")
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                                .shadow(color: colorForProcess(pid: pid).opacity(0.3), radius: 2, x: 0, y: 2)
                            
                            Text("\(results.finish[index])")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            
            // Timeline
            HStack {
                Text("0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Time →")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(maxFinishTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func calculateWidth(for index: Int) -> CGFloat {
        let totalWidth: CGFloat = 500
        let finishTime = CGFloat(results.finish[index])
        let maxTime = CGFloat(maxFinishTime)
        let calculatedWidth = (finishTime / maxTime) * totalWidth
        return max(calculatedWidth, 50)
    }
    
    private func colorForProcess(pid: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .teal, .indigo, .brown, .mint]
        return colors[pid % colors.count]
    }
}

// Custom Button Styles
struct ModernButtonStyle: ButtonStyle {
    let backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Data Models (unchanged)
struct Process: Identifiable {
    let id = UUID()
    let pid: Int
    var arrivalTime: Int
    var burstTime: Int
    var priority: Int
}

struct SchedulingResult {
    let order: [Int]
    let finish: [Int]
}

struct APIResult: Codable {
    let order: [Int]
    let finish: [Int]
}

struct ErrorResponse: Codable {
    let error: String
}


#Preview{
    ContentView()
}
