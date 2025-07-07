# iCloud Setup Instructions for Foundation Lab

## Configuration Steps in Xcode

1. **Update Bundle Identifier**
   - Open the project in Xcode
   - Select your project in the navigator
   - Go to the "Signing & Capabilities" tab
   - Update the Bundle Identifier to match your organization (replace `com.yourcompany.FoundationLab`)

2. **Configure iCloud Container**
   - In "Signing & Capabilities" tab, the iCloud capability has been added
   - Click the "+" button next to "iCloud Containers"
   - Use the default container or create a custom one matching your bundle ID
   - Update the container identifier in `iCloudService.swift` line 23:
     ```swift
     container = CKContainer(identifier: "iCloud.YOUR_ACTUAL_BUNDLE_ID")
     ```

3. **Enable CloudKit in App Store Connect** (for App Store distribution)
   - Go to App Store Connect
   - Select your app
   - Go to "App Information" → "Capabilities"
   - Enable CloudKit

## Features Implemented

### iCloud Sync
- Automatic sync when enabled in Settings
- Manual sync option
- Last sync timestamp display
- Progress indicator during sync

### Data Management
- **Export to iCloud**: Creates a backup of all tasks to iCloud
- **Import from iCloud**: Replaces local data with iCloud data
- **Clear All Data**: Removes all tasks from both local storage and iCloud

### Local Storage
- Tasks are saved locally using UserDefaults (JSON encoded)
- Automatic local backup before iCloud operations
- Fallback to local storage if iCloud is unavailable

### Error Handling
- Network connectivity issues
- iCloud account not available
- Sync conflicts (last write wins)
- Data corruption protection

## Usage

1. **Enable iCloud Sync**
   - Go to Settings in the app
   - Toggle "Enable iCloud Sync"
   - Tasks will automatically sync to iCloud

2. **Manual Operations**
   - Use "Sync Now" to force a sync
   - Use "Export to iCloud" to create a backup
   - Use "Import from iCloud" to restore from backup

## Important Notes

- iCloud sync requires the user to be signed into iCloud on their device
- The app uses the private CloudKit database for security
- Tasks are synchronized across all devices using the same iCloud account
- Initial sync may take a few moments depending on the amount of data

## Testing

1. Run the app on a device or simulator with iCloud signed in
2. Create some tasks
3. Enable iCloud sync in Settings
4. Install the app on another device with the same iCloud account
5. Enable iCloud sync and verify tasks appear

## Troubleshooting

- If sync fails, check that you're signed into iCloud
- Ensure the bundle identifier and container match
- Check Xcode console for any CloudKit errors
- Try "Export to iCloud" followed by "Import from iCloud" to force a full sync