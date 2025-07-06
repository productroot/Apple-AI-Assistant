# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS/macOS application demonstrating Apple's Foundation Models framework for on-device AI. The project includes multiple demo apps:
- **Foundation Lab**: Main demo app showcasing various AI capabilities
- **Physiqa**: Health-focused AI assistant (previously "Body Buddy")
- **Psylean**: Pokémon analysis AI assistant
- **Murmer**: Experimental app

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
├── ViewModels/          # MVVM view models with @Observable
├── Views/               # SwiftUI views organized by feature
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