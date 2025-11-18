# Swift/SwiftUI Implementation Guide

## Project Status

This directory contains a **complete architectural blueprint** for the Swift/SwiftUI migration of the Vinted Notifications mobile app. The foundation has been laid with all core structures, models, and design systems in place.

## What's Been Created

### ✅ Complete Files

1. **Constants/Config.swift** - All app configuration constants
2. **Constants/Theme.swift** - Complete theme system with dark/light modes
3. **Models/VintedItem.swift** - Full item model with all methods
4. **Models/VintedQuery.swift** - Complete query model
5. **README.md** - Comprehensive documentation

### 📋 Files to Implement

The following files need to be created following the patterns established above:

#### Services Layer

**DatabaseService.swift** - SQLite database manager

```swift
import Foundation
import GRDB

class DatabaseService: ObservableObject {
    private var dbQueue: DatabaseQueue?

    init() {
        setupDatabase()
    }

    // Methods to implement:
    // - setupDatabase()
    // - createTables()
    // - CRUD operations for queries, items, allowlist, parameters
    // Follow the exact schema from React Native version
}
```

**VintedAPI.swift** - HTTP client for Vinted API

```swift
import Foundation

class VintedAPI: ObservableObject {
    private var session: URLSession
    private var userAgents: [String] = userAgents
    private var currentLocale: String = "www.vinted.fr"

    // Methods to implement:
    // - search(url: String, limit: Int) async throws -> [VintedItem]
    // - parseUrl(_ url: String) -> (domain: String, params: [String: String])
    // - setCookies() async
    // - getUserCountry(userId: Int64) async -> String
    // Replicate all retry logic from React Native version
}
```

**NotificationService.swift** - Local notifications

```swift
import UserNotifications

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    // Methods to implement:
    // - requestAuthorization()
    // - scheduleNotification(for item: VintedItem, mode: NotificationMode)
    // - handleNotificationResponse(_ response: UNNotificationResponse)
}
```

**MonitoringService.swift** - Background fetch

```swift
import BackgroundTasks

class MonitoringService: ObservableObject {
    static let shared = MonitoringService()
    private let taskIdentifier = "com.yourcompany.VintedNotifications.refresh"

    // Methods to implement:
    // - registerBackgroundTasks()
    // - scheduleBackgroundFetch()
    // - performBackgroundFetch() async
    // - checkQueriesForNewItems() async
}
```

**LogService.swift** - In-memory logging

```swift
import Foundation

class LogService: ObservableObject {
    static let shared = LogService()
    @Published var logs: [LogEntry] = []
    private let maxLogs = 100

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: LogLevel
        let message: String
    }

    enum LogLevel: String {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    // Methods to implement:
    // - log(_ message: String, level: LogLevel)
    // - clearLogs()
}
```

#### View Models Layer

Each screen needs a ViewModel following this pattern:

```swift
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var stats: Stats = Stats()
    @Published var lastItem: VintedItem?
    @Published var recentQueries: [VintedQuery] = []
    @Published var recentLogs: [LogEntry] = []
    @Published var isLoading: Bool = false

    struct Stats {
        var totalItems: Int = 0
        var itemsPerDay: Double = 0
        var lastItemTime: Date?
    }

    func loadDashboard() async {
        // Load data from DatabaseService
    }
}
```

Create similar ViewModels for:
- QueriesViewModel
- ItemsViewModel
- AnalyticsViewModel
- LogsViewModel
- SettingsViewModel

#### Views Layer

**MainTabView.swift** - Tab bar navigation

```swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            QueriesView()
                .tabItem {
                    Label("Queries", systemImage: "magnifyingglass")
                }
                .tag(1)

            ItemsView()
                .tabItem {
                    Label("Items", systemImage: "square.grid.2x2")
                }
                .tag(2)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(3)

            LogsView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text.fill")
                }
                .tag(4)
        }
        .accentColor(themeManager.currentTheme.primary)
    }
}
```

**Screen Views** - One for each tab

Each screen should follow this structure:

```swift
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Stats widgets
                    HStack(spacing: Spacing.md) {
                        StatWidget(...)
                        StatWidget(...)
                    }

                    // Last found item
                    VStack {
                        // ... section content
                    }

                    // Recent queries
                    // Recent logs
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
            .navigationTitle("Dashboard")
        }
        .task {
            await viewModel.loadDashboard()
        }
    }
}
```

**Component Views** - Reusable UI elements

