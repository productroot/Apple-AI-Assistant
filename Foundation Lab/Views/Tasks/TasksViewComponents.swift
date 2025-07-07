import SwiftUI

// MARK: - Task Section Row
struct TaskSectionRow: View {
    let section: TaskSection
    let count: Int
    let viewModel: TasksViewModel
    
    var body: some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundStyle(section.color)
                .font(.title3)
                .frame(width: 28)
            
            Text(section.rawValue)
                .font(.body)
            
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
        .padding(.vertical, 4)
    }
}

// MARK: - Area Header View
struct AreaHeaderView: View {
    let area: Area
    
    var body: some View {
        HStack {
            Image(systemName: area.icon)
                .foregroundStyle(Color(area.color))
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
            Circle()
                .fill(Color(project.color))
                .frame(width: 8, height: 8)
                .padding(.leading, 20)
            
            Text(project.name)
                .font(.body)
            
            Spacer()
            
            if project.progress > 0 {
                CircularProgressView(progress: project.progress)
                    .frame(width: 20, height: 20)
            }
            
            let taskCount = viewModel.tasks.filter { !$0.isCompleted && $0.projectId == project.id }.count
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