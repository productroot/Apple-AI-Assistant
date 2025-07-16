import SwiftUI

struct DependencyGraphView: View {
    let viewModel: TasksViewModel
    @State private var dependencyGraph: TaskDependencyAnalyzer.DependencyGraph?
    @State private var isAnalyzing = false
    @State private var selectedTaskId: UUID?
    @State private var showingAIAnalysis = false
    @State private var aiAnalysisResult = ""
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isAnalyzing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Analyzing task dependencies...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("AI is examining task relationships")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let graph = dependencyGraph {
                    if graph.dependencies.isEmpty {
                        EmptyDependencyView()
                    } else {
                        GeometryReader { geometry in
                            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                                GraphCanvasView(
                                    graph: graph,
                                    selectedTaskId: $selectedTaskId,
                                    tasks: viewModel.tasks,
                                    projects: viewModel.projects,
                                    geometry: geometry
                                )
                                .scaleEffect(zoomScale)
                                .offset(x: offset.width + dragOffset.width,
                                       y: offset.height + dragOffset.height)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            dragOffset = value.translation
                                        }
                                        .onEnded { _ in
                                            offset.width += dragOffset.width
                                            offset.height += dragOffset.height
                                            dragOffset = .zero
                                        }
                                )
                                .frame(
                                    width: max(geometry.size.width, 1200) * zoomScale,
                                    height: max(geometry.size.height, 800) * zoomScale
                                )
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            ZoomControls(zoomScale: $zoomScale)
                                .padding()
                        }
                        .overlay(alignment: .bottomLeading) {
                            LegendView()
                                .padding()
                        }
                    }
                } else {
                    StartAnalysisView {
                        analyzeDependencies()
                    }
                }
            }
            .navigationTitle("Task Dependencies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if dependencyGraph != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingAIAnalysis = true
                                performAIAnalysis()
                            } label: {
                                Label("AI Analysis", systemImage: "brain")
                            }
                            
                            Button {
                                analyzeDependencies()
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            
                            if let graph = dependencyGraph, graph.hasCycles {
                                Button(role: .destructive) {
                                    // Show cycle warning
                                } label: {
                                    Label("Circular Dependencies Detected", systemImage: "exclamationmark.triangle")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAIAnalysis) {
                DependencyAIAnalysisView(
                    analysis: aiAnalysisResult,
                    graph: dependencyGraph,
                    onApplySuggestions: applySuggestions
                )
            }
        }
    }
    
    private func analyzeDependencies() {
        isAnalyzing = true
        
        Task {
            // Get incomplete tasks
            let incompleteTasks = viewModel.tasks.filter { !$0.isCompleted }
            
            print("🔍 Analyzing dependencies for \(incompleteTasks.count) tasks")
            
            // Analyze dependencies
            let graph = TaskDependencyAnalyzer.analyzeDependencies(
                tasks: incompleteTasks,
                projects: viewModel.projects
            )
            
            await MainActor.run {
                dependencyGraph = graph
                isAnalyzing = false
                print("✅ Found \(graph.dependencies.count) dependencies")
            }
        }
    }
    
    private func performAIAnalysis() {
        Task {
            do {
                if let graph = dependencyGraph {
                    aiAnalysisResult = try await viewModel.analyzeDependencies(graph)
                }
            } catch {
                print("❌ AI analysis failed: \(error)")
                aiAnalysisResult = "Failed to analyze dependencies. Please try again."
            }
        }
    }
    
    private func applySuggestions() {
        // Apply AI suggestions
        dismiss()
    }
}

struct GraphCanvasView: View {
    let graph: TaskDependencyAnalyzer.DependencyGraph
    @Binding var selectedTaskId: UUID?
    let tasks: [TodoTask]
    let projects: [Project]
    let geometry: GeometryProxy
    
    @State private var nodePositions: [UUID: CGPoint] = [:]
    
