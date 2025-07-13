import Foundation
import SwiftUI

struct TaskDependencyAnalyzer {
    struct TaskDependency: Identifiable {
        let id = UUID()
        let taskId: UUID
        let dependsOnTaskId: UUID
        let dependencyType: DependencyType
        let confidence: Double // 0.0 to 1.0
        let reason: String
        
        enum DependencyType {
            case blocks // This task blocks another
            case requires // This task requires another to be completed first
            case related // Tasks are related but not strictly dependent
            
            var description: String {
                switch self {
                case .blocks: return "Blocks"
                case .requires: return "Requires"
                case .related: return "Related"
                }
            }
            
            var color: Color {
                switch self {
                case .blocks: return .red
                case .requires: return .orange
                case .related: return .blue
                }
            }
            
            var arrowStyle: (dash: [CGFloat], width: CGFloat) {
                switch self {
                case .blocks: return ([], 2.0) // Solid line
                case .requires: return ([5, 5], 2.0) // Dashed line
                case .related: return ([2, 2], 1.0) // Dotted line
                }
            }
        }
    }
    
    struct DependencyGraph {
        let tasks: [TodoTask]
        let dependencies: [TaskDependency]
        let clusters: [TaskCluster]
        let criticalPath: [UUID] // Task IDs in critical path order
        
        var hasCycles: Bool {
            // Simple cycle detection
            detectCycles()
        }
        
