//
//  SettingsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI
import Combine

struct SettingsView: View {
  @AppStorage("exaAPIKey") private var exaAPIKey: String = ""
  @AppStorage("createTasksFromChatReminders") private var createTasksFromChatReminders: Bool = false
  @State private var tempAPIKey: String = ""
  @State private var showingAlert = false
  @State private var alertMessage = ""
  
  let tasksViewModel: TasksViewModel
  @State private var showingExportConfirmation = false
  @State private var showingImportConfirmation = false
  @State private var showingClearDataConfirmation = false
  @State private var isProcessing = false
  
  // Add state to track iCloud status
  @State private var iCloudEnabled = false
  @State private var isSyncing = false
  
  @ViewBuilder
  private var webSearchSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 8) {
        Text("Exa Web Search")
          .font(.headline)
        
        Text("Configure your Exa API key to enable web search functionality.")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.vertical, 4)
      
      VStack(alignment: .leading, spacing: 12) {
        Text("API Key")
          .font(.subheadline)
          .fontWeight(.medium)
        
        SecureField("Enter your Exa API key", text: $tempAPIKey)
          .textFieldStyle(.roundedBorder)
          .onAppear {
            tempAPIKey = exaAPIKey
          }
        
        HStack {
          Button("Save") {
            saveAPIKey()
          }
          .buttonStyle(.glassProminent)
          .disabled(tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          
          if !exaAPIKey.isEmpty {
            Button("Clear") {
              clearAPIKey()
            }
            .buttonStyle(.glassProminent)
            .tint(.secondary)
            .foregroundColor(.red)
          }
        }
      }
      
      if !exaAPIKey.isEmpty {
        Text("✓ API key configured")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
    } header: {
      Text("Web Search Configuration")
    } footer: {
      VStack(alignment: .leading, spacing: 8) {
        Text("Get your free Exa API key:")
        Link("https://exa.ai/api", destination: URL(string: "https://exa.ai/api")!)
          .font(.caption)
        
        Text("The API key is stored on the device and only used for web search requests.")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
  
  @ViewBuilder
  private var iCloudSection: some View {
    Section {
      Toggle("Enable iCloud Sync", isOn: $iCloudEnabled)
        .onChange(of: iCloudEnabled) { _, newValue in
          iCloudService.shared.iCloudEnabled = newValue
        }
      
      if iCloudEnabled {
        VStack(alignment: .leading, spacing: 12) {
          if let lastSync = iCloudService.shared.lastSyncDate {
            HStack {
              Text("Last synced")
              Spacer()
              Text(lastSync, style: .relative)
                .foregroundColor(.secondary)
            }
            .font(.caption)
          }
          
          if isSyncing {
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Syncing...")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          
          Button("Sync to iCloud") {
            syncToiCloud()
          }
          .buttonStyle(.glassProminent)
          .disabled(isSyncing)
        }
      }
    } header: {
      Text("iCloud Sync")
    } footer: {
      Text("Enable iCloud sync to keep your tasks backed up and synchronized across your devices. 'Sync to iCloud' uploads your local data to iCloud.")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  @ViewBuilder
  private var dataManagementSection: some View {
    Section {
      Button(action: {
        showingExportConfirmation = true
      }) {
        HStack {
          Image(systemName: "icloud.and.arrow.up")
          Text("Export to iCloud")
        }
      }
      .disabled(isProcessing || !iCloudEnabled)
      
      Button(action: {
        showingImportConfirmation = true
      }) {
        HStack {
          Image(systemName: "icloud.and.arrow.down")
          Text("Import from iCloud")
        }
      }
      .disabled(isProcessing || !iCloudEnabled)
      
      Button(action: {
        showingClearDataConfirmation = true
      }) {
        HStack {
          Image(systemName: "trash")
          Text("Clear All Data")
        }
        .foregroundColor(.red)
      }
      .disabled(isProcessing)
    } header: {
      Text("Data Management")
    } footer: {
      Text("Export uploads your tasks to iCloud. Import downloads and replaces local data with iCloud data. Clear removes all tasks from both local storage and iCloud.")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  @ViewBuilder
  private var helpSection: some View {
    Section {
      NavigationLink(destination: AIHelpView()) {
        HStack {
          Image(systemName: "sparkles")
            .foregroundColor(.purple)
          Text("AI Features Guide")
          Spacer()
          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }
      
      NavigationLink(destination: HelpTopicsView()) {
        HStack {
          Image(systemName: "questionmark.circle")
            .foregroundColor(.blue)
          Text("Help Topics")
          Spacer()
          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }
    } header: {
      Text("Help")
    } footer: {
      Text("Learn about AI-powered features and get help with using the app.")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  var body: some View {
    NavigationStack {
      Form {
        helpSection
        
        Section {
          Toggle("Create Tasks from Chat Reminders", isOn: $createTasksFromChatReminders)
        } header: {
          Text("Chat Integration")
        } footer: {
          Text("When enabled, reminders created through the Chat will also be added to your Tasks list.")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        iCloudSection
        
        dataManagementSection
        
        webSearchSection
        
        Section {
          HStack {
            Text("Made by Productroot.io Patryk Wodniak")
            Spacer()
          }
          
          HStack {
            Text("Version")
            Spacer()
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
              .foregroundColor(.secondary)
          }
        } header: {
          Text("About")
        } footer: {
          VStack(alignment: .leading, spacing: 4) {
            Text("\"Sophia\" (wisdom, feminine name) + \"Flow\" for graceful, AI-driven task workflows")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      .formStyle(.grouped)
      #if os(macOS)
      .padding()
      #endif
      .navigationTitle("Settings")
      .alert("Settings", isPresented: $showingAlert) {
        Button("OK") { }
      } message: {
        Text(alertMessage)
      }
      .confirmationDialog("Export to iCloud", isPresented: $showingExportConfirmation) {
        Button("Export") {
          exportToiCloud()
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("This will upload all your tasks to iCloud. Existing iCloud data will be replaced.")
      }
      .confirmationDialog("Import from iCloud", isPresented: $showingImportConfirmation) {
        Button("Import", role: .destructive) {
          importFromiCloud()
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("This will replace all local tasks with data from iCloud. Your current local data will be lost.")
      }
      .confirmationDialog("Clear All Data", isPresented: $showingClearDataConfirmation) {
        Button("Clear All", role: .destructive) {
          clearAllData()
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("This will permanently delete all tasks from both local storage and iCloud. This action cannot be undone.")
      }
      .onAppear {
        // Initialize the local state from the service
        iCloudEnabled = iCloudService.shared.iCloudEnabled
        isSyncing = iCloudService.shared.isSyncing
      }
      .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
        // Update local state when UserDefaults changes
        iCloudEnabled = iCloudService.shared.iCloudEnabled
      }
      .task {
        // Monitor iCloud service state changes
        for await _ in Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().values {
          isSyncing = iCloudService.shared.isSyncing
          iCloudEnabled = iCloudService.shared.iCloudEnabled
        }
      }
    }
  }
  
  private func saveAPIKey() {
    let trimmedKey = tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard !trimmedKey.isEmpty else {
      alertMessage = "Please enter a valid API key"
      showingAlert = true
      return
    }
    
    exaAPIKey = trimmedKey
    alertMessage = "API key saved successfully!"
    showingAlert = true
  }
  
  private func clearAPIKey() {
    exaAPIKey = ""
    tempAPIKey = ""
    alertMessage = "API key cleared"
    showingAlert = true
  }
  
  private func exportToiCloud() {
    isProcessing = true
    Task {
      do {
        try await tasksViewModel.exportToiCloud()
        await MainActor.run {
          alertMessage = "Tasks successfully exported to iCloud!"
          showingAlert = true
          isProcessing = false
        }
      } catch {
        await MainActor.run {
          alertMessage = "Export failed: \(error.localizedDescription)"
          showingAlert = true
          isProcessing = false
        }
      }
    }
  }
  
  private func importFromiCloud() {
    isProcessing = true
    Task {
      do {
        try await tasksViewModel.importFromiCloud()
        await MainActor.run {
          alertMessage = "Tasks successfully imported from iCloud!"
          showingAlert = true
          isProcessing = false
        }
      } catch iCloudError.syncInProgress {
        await MainActor.run {
          alertMessage = "Sync is already in progress. Please wait and try again."
          showingAlert = true
          isProcessing = false
        }
      } catch {
        await MainActor.run {
          let errorDetails = error.localizedDescription
          alertMessage = "Import failed: \(errorDetails)\n\nPlease check your iCloud connection and try again."
          showingAlert = true
          isProcessing = false
        }
      }
    }
  }
  
  private func syncToiCloud() {
    isSyncing = true
    Task {
      // Use the corrected sync function that pushes to iCloud
      tasksViewModel.syncWithiCloud()
      
      // Give a brief moment for the sync to complete
      try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
      
      await MainActor.run {
        isSyncing = false
        alertMessage = "Local data synced to iCloud successfully!"
        showingAlert = true
      }
    }
  }
  
  private func clearAllData() {
    isProcessing = true
    tasksViewModel.clearAllData()
    alertMessage = "All data has been cleared."
    showingAlert = true
    isProcessing = false
  }
}

#Preview {
  SettingsView(tasksViewModel: TasksViewModel.shared)
}