    var body: some View {
        ZStack {
            // Draw clusters first (background)
            ForEach(graph.clusters) { cluster in
                ClusterView(
                    cluster: cluster,
                    nodePositions: nodePositions,
                    tasks: tasks
                )
            }
            
            // Draw dependency lines
            ForEach(graph.dependencies) { dependency in
                if let fromPos = nodePositions[dependency.dependsOnTaskId],
                   let toPos = nodePositions[dependency.taskId] {
                    DependencyArrow(
                        from: fromPos,
                        to: toPos,
                        dependency: dependency,
                        isHighlighted: selectedTaskId == dependency.taskId || selectedTaskId == dependency.dependsOnTaskId
                    )
                }
            }
            
            // Draw task nodes
            ForEach(graph.tasks) { task in
                if let position = nodePositions[task.id] {
                    TaskNodeView(
                        task: task,
                        position: position,
                        isSelected: selectedTaskId == task.id,
                        isInCriticalPath: graph.criticalPath.contains(task.id),
                        project: projects.first { $0.id == task.projectId }
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTaskId = selectedTaskId == task.id ? nil : task.id
                        }
                    }
                }
            }
        }
        .onAppear {
            calculateNodePositions()
        }
    }
    
    private func calculateNodePositions() {
        // Simple force-directed layout
        let _ = 600.0 // centerX
        let _ = 400.0 // centerY
        let nodeSpacing = 150.0
        
        // Group tasks by project/cluster
        var yOffset = 100.0
        
        for cluster in graph.clusters {
            let xOffset = 100.0
            let clusterTasks = tasks.filter { cluster.taskIds.contains($0.id) }
            
            for (index, task) in clusterTasks.enumerated() {
                nodePositions[task.id] = CGPoint(
                    x: xOffset + Double(index % 4) * nodeSpacing,
                    y: yOffset + Double(index / 4) * nodeSpacing
                )
            }
            
            yOffset += Double((clusterTasks.count / 4 + 1)) * nodeSpacing + 50
        }
        
        // Position orphan tasks
        let orphanTasks = tasks.filter { task in
            !graph.clusters.contains { $0.taskIds.contains(task.id) }
        }
        
        let xOffset = 100.0
        for (index, task) in orphanTasks.enumerated() {
            nodePositions[task.id] = CGPoint(
                x: xOffset + Double(index % 4) * nodeSpacing,
                y: yOffset + Double(index / 4) * nodeSpacing
            )
        }
    }
}

