import Foundation
import CloudKit

@Observable
final class iCloudService {
    static let shared = iCloudService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let recordType = "Task"
    private let customZoneID = CKRecordZone.ID(zoneName: "TasksZone", ownerName: CKCurrentUserDefaultName)
    private var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "serverChangeToken") else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
        }
        set {
            guard let token = newValue else {
                UserDefaults.standard.removeObject(forKey: "serverChangeToken")
                return
            }
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: "serverChangeToken")
            }
        }
    }
    
    var iCloudEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudEnabled") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "iCloudEnabled")
            if newValue {
                Task { @MainActor in
                    setupiCloud()
                }
            }
        }
    }
    
    var isSyncing = false
    private var syncDebounceTimer: Timer?
    private var hasInitialSchemaMismatch = false
    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastSyncDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastSyncDate") }
    }
    
    var syncError: Error?
    
    private init() {
        // Use default container to avoid configuration issues
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        
        // Log container info for debugging
        print("Using CloudKit container: \(container.containerIdentifier ?? "default")")
    }
    
    func setupiCloud() {
        Task {
            do {
                try await checkiCloudAccountStatus()
                try await createCustomZoneIfNeeded()
                print("iCloud setup completed successfully")
            } catch {
                print("iCloud setup failed: \(error)")
                await MainActor.run {
                    self.syncError = error
                }
            }
        }
    }
    
    private func createCustomZoneIfNeeded() async throws {
        let customZone = CKRecordZone(zoneID: customZoneID)
        do {
            let savedZone = try await privateDatabase.save(customZone)
            print("✅ Custom zone created successfully: \(savedZone.zoneID.zoneName)")
        } catch let error as CKError {
            if error.code == .zoneNotFound || error.code == .serverRecordChanged {
                print("ℹ️ Zone already exists: \(customZoneID.zoneName)")
            } else {
                print("❌ Failed to create zone: \(error.localizedDescription)")
                print("   Error code: \(error.code)")
                print("   Error info: \(error.userInfo)")
                throw error
            }
        }
    }
    
    private func checkiCloudAccountStatus() async throws {
        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                print("iCloud account status: \(status)")
                throw iCloudError.accountNotAvailable
            }
        } catch {
            print("Error checking iCloud account status: \(error)")
            throw error
        }
    }
    
    func saveTasks(_ tasks: [TodoTask], projects: [Project], areas: [Area]) async throws {
        guard !isSyncing else { 
            throw iCloudError.syncInProgress 
        }
        
        await MainActor.run { self.isSyncing = true }
        defer { 
            Task { @MainActor in 
                self.isSyncing = false
                self.syncError = nil
            }
        }
        
        print("💾 Preparing data for iCloud export:")
        print("  - Areas: \(areas.count)")
        print("  - Projects: \(projects.count)")
        print("  - Tasks: \(tasks.count)")
        
        // First, fetch existing records to determine which ones to update vs insert
        let existingRecords = try await fetchExistingRecords()
        var records: [CKRecord] = []
        
        // Save AI Learning Data
        let aiLearningData = AILearningDataManager.shared.collectLearningData()
        let aiRecordID = CKRecord.ID(recordName: "AILearningData", zoneID: customZoneID)
        
        if let existingAIRecord = existingRecords[aiRecordID.recordName] {
            // Update existing record
            let aiRecord = existingAIRecord
            if let encodedData = try? JSONEncoder().encode(aiLearningData) {
                aiRecord["data"] = encodedData
                aiRecord["lastUpdated"] = aiLearningData.lastUpdated
                aiRecord["version"] = aiLearningData.version
                records.append(aiRecord)
                print("📊 Updated existing AI learning data for iCloud sync")
            }
        } else {
            // Create new record
            let aiRecord = CKRecord(recordType: "AILearning", recordID: aiRecordID)
            if let encodedData = try? JSONEncoder().encode(aiLearningData) {
                aiRecord["data"] = encodedData
                aiRecord["lastUpdated"] = aiLearningData.lastUpdated
                aiRecord["version"] = aiLearningData.version
                records.append(aiRecord)
                print("📊 Created new AI learning data for iCloud sync")
            }
        }
        
        for area in areas {
            let recordID = CKRecord.ID(recordName: area.id.uuidString, zoneID: customZoneID)
            let record = existingRecords[recordID.recordName] ?? CKRecord(recordType: "Area", recordID: recordID)
            record["name"] = area.name
            record["icon"] = area.icon
            record["color"] = area.color
            record["createdAt"] = area.createdAt
            record["modifiedAt"] = Date()
            records.append(record)
        }
        
        for project in projects {
            let recordID = CKRecord.ID(recordName: project.id.uuidString, zoneID: customZoneID)
            let record = existingRecords[recordID.recordName] ?? CKRecord(recordType: "Project", recordID: recordID)
            record["name"] = project.name
            record["notes"] = project.notes
            record["color"] = project.color
            record["icon"] = project.icon
            record["areaID"] = project.areaId?.uuidString
            record["deadline"] = project.deadline
            record["createdAt"] = project.createdAt
            record["modifiedAt"] = Date()
            records.append(record)
            print("🗂️ Prepared project for iCloud: '\(project.name)' (ID: \(project.id)) - \(existingRecords[recordID.recordName] != nil ? "UPDATE" : "INSERT")")
        }
        
        for task in tasks {
            let recordID = CKRecord.ID(recordName: task.id.uuidString, zoneID: customZoneID)
            let record = existingRecords[recordID.recordName] ?? CKRecord(recordType: recordType, recordID: recordID)
            
            // Update all task fields
            record["title"] = task.title
            record["notes"] = task.notes
            record["isCompleted"] = task.isCompleted ? 1 : 0
            record["completionDate"] = task.completionDate
            record["projectID"] = task.projectId?.uuidString
            record["tags"] = task.tags
            record["dueDate"] = task.dueDate
            record["scheduledDate"] = task.scheduledDate
            record["priority"] = task.priority.rawValue
            record["estimatedDuration"] = task.estimatedDuration
            record["createdAt"] = task.createdAt
            record["modifiedAt"] = Date()
            record["recurrenceRule"] = task.recurrenceRule?.rawValue
            record["parentTaskId"] = task.parentTaskId?.uuidString
            record["startedAt"] = task.startedAt
            
            if let customRecurrence = task.customRecurrence,
               let customData = try? JSONEncoder().encode(customRecurrence) {
                record["customRecurrence"] = customData
            }
            
            if !task.checklistItems.isEmpty {
                let checklistData = try? JSONEncoder().encode(task.checklistItems)
                record["checklistItems"] = checklistData
            }
            
            records.append(record)
        }
        
        let chunkedRecords = records.chunked(into: 400)
        for chunk in chunkedRecords {
            do {
                let result = try await privateDatabase.modifyRecords(saving: chunk, deleting: [])
                print("✅ Successfully saved \(chunk.count) records to iCloud")
                
                // Log any partial failures
                let failures = result.saveResults.compactMap({ (key, value) -> String? in
                    if case .failure(let error) = value {
                        return "Failed to save \(key.recordName): \(error.localizedDescription)"
                    }
                    return nil
                })
                if !failures.isEmpty {
                    print("⚠️ Some records failed to save:")
                    failures.forEach { print("  - \($0)") }
                }
            } catch {
                print("❌ Failed to save chunk of \(chunk.count) records: \(error)")
                throw error
            }
        }
        
        await MainActor.run {
            self.lastSyncDate = Date()
            self.syncError = nil
            self.hasInitialSchemaMismatch = false
        }
    }
    
    private func fetchExistingRecords() async throws -> [String: CKRecord] {
        print("🔍 Fetching existing records from iCloud...")
        let (_, _, _) = try await fetchTasks()
        
        // Fetch all records to build a map of existing records
        let changesOp = CKFetchRecordZoneChangesOperation()
        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration(
            previousServerChangeToken: nil,
            resultsLimit: nil,
            desiredKeys: nil
        )
        changesOp.configurationsByRecordZoneID = [customZoneID: config]
        changesOp.recordZoneIDs = [customZoneID]
        changesOp.fetchAllChanges = true
        
        var existingRecords: [String: CKRecord] = [:]
        
        changesOp.recordWasChangedBlock = { recordID, result in
            switch result {
            case .success(let record):
                existingRecords[recordID.recordName] = record
            case .failure(let error):
                print("Error fetching existing record \(recordID): \(error)")
            }
        }
        
        changesOp.recordZoneFetchResultBlock = { zoneID, result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error fetching zone changes: \(error)")
            }
        }
        
        privateDatabase.add(changesOp)
        
        try await withCheckedThrowingContinuation { continuation in
            changesOp.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    print("✅ Fetched \(existingRecords.count) existing records")
                    continuation.resume()
                case .failure(let error):
                    print("❌ Failed to fetch existing records: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
        
        return existingRecords
    }
    
    func fetchTasks(forceFullFetch: Bool = false) async throws -> (tasks: [TodoTask], projects: [Project], areas: [Area]) {
        await MainActor.run { self.isSyncing = true }
        defer { Task { @MainActor in self.isSyncing = false } }
        
        var areas: [Area] = []
        var projects: [Project] = []
        var tasks: [TodoTask] = []
        
        // Use CKFetchRecordZoneChangesOperation to avoid queryable field issues
        let changesOp = CKFetchRecordZoneChangesOperation()
        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration(
            previousServerChangeToken: forceFullFetch ? nil : serverChangeToken,
            resultsLimit: nil,
            desiredKeys: nil
        )
        
        if forceFullFetch {
            print("🔄 Force full fetch requested - ignoring previous change token")
        }
        changesOp.configurationsByRecordZoneID = [customZoneID: config]
        changesOp.recordZoneIDs = [customZoneID]
        changesOp.fetchAllChanges = true
        
        var fetchedRecords: [CKRecord] = []
        
        changesOp.recordWasChangedBlock = { recordID, result in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
            case .failure(let error):
                print("Error fetching record \(recordID): \(error)")
            }
        }
        
        changesOp.recordZoneChangeTokensUpdatedBlock = { _, token, _ in
            Task { @MainActor in
                self.serverChangeToken = token
            }
        }
        
        changesOp.recordZoneFetchResultBlock = { zoneID, result in
            switch result {
            case .success(let (token, _, _)):
                Task { @MainActor in
                    self.serverChangeToken = token
                }
            case .failure(let error):
                print("Error fetching zone changes: \(error)")
            }
        }
        
        changesOp.fetchRecordZoneChangesResultBlock = { result in
            if case .failure(let error) = result {
                print("Fetch operation failed: \(error)")
            }
        }
        
        privateDatabase.add(changesOp)
        
        // Wait for operation to complete
        try await withCheckedThrowingContinuation { continuation in
            changesOp.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    print("✅ Successfully fetched \(fetchedRecords.count) records from iCloud")
                    continuation.resume()
                case .failure(let error):
                    print("❌ Failed to fetch records from iCloud: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
        
        // Process fetched records
        var aiLearningRecord: CKRecord?
        
        for record in fetchedRecords {
            switch record.recordType {
            case "Area":
                if let area = recordToArea(record) {
                    areas.append(area)
                }
            case "Project":
                if let project = recordToProject(record) {
                    projects.append(project)
                }
            case "AILearning":
                aiLearningRecord = record
            case recordType:
                if let task = recordToTask(record) {
                    tasks.append(task)
                }
            default:
                break
            }
        }
        
        // Process AI Learning Data
        if let aiRecord = aiLearningRecord,
           let encodedData = aiRecord["data"] as? Data,
           let aiLearningData = try? JSONDecoder().decode(AILearningData.self, from: encodedData) {
            AILearningDataManager.shared.distributeLearningData(aiLearningData)
            print("📊 AI learning data restored from iCloud")
        }
        
        await MainActor.run {
            self.lastSyncDate = Date()
            self.syncError = nil
        }
        
        print("📊 iCloud fetch completed:")
        print("  - Areas: \(areas.count)")
        print("  - Projects: \(projects.count)")
        print("  - Tasks: \(tasks.count)")
        
        // Log some sample data for debugging
        if let firstProject = projects.first {
            print("  - Sample project: '\(firstProject.name)' (ID: \(firstProject.id))")
        }
        if let firstArea = areas.first {
            print("  - Sample area: '\(firstArea.name)' (ID: \(firstArea.id))")
        }
        
        return (tasks, projects, areas)
    }
    
    private func performQuery(_ query: CKQuery) async throws -> [CKRecord] {
        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?
        
        // Create operation instead of using direct query to avoid recordName issues
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 100
        operation.desiredKeys = nil // Fetch all fields
        operation.qualityOfService = .userInitiated
        
        // Collect records
        var tempRecords: [CKRecord] = []
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                tempRecords.append(record)
            case .failure(let error):
                print("Error fetching record \(recordID): \(error)")
            }
        }
        
        // Handle completion
        operation.queryResultBlock = { result in
            switch result {
            case .success(let queryCursor):
                cursor = queryCursor
                allRecords.append(contentsOf: tempRecords)
                tempRecords.removeAll()
            case .failure(let error):
                print("Query operation failed: \(error)")
            }
        }
        
        // Execute first operation
        privateDatabase.add(operation)
        
        // Wait for operation to complete
        try await withCheckedThrowingContinuation { continuation in
            operation.queryResultBlock = { result in
                switch result {
                case .success(let queryCursor):
                    cursor = queryCursor
                    allRecords.append(contentsOf: tempRecords)
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        // Handle cursor for pagination
        while let currentCursor = cursor {
            cursor = nil
            tempRecords.removeAll()
            
            let cursorOperation = CKQueryOperation(cursor: currentCursor)
            cursorOperation.resultsLimit = 100
            cursorOperation.qualityOfService = .userInitiated
            
            cursorOperation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    tempRecords.append(record)
                case .failure(let error):
                    print("Error fetching record \(recordID): \(error)")
                }
            }
            
            privateDatabase.add(cursorOperation)
            
            try await withCheckedThrowingContinuation { continuation in
                cursorOperation.queryResultBlock = { result in
                    switch result {
                    case .success(let queryCursor):
                        cursor = queryCursor
                        allRecords.append(contentsOf: tempRecords)
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        return allRecords
    }
    
    func deleteAllData() async throws {
        await MainActor.run { self.isSyncing = true }
        defer { Task { @MainActor in self.isSyncing = false } }
        
        // Delete the entire zone
        do {
            _ = try await privateDatabase.deleteRecordZone(withID: customZoneID)
            // Reset the change token
            await MainActor.run {
                serverChangeToken = nil
            }
            print("Deleted custom zone and all data")
            
            // Recreate the zone for future use
            try await createCustomZoneIfNeeded()
        } catch {
            print("Error deleting zone: \(error)")
            throw error
        }
        
        await MainActor.run {
            self.lastSyncDate = Date()
            self.syncError = nil
        }
    }
    
    private func taskToRecord(_ task: TodoTask) -> CKRecord {
        let recordID = CKRecord.ID(recordName: task.id.uuidString, zoneID: customZoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["title"] = task.title
        record["notes"] = task.notes
        record["isCompleted"] = task.isCompleted ? 1 : 0
        record["completionDate"] = task.completionDate
        record["projectID"] = task.projectId?.uuidString
        record["tags"] = task.tags
        record["dueDate"] = task.dueDate
        record["scheduledDate"] = task.scheduledDate
        record["priority"] = task.priority.rawValue
        record["estimatedDuration"] = task.estimatedDuration
        record["createdAt"] = task.createdAt
        record["modifiedAt"] = Date()
        
        // Add recurrence fields
        record["recurrenceRule"] = task.recurrenceRule?.rawValue
        if let customRecurrence = task.customRecurrence,
           let customData = try? JSONEncoder().encode(customRecurrence) {
            record["customRecurrence"] = customData
        }
        record["parentTaskId"] = task.parentTaskId?.uuidString
        
        // Add duration tracking field
        record["startedAt"] = task.startedAt
        
        if !task.checklistItems.isEmpty {
            let checklistData = try? JSONEncoder().encode(task.checklistItems)
            record["checklistItems"] = checklistData
        }
        
        return record
    }
    
    private func recordToTask(_ record: CKRecord) -> TodoTask? {
        guard let title = record["title"] as? String, !title.isEmpty else { 
            print("Skipping task record with missing or empty title")
            return nil 
        }
        
        var task = TodoTask(title: title)
        
        // Safely extract all fields
        task.notes = record["notes"] as? String ?? ""
        
        if let projectIDString = record["projectID"] as? String {
            task.projectId = UUID(uuidString: projectIDString)
        }
        
        task.tags = record["tags"] as? [String] ?? []
        task.dueDate = record["dueDate"] as? Date
        task.scheduledDate = record["scheduledDate"] as? Date
        
        let priorityString = record["priority"] as? String ?? "none"
        task.priority = TodoTask.Priority(rawValue: priorityString) ?? .none
        
        task.estimatedDuration = record["estimatedDuration"] as? TimeInterval
        
        if let id = UUID(uuidString: record.recordID.recordName) {
            task.id = id
        }
        
        task.isCompleted = (record["isCompleted"] as? Int ?? 0) == 1
        task.completionDate = record["completionDate"] as? Date
        task.createdAt = record["createdAt"] as? Date ?? Date()
        
        // Read recurrence fields
        if let recurrenceRuleString = record["recurrenceRule"] as? String {
            task.recurrenceRule = RecurrenceRule(rawValue: recurrenceRuleString)
        }
        
        if let customRecurrenceData = record["customRecurrence"] as? Data {
            do {
                task.customRecurrence = try JSONDecoder().decode(CustomRecurrence.self, from: customRecurrenceData)
            } catch {
                print("Failed to decode custom recurrence: \(error)")
            }
        }
        
        if let parentTaskIdString = record["parentTaskId"] as? String {
            task.parentTaskId = UUID(uuidString: parentTaskIdString)
        }
        
        // Read duration tracking field
        task.startedAt = record["startedAt"] as? Date
        
        if let checklistData = record["checklistItems"] as? Data {
            do {
                task.checklistItems = try JSONDecoder().decode([ChecklistItem].self, from: checklistData)
            } catch {
                print("Failed to decode checklist items: \(error)")
                task.checklistItems = []
            }
        }
        
        return task
    }
    
    private func recordToProject(_ record: CKRecord) -> Project? {
        guard let name = record["name"] as? String, !name.isEmpty else { 
            print("Skipping project record with missing or empty name")
            return nil 
        }
        
        var project = Project(name: name)
        project.notes = record["notes"] as? String ?? ""
        project.color = record["color"] as? String ?? "blue"
        project.icon = record["icon"] as? String ?? "folder"
        
        if let areaIDString = record["areaID"] as? String {
            project.areaId = UUID(uuidString: areaIDString)
        }
        
        if let id = UUID(uuidString: record.recordID.recordName) {
            project.id = id
        }
        
        project.createdAt = record["createdAt"] as? Date ?? Date()
        
        // Validate deadline if present
        if let deadline = record["deadline"] as? Date {
            project.deadline = deadline
        }
        
        return project
    }
    
    private func recordToArea(_ record: CKRecord) -> Area? {
        guard let name = record["name"] as? String, !name.isEmpty else { 
            print("Skipping area record with missing or empty name")
            return nil 
        }
        
        var area = Area(name: name)
        area.icon = record["icon"] as? String ?? "square.stack.3d.up"
        area.color = record["color"] as? String ?? "blue"
        
        if let id = UUID(uuidString: record.recordID.recordName) {
            area.id = id
        }
        
        area.createdAt = record["createdAt"] as? Date ?? Date()
        
        return area
    }
    
    func debouncedSaveTasks(_ tasks: [TodoTask], projects: [Project], areas: [Area]) {
        syncDebounceTimer?.invalidate()
        
        syncDebounceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Task {
                do {
                    try await self.saveTasks(tasks, projects: projects, areas: areas)
                } catch {
                    print("Debounced save failed: \(error)")
                }
            }
        }
    }
    
    func resetCloudKitConfiguration() {
        Task { @MainActor in
            // Clear all CloudKit related settings
            UserDefaults.standard.removeObject(forKey: "iCloudEnabled")
            UserDefaults.standard.removeObject(forKey: "lastSyncDate")
            UserDefaults.standard.removeObject(forKey: "serverChangeToken")
            UserDefaults.standard.synchronize()
            hasInitialSchemaMismatch = false
            serverChangeToken = nil
            print("CloudKit configuration reset")
        }
    }
    
    // MARK: - Generic Key-Value Storage
    
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    
    func setData(_ data: Data, forKey key: String) {
        guard iCloudEnabled else { return }
        keyValueStore.set(data, forKey: key)
        keyValueStore.synchronize()
    }
    
    func getData(forKey key: String) -> Data? {
        guard iCloudEnabled else { return nil }
        return keyValueStore.data(forKey: key)
    }
    
    func setString(_ string: String, forKey key: String) {
        guard iCloudEnabled else { return }
        keyValueStore.set(string, forKey: key)
        keyValueStore.synchronize()
    }
    
    func getString(forKey key: String) -> String? {
        guard iCloudEnabled else { return nil }
        return keyValueStore.string(forKey: key)
    }
    
    func removeData(forKey key: String) {
        keyValueStore.removeObject(forKey: key)
        keyValueStore.synchronize()
    }
}

enum iCloudError: LocalizedError {
    case accountNotAvailable
    case syncInProgress
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
        case .syncInProgress:
            return "Sync is already in progress. Please wait."
        case .dataCorrupted:
            return "Data could not be read from iCloud."
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
