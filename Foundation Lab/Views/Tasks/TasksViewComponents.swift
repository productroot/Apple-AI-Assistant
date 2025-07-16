import SwiftUI

// MARK: - Task Section Row
struct TaskSectionRow: View {
    let section: TaskSection
    let count: Int
    let viewModel: TasksViewModel
    let showExplainers: Bool
    
    var body: some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundStyle(section.color)
                .font(.title3)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.body)
                
                if showExplainers {
                    Text(section.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                }
            }
            
            Spacer()
            
            if count > 0 {
                Text("\(count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, showExplainers ? 6 : 4)
        .animation(.easeInOut(duration: 0.3), value: showExplainers)
    }
}

// MARK: - Area Header View
struct AreaHeaderView: View {
    let area: Area
    
    var body: some View {
        HStack {
            Image(systemName: area.icon)
                .foregroundStyle(area.displayColor)
                .font(.caption)
            
            Text(area.name.uppercased())
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: Project
    let viewModel: TasksViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            let allProjectTasks = viewModel.tasks.filter { $0.projectId == project.id }
            let openProjectTasks = allProjectTasks.filter { !$0.isCompleted }
            let completionProgress = allProjectTasks.isEmpty ? 0.0 : Double(allProjectTasks.count - openProjectTasks.count) / Double(allProjectTasks.count)
            
            ZStack {
                Circle()
                    .stroke(project.displayColor.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                
                Circle()
                    .trim(from: 0, to: completionProgress)
                    .stroke(project.displayColor, lineWidth: 1.5)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: completionProgress)
                    .frame(width: 16, height: 16)
            }
            .padding(.leading, 20)
            
            Text(project.name)
                .font(.body)
            
            Spacer()
            
            if project.progress > 0 {
                CircularProgressView(progress: project.progress)
                    .frame(width: 20, height: 20)
            }
            
            let taskCount = openProjectTasks.count
            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}