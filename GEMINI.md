# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS/macOS application demonstrating Apple's Foundation Models framework for on-device AI. The project includes multiple demo apps:
- **Foundation Lab**: Main demo app showcasing various AI capabilities
- **Physiqa**: Health-focused AI assistant (previously "Body Buddy")
- **Psylean**: Pokémon analysis AI assistant
- **Murmer**: Experimental app

### Recent Updates (January 2025)
- **Tasks Management System**: Complete task management with Projects and Areas
  - Areas: Organizational containers for grouping related projects
  - Projects: Collections of tasks with deadlines and progress tracking
  - Drag & drop support for reordering Areas/Projects and assigning Projects to Areas
  - Inline creation/editing for both Areas and Projects
  - Swipe actions with confirmation dialogs for deletion
  - iCloud sync support for data persistence

## Development Commands

### Build & Run
- Open `FoundationLab.xcodeproj` in Xcode 26.0+
- Select target (Foundation Lab, Physiqa, Psylean, or Murmer)
- Build: ⌘+B
- Run: ⌘+R
- Clean: ⌘+Shift+K

### Testing
- Run tests: ⌘+U
- Run specific test: Click diamond next to test method in Xcode

### Requirements
- Xcode 26.0+ (Beta 2)
- iOS 26.0+ / macOS 26.0+ / visionOS support
- Apple Silicon Mac or iOS device
- Apple Intelligence must be enabled

## Architecture

### Core Structure
```
Foundation Lab/
├── AppIntents/          # Siri shortcuts and app intents
├── Models/              # Data models, AI configurations
│   └── TaskModels.swift # Task, Project, Area models with Transferable support
├── ViewModels/          # MVVM view models with @Observable
│   └── TasksViewModel.swift # Main tasks management with iCloud sync
├── Views/               # SwiftUI views organized by feature
│   └── Tasks/           # Task management views
│       ├── TasksView.swift # Main tasks list with Areas/Projects
│       ├── InlineAreaCreationView.swift # Inline area creation
│       ├── InlineProjectCreationView.swift # Inline project creation
│       ├── EditAreaView.swift # Area editing (name, icon, color)
│       ├── EditProjectView.swift # Project editing with area assignment
│       ├── DraggableAreaView.swift # Drag & drop enabled area view
│       ├── DraggableProjectView.swift # Drag & drop enabled project view
│       ├── AreaSectionView.swift # Area section with projects
│       └── OrphanProjectsSection.swift # Projects without areas
├── Services/            # External integrations (Exa search)
├── Tools/               # AI tool implementations
└── Playgrounds/         # Example implementations
```

### Key Patterns
- **MVVM Architecture**: Views bind to ViewModels using @Observable
- **AI Integration**: Uses FoundationModels framework with type-safe `@Generable` protocol
- **Tool System**: Extensible tools conforming to `Tool` protocol for AI capabilities
- **Platform Adaptive**: Shared codebase with platform-specific UI adaptations

### AI Tool System
Tools extend AI capabilities by conforming to `Tool` protocol:
- Weather (OpenMeteo API)
- Web Search (Exa AI - requires API key)
- Calendar, Contacts, Health, Location, Music, Reminders (iOS integrations)

### Model Configuration
- Models configured in `Models/ModelConfiguration.swift`
- Generation guides in `Models/GenerationGuides/`
- Streaming and async generation support

## Important Implementation Details

### Adding New Features
1. For new AI tools: Create in `Tools/` directory conforming to `Tool` protocol
2. For new views: Add to appropriate subdirectory in `Views/`
3. Update model configurations in `ModelConfiguration.swift` if needed

### Tasks System Implementation
- **Areas & Projects**: Hierarchical organization with Areas containing Projects
- **Drag & Drop**: Uses Transferable protocol with ProxyRepresentation for ID-based transfers
- **Inline Editing**: FocusState management for seamless creation/editing experience
- **Swipe Actions**: Delete and Edit with confirmation dialogs
- **State Management**: Multiple @State variables for creation/editing modes
- **iCloud Sync**: Automatic persistence through TasksViewModel

### API Keys
- Exa AI key needed for web search: Set in `Services/ExaService.swift`
- Keys should be stored securely, not committed to repository

### Platform Considerations
- Use `#if os(iOS)` for platform-specific code
- Test on both iOS and macOS targets
- Consider visionOS compatibility for new features

### Common Patterns
- Error handling for model unavailability
- Streaming response handling with AsyncStream
- Type-safe generation with Generable protocol
- Observable state management for real-time updates

## Code Implementation Guidelines

### Avoid Mockup Functions
- **NEVER create placeholder or mockup functions** - all code should be fully functional
- Implement complete functionality for every method and computed property
- If external dependencies are needed, use real APIs or services
- For development/testing, use actual test data rather than hardcoded mockups

### Cross-Platform Compatibility
- **Ensure all code works on both iOS and macOS** without modification
- Use platform-agnostic SwiftUI components when possible
- When platform-specific code is necessary:
  ```swift
  #if os(iOS)
  // iOS-specific implementation
  #elseif os(macOS)
  // macOS-specific implementation
  #endif
  ```
- Test UI layouts on both platforms to ensure proper rendering
- Use `@Environment(\.horizontalSizeClass)` for adaptive layouts
- Avoid UIKit/AppKit imports unless absolutely necessary
- Prefer SwiftUI native solutions over platform-specific frameworks

### Debugging and Monitoring
- **Add debugging logs to all key operations** for easy monitoring and troubleshooting
- Use descriptive log messages that include:
  - Operation being performed
  - Key parameters/data
  - Success/failure states
- Example pattern:
  ```swift
  func addProject(_ project: Project) {
      print("📝 Adding project: \(project.name) with ID: \(project.id)")
      print("   Area: \(project.areaId?.uuidString ?? "none")")
      projects.append(project)
      saveToiCloudIfEnabled()
      print("✅ Project added successfully")
  }
  ```
- Log categories to include:
  - Data operations (create, update, delete)
  - State changes
  - User interactions
  - Sync operations
  - Error conditions
- Use emoji prefixes for visual clarity:
  - 📝 for create/add operations
  - ✏️ for update operations
  - 🗑️ for delete operations
  - 🔄 for sync operations
  - ❌ for errors
  - ✅ for success confirmations