struct TaskNodeView: View {
    let task: TodoTask
    let position: CGPoint
    let isSelected: Bool
    let isInCriticalPath: Bool
    let project: Project?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(task.title)
                .font(.caption)
                .fontWeight(isInCriticalPath ? .bold : .medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(isSelected ? .white : .primary)
            
            if let project = project {
                Text(project.name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            HStack(spacing: 4) {
                if task.priority != .none {
                    Image(systemName: task.priority.icon)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : task.priority.color)
                }
                
                if task.estimatedDuration != nil {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : .orange)
                }
            }
        }
        .padding(8)
        .frame(width: 120, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : (isInCriticalPath ? Color.red.opacity(0.1) : Color(.systemBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isInCriticalPath ? Color.red : (project?.displayColor ?? Color.gray),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
        )
        .shadow(radius: isSelected ? 8 : 4)
        .position(position)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

struct DependencyArrow: View {
    let from: CGPoint
    let to: CGPoint
    let dependency: TaskDependencyAnalyzer.TaskDependency
    let isHighlighted: Bool
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Calculate control points for curved arrow
            let midX = (from.x + to.x) / 2
            let _ = (from.y + to.y) / 2 // midY
            let controlPoint1 = CGPoint(x: midX, y: from.y)
            let controlPoint2 = CGPoint(x: midX, y: to.y)
            
            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(
            dependency.dependencyType.color.opacity(isHighlighted ? 1.0 : 0.6),
            style: StrokeStyle(
                lineWidth: dependency.dependencyType.arrowStyle.width * (isHighlighted ? 1.5 : 1.0),
                dash: dependency.dependencyType.arrowStyle.dash
            )
        )
        
        // Arrowhead
        Path { path in
            let angle = atan2(to.y - from.y, to.x - from.x)
            let arrowLength: CGFloat = 10
            let arrowAngle: CGFloat = .pi / 6
            
            let arrowPoint1 = CGPoint(
                x: to.x - arrowLength * cos(angle - arrowAngle),
                y: to.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowPoint2 = CGPoint(
                x: to.x - arrowLength * cos(angle + arrowAngle),
                y: to.y - arrowLength * sin(angle + arrowAngle)
            )
            
            path.move(to: arrowPoint1)
            path.addLine(to: to)
            path.addLine(to: arrowPoint2)
        }
        .stroke(
            dependency.dependencyType.color.opacity(isHighlighted ? 1.0 : 0.6),
            lineWidth: dependency.dependencyType.arrowStyle.width * (isHighlighted ? 1.5 : 1.0)
        )
    }
}

struct ClusterView: View {
    let cluster: TaskDependencyAnalyzer.TaskCluster
    let nodePositions: [UUID: CGPoint]
    let tasks: [TodoTask]
    
    var boundingBox: CGRect {
        let positions = cluster.taskIds.compactMap { nodePositions[$0] }
        guard !positions.isEmpty else { return .zero }
        
        let minX = positions.map { $0.x }.min()! - 20
        let maxX = positions.map { $0.x }.max()! + 140
        let minY = positions.map { $0.y }.min()! - 60
        let maxY = positions.map { $0.y }.max()! + 60
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    var body: some View {
        if !cluster.taskIds.isEmpty {
            VStack {
                Text(cluster.name)
                    .font(.headline)
                    .foregroundColor(cluster.color)
                    .position(x: boundingBox.midX, y: boundingBox.minY + 20)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(cluster.color.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(cluster.color.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    )
                    .frame(width: boundingBox.width, height: boundingBox.height)
                    .position(x: boundingBox.midX, y: boundingBox.midY)
            }
        }
    }
}

struct ZoomControls: View {
    @Binding var zoomScale: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation {
                    zoomScale = min(zoomScale + 0.25, 3.0)
                }
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.bordered)
            
            Text("\(Int(zoomScale * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button {
                withAnimation {
                    zoomScale = max(zoomScale - 0.25, 0.5)
                }
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            Button {
                withAnimation {
                    zoomScale = 1.0
                }
            } label: {
                Text("Reset")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Legend")
                .font(.caption)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .foregroundColor(.red)
                Text("Blocks")
                    .font(.caption2)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .foregroundColor(.orange)
                    .opacity(0.8)
                    .overlay(
                        Rectangle()
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .frame(width: 16, height: 2)
                    )
                Text("Requires")
                    .font(.caption2)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                    .opacity(0.6)
                Text("Related")
                    .font(.caption2)
            }
            
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.red, lineWidth: 2)
                    .frame(width: 20, height: 12)
                Text("Critical Path")
                    .font(.caption2)
            }
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

struct StartAnalysisView: View {
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolRenderingMode(.hierarchical)
            
            Text("Task Dependency Analysis")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("AI will analyze your tasks to identify dependencies and suggest optimal ordering")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                onAnalyze()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Analyze Dependencies")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct EmptyDependencyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No Dependencies Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your tasks appear to be independent. This is great for parallel execution!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct DependencyAIAnalysisView: View {
    let analysis: String
    let graph: TaskDependencyAnalyzer.DependencyGraph?
    let onApplySuggestions: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !analysis.isEmpty {
                        Text(analysis)
                            .padding()
                    } else {
                        ProgressView("Analyzing dependencies...")
                            .padding()
                    }
                    
                    if let graph = graph, !graph.dependencies.isEmpty {
                        Button {
                            onApplySuggestions()
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Apply AI Suggestions")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Dependency Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}