        private func detectCycles() -> Bool {
            var visited = Set<UUID>()
            var recursionStack = Set<UUID>()
            
            func hasCycleUtil(taskId: UUID) -> Bool {
                visited.insert(taskId)
                recursionStack.insert(taskId)
                
                let outgoingDeps = dependencies.filter { $0.taskId == taskId }
                for dep in outgoingDeps {
                    if !visited.contains(dep.dependsOnTaskId) {
                        if hasCycleUtil(taskId: dep.dependsOnTaskId) {
                            return true
                        }
                    } else if recursionStack.contains(dep.dependsOnTaskId) {
                        return true
                    }
                }
                
                recursionStack.remove(taskId)
                return false
            }
            
            for task in tasks {
                if !visited.contains(task.id) {
                    if hasCycleUtil(taskId: task.id) {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    struct TaskCluster: Identifiable {
        let id = UUID()
        let name: String
        let taskIds: Set<UUID>
        let color: Color
    }
    
    static func analyzeDependencies(tasks: [TodoTask], projects: [Project]) -> DependencyGraph {
        var dependencies: [TaskDependency] = []
        
        // Analyze task titles and notes for dependency keywords
        let _ = [
            "after", "before", "requires", "depends on", "blocked by",
            "waiting for", "needs", "prerequisite", "following"
        ]
        
        for i in 0..<tasks.count {
            let task = tasks[i]
            let taskText = "\(task.title) \(task.notes)".lowercased()
            
            for j in 0..<tasks.count where i != j {
                let otherTask = tasks[j]
                let otherTaskTitle = otherTask.title.lowercased()
                
                // Check for explicit mentions
                if taskText.contains(otherTaskTitle) {
                    // Determine dependency type based on keywords
                    if taskText.contains("after") || taskText.contains("following") {
                        dependencies.append(TaskDependency(
                            taskId: task.id,
                            dependsOnTaskId: otherTask.id,
                            dependencyType: .requires,
                            confidence: 0.8,
                            reason: "Task mentions '\(otherTask.title)' with dependency keyword"
                        ))
                    } else if taskText.contains("blocks") || taskText.contains("blocking") {
                        dependencies.append(TaskDependency(
                            taskId: otherTask.id,
                            dependsOnTaskId: task.id,
                            dependencyType: .blocks,
                            confidence: 0.7,
                            reason: "Task indicates it blocks '\(otherTask.title)'"
                        ))
                    }
                }
                
                // Check for sequential patterns in the same project
                if let projectId = task.projectId,
                   projectId == otherTask.projectId {
                    // Tasks in same project might have dependencies based on dates
                    if let taskDate = task.scheduledDate,
                       let otherDate = otherTask.scheduledDate,
                       taskDate > otherDate {
                        // Check if titles suggest sequence
                        if hasSequentialPattern(task.title, otherTask.title) {
                            dependencies.append(TaskDependency(
                                taskId: task.id,
                                dependsOnTaskId: otherTask.id,
                                dependencyType: .requires,
                                confidence: 0.6,
                                reason: "Sequential pattern detected in project"
                            ))
                        }
                    }
                }
                
                // Check for technical dependencies (e.g., "Setup" before "Deploy")
                if hasTechnicalDependency(from: otherTask.title, to: task.title) {
                    dependencies.append(TaskDependency(
                        taskId: task.id,
                        dependsOnTaskId: otherTask.id,
                        dependencyType: .requires,
                        confidence: 0.7,
                        reason: "Technical dependency pattern detected"
                    ))
                }
            }
        }
        
        // Identify clusters
        let clusters = identifyClusters(tasks: tasks, dependencies: dependencies, projects: projects)
        
        // Calculate critical path
        let criticalPath = calculateCriticalPath(tasks: tasks, dependencies: dependencies)
        
        return DependencyGraph(
            tasks: tasks,
            dependencies: dependencies,
            clusters: clusters,
            criticalPath: criticalPath
        )
    }
    
    private static func hasSequentialPattern(_ title1: String, _ title2: String) -> Bool {
        let sequentialPairs = [
            ("part 1", "part 2"), ("step 1", "step 2"), ("phase 1", "phase 2"),
            ("design", "implement"), ("plan", "execute"), ("research", "develop"),
            ("draft", "review"), ("create", "test"), ("build", "deploy")
        ]
        
        let lower1 = title1.lowercased()
        let lower2 = title2.lowercased()
        
        for (first, second) in sequentialPairs {
            if lower1.contains(first) && lower2.contains(second) {
                return true
            }
        }
        
        // Check for numbered sequences
        let pattern1 = extractNumber(from: lower1)
        let pattern2 = extractNumber(from: lower2)
        
        if let num1 = pattern1, let num2 = pattern2, num2 > num1 {
            return true
        }
        
        return false
    }
    
    private static func extractNumber(from text: String) -> Int? {
        let pattern = #"\d+"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return Int(text[range])
        }
        return nil
    }
    
    private static func hasTechnicalDependency(from: String, to: String) -> Bool {
        let technicalDependencies = [
            ("setup", ["configure", "deploy", "test", "run"]),
            ("design", ["implement", "build", "code"]),
            ("create", ["populate", "fill", "update"]),
            ("install", ["configure", "setup", "use"]),
            ("database", ["api", "frontend", "ui"]),
            ("backend", ["frontend", "ui", "client"]),
            ("infrastructure", ["application", "deployment"])
        ]
        
        let fromLower = from.lowercased()
        let toLower = to.lowercased()
        
        for (prerequisite, dependents) in technicalDependencies {
            if fromLower.contains(prerequisite) {
                for dependent in dependents {
                    if toLower.contains(dependent) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private static func identifyClusters(tasks: [TodoTask], dependencies: [TaskDependency], projects: [Project]) -> [TaskCluster] {
        var clusters: [TaskCluster] = []
        
        // Group by project first
        let projectGroups = Dictionary(grouping: tasks) { $0.projectId }
        
        for (projectId, projectTasks) in projectGroups {
            if let projectId = projectId,
               let project = projects.first(where: { $0.id == projectId }) {
                clusters.append(TaskCluster(
                    name: project.name,
                    taskIds: Set(projectTasks.map { $0.id }),
                    color: project.displayColor
                ))
            }
        }
        
        // Find strongly connected components for tasks without projects
        let orphanTasks = tasks.filter { $0.projectId == nil }
        if !orphanTasks.isEmpty {
            // Simple clustering based on dependencies
            var visited = Set<UUID>()
            
            for task in orphanTasks {
                if !visited.contains(task.id) {
                    var clusterTasks = Set<UUID>()
                    findConnectedTasks(taskId: task.id, dependencies: dependencies, visited: &visited, cluster: &clusterTasks)
                    
                    if clusterTasks.count > 1 {
                        clusters.append(TaskCluster(
                            name: "Related Tasks",
                            taskIds: clusterTasks,
                            color: .gray
                        ))
                    }
                }
            }
        }
        
        return clusters
    }
    
    private static func findConnectedTasks(taskId: UUID, dependencies: [TaskDependency], visited: inout Set<UUID>, cluster: inout Set<UUID>) {
        visited.insert(taskId)
        cluster.insert(taskId)
        
        // Find all connected tasks
        let connected = dependencies.filter { $0.taskId == taskId || $0.dependsOnTaskId == taskId }
        
        for dep in connected {
            let otherTaskId = dep.taskId == taskId ? dep.dependsOnTaskId : dep.taskId
            if !visited.contains(otherTaskId) {
                findConnectedTasks(taskId: otherTaskId, dependencies: dependencies, visited: &visited, cluster: &cluster)
            }
        }
    }
    
    private static func calculateCriticalPath(tasks: [TodoTask], dependencies: [TaskDependency]) -> [UUID] {
        // Simple topological sort for critical path
        var inDegree = [UUID: Int]()
        var adjList = [UUID: [UUID]]()
        
        // Initialize
        for task in tasks {
            inDegree[task.id] = 0
            adjList[task.id] = []
        }
        
        // Build graph
        for dep in dependencies where dep.dependencyType != .related {
            adjList[dep.dependsOnTaskId, default: []].append(dep.taskId)
            inDegree[dep.taskId, default: 0] += 1
        }
        
        // Find nodes with no dependencies
        var queue = tasks.filter { inDegree[$0.id] == 0 }.map { $0.id }
        var result: [UUID] = []
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            result.append(current)
            
            for neighbor in adjList[current] ?? [] {
                inDegree[neighbor]! -= 1
                if inDegree[neighbor] == 0 {
                    queue.append(neighbor)
                }
            }
        }
        
        return result
    }
}