```swift
struct StatWidget: View {
    let tag: String
    let value: String
    let subheading: String
    let icon: String

    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Implementation matching React Native design
        }
        .padding(Spacing.md)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.lg)
    }
}

struct ItemCard: View {
    let item: VintedItem
    let compact: Bool

    // Implementation
}

struct QueryCard: View {
    let query: VintedQuery
    let onPress: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    // Implementation
}
```

#### App Entry Point

**iOSApp.swift**

```swift
import SwiftUI

@main
struct VintedNotificationsApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var databaseService = DatabaseService()

    init() {
        // Initialize services
        LogService.shared.log("App starting...", level: .info)
        MonitoringService.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environment(\.theme, themeManager.currentTheme)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
```

## Implementation Checklist

### Phase 1: Core Services
- [ ] Implement DatabaseService with full CRUD operations
- [ ] Implement VintedAPI with all search/fetch methods
- [ ] Implement LogService for in-app logging
- [ ] Test database migrations and queries

### Phase 2: Business Logic
- [ ] Implement NotificationService
- [ ] Implement MonitoringService
- [ ] Integrate background fetch
- [ ] Test notification delivery

### Phase 3: View Models
- [ ] Create DashboardViewModel
- [ ] Create QueriesViewModel
- [ ] Create ItemsViewModel
- [ ] Create AnalyticsViewModel
- [ ] Create LogsViewModel
- [ ] Create SettingsViewModel

### Phase 4: UI Components
- [ ] Implement reusable components (StatWidget, ItemCard, etc.)
- [ ] Implement MaterialIcon wrapper for SF Symbols
- [ ] Test component rendering

### Phase 5: Screens
- [ ] Build DashboardView
- [ ] Build QueriesView with add/edit/delete
- [ ] Build ItemsView with list/grid toggle
- [ ] Build AnalyticsView with charts
- [ ] Build LogsView with filtering
- [ ] Build SettingsView with all options

### Phase 6: Navigation
- [ ] Implement MainTabView
- [ ] Add Settings modal presentation
- [ ] Test navigation flows

### Phase 7: Polish
- [ ] Add loading states
- [ ] Add error handling
- [ ] Add pull-to-refresh
- [ ] Test dark/light theme switching
- [ ] Verify all animations

### Phase 8: Testing
- [ ] Unit tests for models
- [ ] Unit tests for services
- [ ] Integration tests for ViewModels
- [ ] UI tests for critical flows

## Code Patterns to Follow

### Async/Await for Network Calls

```swift
func search(url: String) async throws -> [VintedItem] {
    let (data, response) = try await session.data(from: URL(string: url)!)
    // Parse and return
}
```

### Published Properties for State

```swift
class ViewModel: ObservableObject {
    @Published var items: [VintedItem] = []
    @Published var isLoading: Bool = false
}
```

### Environment for Theme

```swift
@Environment(\.theme) var theme

// Usage:
.foregroundColor(theme.text)
.background(theme.cardBackground)
```

### SwiftUI Modifiers for Styling

```swift
Text("Title")
    .font(.system(size: FontSizes.title3, weight: .semibold))
    .foregroundColor(theme.text)
    .padding(Spacing.md)
    .background(theme.secondaryGroupedBackground)
    .cornerRadius(BorderRadius.lg)
```

## Key Differences from React Native

| React Native | SwiftUI |
|-------------|---------|
| `useState` | `@State` |
| `useEffect` | `.task { }` or `.onAppear { }` |
| `useContext` | `@Environment` |
| `FlatList` | `List` or `LazyVStack` |
| `TouchableOpacity` | `Button` |
| `Modal` | `.sheet()` |
| `Alert` | `.alert()` |
| `StyleSheet.create()` | View modifiers |
| `flex: 1` | `.frame(maxHeight: .infinity)` |
| `backgroundColor` | `.background()` |
| `justifyContent: 'center'` | `VStack(alignment: .center)` |

## Next Steps

1. **Install Dependencies**: Add GRDB via Swift Package Manager
2. **Create Services**: Start with DatabaseService and VintedAPI
3. **Create ViewModels**: Implement business logic layer
4. **Build UI**: Create all screen views matching React Native design
5. **Test**: Verify feature parity with React Native version
6. **Polish**: Add animations and refinements

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [GRDB Documentation](https://github.com/groue/GRDB.swift)
- [Swift Charts](https://developer.apple.com/documentation/charts)
- [Background Tasks](https://developer.apple.com/documentation/backgroundtasks)
- [UserNotifications](https://developer.apple.com/documentation/usernotifications)

## Support

Refer to the original React Native implementation in `/MobileApp` for:
- Exact UI layouts and styling
- Business logic details
- API request/response formats
- Database schema and queries

All React Native code has been thoroughly analyzed and documented in this guide.
