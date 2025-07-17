import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TasksView: View {
    let viewModel: TasksViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showingAddTask = false
    @State private var showingQuickAddOverlay = false
    @State private var isCreatingProject = false
    @State private var newProjectName = ""
    @State private var newProjectAreaId: UUID?
    @State private var isCreatingArea = false
    @State private var newAreaName = ""
    @State private var areaToEdit: Area?
    @State private var projectToEdit: Project?
    @State private var showingDeleteAreaAlert = false
    @State private var showingDeleteProjectAlert = false
    @State private var areaToDelete: Area?
    @State private var projectToDelete: Project?
#if os(iOS)
    @State private var editMode: EditMode = .inactive
#else
    @State private var editMode: Bool = false
#endif
    @State private var showingOptimization = false
    @State private var showingWorkloadBalance = false
    @State private var showingRecurrenceSuggestions = false
    @State private var showingDependencyGraph = false
    @State private var showingInsightsDashboard = false
    @AppStorage("showTaskExplainers") private var showExplainers = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                tasksList
            }
            
            overlayViews
        }
    }
    
    private var tasksList: some View {
        List {
#if os(iOS)
            if editMode == .inactive {
                mainSections
                areasAndProjectsSection
            } else {
                // In edit mode, show the editable list
                areasAndProjectsSection
            }
#else
            if !editMode {
                mainSections
                areasAndProjectsSection
            } else {
                // In edit mode, show the editable list
                areasAndProjectsSection
            }
#endif
        }
        .id("\(viewModel.projects.count)-\(viewModel.areas.count)-\(viewModel.tasks.count)")
        .listStyle(.insetGrouped)
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TaskFilter.self) { filter in
            TasksSectionDetailView(viewModel: viewModel, filter: filter)
        }
        .navigationDestination(for: Area.self) { area in
            print("🚀 NavigationDestination triggered for area: \(area.name)")
            return AreaProjectsView(area: area, viewModel: viewModel)
        }
        .toolbar {
            aiToolsButton
            helpAndEditButtons
        }
#if os(iOS)
        .environment(\.editMode, $editMode)
