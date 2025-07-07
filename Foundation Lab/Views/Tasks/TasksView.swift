import SwiftUI

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
    @State private var editMode: EditMode = .inactive
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
            mainSections
            areasSection
            orphanProjectsSection
        }
        .id("\(viewModel.projects.count)-\(viewModel.areas.count)-\(viewModel.tasks.count)")
        .listStyle(.insetGrouped)
        .navigationTitle("Tasks (\(viewModel.projects.count) projects)")
        .navigationDestination(for: TaskFilter.self) { filter in
            TasksSectionDetailView(viewModel: viewModel, filter: filter)
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: viewModel)
        }
        .sheet(item: $areaToEdit) { area in
            EditAreaView(viewModel: viewModel, area: area)
        }
        .sheet(item: $projectToEdit) { project in
            EditProjectView(viewModel: viewModel, project: project)
        }
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
    
    @ViewBuilder
    private var mainSections: some View {
        Section {
            ForEach(TaskSection.allCases.filter { $0 != .logbook }, id: \.self) { section in
                NavigationLink(value: TaskFilter.section(section)) {
                    TaskSectionRow(
                        section: section,
                        count: taskCount(for: section),
                        viewModel: viewModel
                    )
                }
            }
        }
        
        Section {
            NavigationLink(value: TaskFilter.section(.logbook)) {
                TaskSectionRow(
                    section: .logbook,
                    count: taskCount(for: .logbook),
                    viewModel: viewModel
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
                    onSaveProject: { saveNewProject() },
                    onCancelProject: { cancelProjectCreation() }
                )
            }
            .onMove { source, destination in
                moveAreas(from: source, to: destination)
            }
        }
    }
    
    @ViewBuilder
    private var orphanProjectsSection: some View {
        OrphanProjectsSection(
            viewModel: viewModel,
            projectToEdit: $projectToEdit,
            projectToDelete: $projectToDelete,
            showingDeleteProjectAlert: $showingDeleteProjectAlert
        )
    }
    
    @ViewBuilder
    private var overlayViews: some View {
        if !showingQuickAddOverlay {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingQuickAddOverlay = true
                        }
                    })
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                }
            }
        }
        
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
            return viewModel.tasks.filter { !$0.isCompleted && $0.scheduledDate == nil && $0.projectId != nil }.count
        case .someday:
            return viewModel.tasks.filter { !$0.isCompleted && $0.tags.contains("someday") }.count
        case .logbook:
            return viewModel.tasks.filter { $0.isCompleted }.count
        }
    }
    
    private func areaTaskCount(for area: Area) -> Int {
        viewModel.tasks.filter { !$0.isCompleted && $0.areaId == area.id }.count
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
    
    // MARK: - Drag & Drop Helpers
    private func moveAreas(from source: IndexSet, to destination: Int) {
        viewModel.areas.move(fromOffsets: source, toOffset: destination)
        if let firstArea = viewModel.areas.first {
            viewModel.updateArea(firstArea)
        }
    }
    
    private func moveProjects(in area: Area, from source: IndexSet, to destination: Int) {
        var areaProjects = viewModel.projects.filter { $0.areaId == area.id }
        areaProjects.move(fromOffsets: source, toOffset: destination)
        
        let otherProjects = viewModel.projects.filter { $0.areaId != area.id }
        viewModel.projects = otherProjects + areaProjects
        
        if let firstProject = viewModel.projects.first {
            viewModel.updateProject(firstProject)
        }
    }
    
    private func moveOrphanProjects(from source: IndexSet, to destination: Int) {
        var orphanProjects = viewModel.projects.filter { $0.areaId == nil }
        orphanProjects.move(fromOffsets: source, toOffset: destination)
        
        let areaProjects = viewModel.projects.filter { $0.areaId != nil }
        viewModel.projects = areaProjects + orphanProjects
        
        if let firstProject = viewModel.projects.first {
            viewModel.updateProject(firstProject)
        }
    }
}