#endif
        .modifier(TasksViewSheets(
            showingAddTask: $showingAddTask,
            showingOptimization: $showingOptimization,
            showingWorkloadBalance: $showingWorkloadBalance,
            showingRecurrenceSuggestions: $showingRecurrenceSuggestions,
            showingDependencyGraph: $showingDependencyGraph,
            showingInsightsDashboard: $showingInsightsDashboard,
            areaToEdit: $areaToEdit,
            projectToEdit: $projectToEdit,
            viewModel: viewModel
        ))
        .modifier(TasksViewAlerts(
            showingDeleteAreaAlert: $showingDeleteAreaAlert,
            showingDeleteProjectAlert: $showingDeleteProjectAlert,
            areaToDelete: $areaToDelete,
            projectToDelete: $projectToDelete,
            deleteArea: deleteArea,
            deleteProject: deleteProject
        ))
    }
    
    @ToolbarContentBuilder
    private var aiToolsButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button {
                    showingOptimization = true
                } label: {
                    Label("Optimize Tasks", systemImage: "sparkles")
                }
                
                Button {
                    showingWorkloadBalance = true
                } label: {
                    Label("Workload Balance", systemImage: "chart.bar.fill")
                }
                
                Button {
                    showingRecurrenceSuggestions = true
                } label: {
                    Label("Detect Patterns", systemImage: "arrow.clockwise")
                }
                
                Divider()
                
                Button {
                    showingDependencyGraph = true
                } label: {
                    Label("Task Dependencies", systemImage: "network")
                }
                
                Button {
                    showingInsightsDashboard = true
                } label: {
                    Label("Productivity Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
            } label: {
                Label("AI Tools", systemImage: "sparkles")
            }
        }
    }
    
    @ToolbarContentBuilder
    private var helpAndEditButtons: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showExplainers.toggle()
                    }
                } label: {
                    Image(systemName: showExplainers ? "questionmark.circle.fill" : "questionmark.circle")
                        .font(.body)
                        .foregroundColor(showExplainers ? .accentColor : .primary)
                }
                
                EditButton()
            }
        }
    }
    
    @ViewBuilder
    private var mainSections: some View {
        Section {
            ForEach(TaskSection.allCases.filter { $0 != .logbook }, id: \.self) { section in
                NavigationLink(value: TaskFilter.section(section)) {
                    TaskSectionRow(
                        section: section,
                        count: taskCount(for: section),
                        viewModel: viewModel,
                        showExplainers: showExplainers
                    )
                }
            }
        }
        
        Section {
            NavigationLink(value: TaskFilter.section(.logbook)) {
                TaskSectionRow(
                    section: .logbook,
                    count: taskCount(for: .logbook),
                    viewModel: viewModel,
                    showExplainers: showExplainers
                )
            }
        }
        
        if isCreatingProject && newProjectAreaId == nil {
            Section {
                InlineProjectCreationView(
                    projectName: $newProjectName,
                    selectedAreaId: $newProjectAreaId,
                    areas: viewModel.areas,
                    onSave: { saveNewProject() },
                    onCancel: { cancelProjectCreation() }
                )
            }
        }
    }
    
    @ViewBuilder
    private var areasAndProjectsSection: some View {
#if os(iOS)
        if editMode == .active {
            // Edit mode: simple list for areas
            Section(header: VStack(alignment: .leading, spacing: 2) {
                Text("Areas & Projects")
                    .font(.headline)
                if showExplainers {
                    Text("Organize your tasks by context and goals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                }
            }) {
                ForEach(viewModel.areas) { area in
                    NavigationLink(value: area) {
                        HStack {
                            Image(systemName: area.icon)
                                .foregroundStyle(area.displayColor)
                                .frame(width: 28)
                            
                            Text(area.name)
                                .font(.body)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if areaTaskCount(for: area) > 0 {
                                Text("\(areaTaskCount(for: area))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
                }
                .onMove { from, to in
                    viewModel.areas.move(fromOffsets: from, toOffset: to)
                    viewModel.saveToiCloudIfEnabled()
                }
                .onDelete { indices in
                    for index in indices {
                        areaToDelete = viewModel.areas[index]
                        showingDeleteAreaAlert = true
                    }
                }
            }
            
            // Orphan projects in separate section
            let orphanProjects = viewModel.projects.filter { $0.areaId == nil }
            if !orphanProjects.isEmpty {
                Section(header: VStack(alignment: .leading, spacing: 2) {
                    Text("Projects")
                        .font(.headline)
                    if showExplainers {
                        Text("Projects not assigned to any area")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .transition(.asymmetric(
                                insertion: .push(from: .top).combined(with: .opacity),
                                removal: .push(from: .bottom).combined(with: .opacity)
                            ))
                    }
                }) {
                    ForEach(orphanProjects) { project in
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
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .listRowInsets(EdgeInsets())
                    }
                    .onMove { from, to in
                        var orphans = viewModel.projects.filter { $0.areaId == nil }
                        orphans.move(fromOffsets: from, toOffset: to)
                        
                        // Update the projects array
                        viewModel.projects = viewModel.projects.filter { $0.areaId != nil } + orphans
                        viewModel.saveToiCloudIfEnabled()
                    }
                    .onDelete { indices in
                        let orphans = viewModel.projects.filter { $0.areaId == nil }
                        for index in indices {
                            if index < orphans.count {
                                projectToDelete = orphans[index]
                                showingDeleteProjectAlert = true
                            }
                        }
                    }
                }
            }
        } else {
            // Normal mode: grouped by areas
            Group {
                areasSection
                orphanProjectsSection
            }
        }
#else
        if editMode {
            // Edit mode: simple list for areas
            Section(header: VStack(alignment: .leading, spacing: 2) {
                Text("Areas & Projects")
                    .font(.headline)
                if showExplainers {
                    Text("Organize your tasks by context and goals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                }
            }) {
                ForEach(viewModel.areas) { area in
                    NavigationLink(value: area) {
                        HStack {
                            Image(systemName: area.icon)
                                .foregroundStyle(area.displayColor)
                                .frame(width: 28)
                            
                            Text(area.name)
                                .font(.body)
                            
                            Spacer()
                            
                            if areaTaskCount(for: area) > 0 {
                                Text("\(areaTaskCount(for: area))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                }
                .onMove { from, to in
                    viewModel.areas.move(fromOffsets: from, toOffset: to)
                    viewModel.saveToiCloudIfEnabled()
                }
                .onDelete { indices in
                    for index in indices {
                        if index < viewModel.areas.count {
                            areaToDelete = viewModel.areas[index]
                            showingDeleteAreaAlert = true
                        }
                    }
                }
                
                ForEach(viewModel.projects.filter { $0.areaId == nil }) { project in
                    HStack {
                        Image(systemName: project.icon)
                            .foregroundStyle(project.displayColor)
                            .frame(width: 28)
                        
                        Text(project.name)
                            .font(.body)
                        
                        Spacer()
                        
                        let taskCount = viewModel.tasks.filter { !$0.isCompleted && $0.projectId == project.id }.count
                        if taskCount > 0 {
                            Text("\(taskCount)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .onMove { from, to in
                    let orphans = viewModel.projects.filter { $0.areaId == nil }
                    var reorderedOrphans = orphans
                    reorderedOrphans.move(fromOffsets: from, toOffset: to)
                    
                    for (index, project) in reorderedOrphans.enumerated() {
                        if let globalIndex = viewModel.projects.firstIndex(where: { $0.id == project.id }) {
                            viewModel.projects[globalIndex] = project
                        }
                    }
                    viewModel.saveToiCloudIfEnabled()
                }
                .onDelete { indices in
                    let orphans = viewModel.projects.filter { $0.areaId == nil }
                    for index in indices {
                        if index < orphans.count {
                            projectToDelete = orphans[index]
                            showingDeleteProjectAlert = true
                        }
                    }
                }
            }
        } else {
            // Normal mode: grouped by areas
            Group {
                areasSection
                orphanProjectsSection
            }
        }
#endif
    }
    
    @ViewBuilder
    private var areasSection: some View {
        if !viewModel.areas.isEmpty || isCreatingArea {
            if isCreatingArea {
                Section {
                    InlineAreaCreationView(
                        areaName: $newAreaName,
                        onSave: { saveNewArea() },
                        onCancel: { cancelAreaCreation() }
                    )
                }
            }
            
            ForEach(viewModel.areas) { area in
                AreaSectionView(
                    area: area,
                    viewModel: viewModel,
                    isCreatingProject: $isCreatingProject,
                    newProjectName: $newProjectName,
                    newProjectAreaId: $newProjectAreaId,
                    areaToEdit: $areaToEdit,
                    areaToDelete: $areaToDelete,
                    showingDeleteAreaAlert: $showingDeleteAreaAlert,
                    projectToEdit: $projectToEdit,
                    projectToDelete: $projectToDelete,
                    showingDeleteProjectAlert: $showingDeleteProjectAlert,
                    editMode: $editMode,
                    onSaveProject: { saveNewProject() },
                    onCancelProject: { cancelProjectCreation() },
                    onNavigateToProject: { project in
                        navigationPath.append(TaskFilter.project(project))
                    }
                )
            }
            .onMove { from, to in
                viewModel.areas.move(fromOffsets: from, toOffset: to)
                viewModel.saveToiCloudIfEnabled()
            }
            .onDelete { indices in
                for index in indices {
                    areaToDelete = viewModel.areas[index]
                    showingDeleteAreaAlert = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var orphanProjectsSection: some View {
        OrphanProjectsSection(
            viewModel: viewModel,
            projectToEdit: $projectToEdit,
            projectToDelete: $projectToDelete,
            showingDeleteProjectAlert: $showingDeleteProjectAlert,
            editMode: $editMode,
            showExplainers: showExplainers,
            onNavigateToProject: { project in
                navigationPath.append(TaskFilter.project(project))
            }
        )
    }
    
    @ViewBuilder
    private var overlayViews: some View {
#if os(iOS)
        if !showingQuickAddOverlay && editMode == .inactive {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingQuickAddOverlay = true
                        }
                    })
                        .padding(.trailing, 20)
                        .padding(.bottom, 25)
                }
            }
        }
#else
        if !showingQuickAddOverlay && !editMode {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingQuickAddOverlay = true
                        }
                    })
                        .padding(.trailing, 20)
                        .padding(.bottom, 25)
                }
            }
        }
#endif
        
        if showingQuickAddOverlay {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingQuickAddOverlay = false
                    }
                }
            
            VStack {
                Spacer()
                
                QuickAddOverlay(
                    isPresented: $showingQuickAddOverlay,
                    onTaskSelected: {
                        showingAddTask = true
                    },
                    onProjectSelected: {
                        isCreatingProject = true
                        newProjectName = ""
                        newProjectAreaId = nil
                    },
                    onAreaSelected: {
                        isCreatingArea = true
                        newAreaName = ""
                    }
                )
                .frame(maxWidth: 400)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Helper Methods
    private func taskCount(for section: TaskSection) -> Int {
        switch section {
        case .inbox:
            return viewModel.tasks.filter { !$0.isCompleted && $0.scheduledDate == nil && $0.projectId == nil }.count
        case .today:
            return viewModel.todayTasks.count
        case .upcoming:
            return viewModel.upcomingTasks.count
        case .anytime:
            return viewModel.tasks.filter { !$0.isCompleted && $0.projectId != nil }.count
        case .someday:
            return viewModel.tasks.filter { !$0.isCompleted && $0.tags.contains("someday") }.count
        case .logbook:
            return viewModel.tasks.filter { $0.isCompleted }.count
        }
    }
    
    private func areaTaskCount(for area: Area) -> Int {
        viewModel.tasks.filter { !$0.isCompleted && $0.areaId == area.id && $0.projectId == nil }.count
    }
    
    private func projectTaskCount(for project: Project) -> Int {
        viewModel.tasks.filter { !$0.isCompleted && $0.projectId == project.id }.count
    }
    
    private func saveNewProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedName = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let areaId = newProjectAreaId
        
        // Reset state immediately
        isCreatingProject = false
        newProjectName = ""
        newProjectAreaId = nil
        
        // Create and add project
        let newProject = Project(
            name: trimmedName,
            areaId: areaId
        )
        
        viewModel.addProject(newProject)
    }
    
    private func cancelProjectCreation() {
        isCreatingProject = false
        newProjectName = ""
        newProjectAreaId = nil
    }
    
    private func saveNewArea() {
        guard !newAreaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newArea = Area(
            name: newAreaName.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: "square.stack.3d.up",
            color: "blue"
        )
        
        viewModel.addArea(newArea, at: 0)
        
        DispatchQueue.main.async {
            self.isCreatingArea = false
            self.newAreaName = ""
        }
    }
    
    private func cancelAreaCreation() {
        isCreatingArea = false
        newAreaName = ""
    }
    
    private func deleteArea(_ area: Area) {
        viewModel.deleteArea(area)
    }
    
    private func deleteProject(_ project: Project) {
        viewModel.deleteProject(project)
    }
}

// MARK: - View Modifiers

struct TasksViewSheets: ViewModifier {
    @Binding var showingAddTask: Bool
    @Binding var showingOptimization: Bool
    @Binding var showingWorkloadBalance: Bool
    @Binding var showingRecurrenceSuggestions: Bool
    @Binding var showingDependencyGraph: Bool
    @Binding var showingInsightsDashboard: Bool
    @Binding var areaToEdit: Area?
    @Binding var projectToEdit: Project?
    let viewModel: TasksViewModel
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .sheet(item: $areaToEdit) { area in
                EditAreaView(viewModel: viewModel, area: area)
            }
            .sheet(item: $projectToEdit) { project in
                EditProjectView(viewModel: viewModel, project: project)
            }
            .sheet(isPresented: $showingOptimization) {
                TaskOptimizationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingWorkloadBalance) {
                WorkloadBalanceView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingRecurrenceSuggestions) {
                RecurrenceSuggestionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingDependencyGraph) {
                DependencyGraphView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingInsightsDashboard) {
                TaskInsightsDashboardView(viewModel: viewModel)
            }
    }
}

struct TasksViewAlerts: ViewModifier {
    @Binding var showingDeleteAreaAlert: Bool
    @Binding var showingDeleteProjectAlert: Bool
    @Binding var areaToDelete: Area?
    @Binding var projectToDelete: Project?
    let deleteArea: (Area) -> Void
    let deleteProject: (Project) -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Delete Area", isPresented: $showingDeleteAreaAlert, presenting: areaToDelete) { area in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteArea(area)
                }
            } message: { area in
                Text("Are you sure you want to delete \"\(area.name)\"? This will also delete all projects and tasks within this area.")
            }
            .alert("Delete Project", isPresented: $showingDeleteProjectAlert, presenting: projectToDelete) { project in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteProject(project)
                }
            } message: { project in
                Text("Are you sure you want to delete \"\(project.name)\"? This will also delete all tasks within this project.")
            }
    }
}