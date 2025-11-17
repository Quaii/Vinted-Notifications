# Vinted Notifications - iOS Mobile App

A React Native mobile application for iOS that monitors Vinted listings and sends push notifications when new items matching your search criteria are posted.

## Features

- **Real-time Monitoring**: Continuously monitors your Vinted search queries for new items
- **Push Notifications**: Instant notifications when new items are found
- **Background Fetch**: Checks for new items even when the app is closed (iOS)
- **Multi-Query Support**: Track multiple search queries simultaneously
- **Advanced Filtering**:
  - Country allowlist (filter by seller location)
  - Banwords filter (exclude items with specific keywords)
- **Customizable Settings**:
  - Adjustable refresh intervals
  - Configurable items per query
  - Custom notification message templates
- **Modern UI**: Clean, user-friendly interface with statistics and item browsing
- **Local Storage**: SQLite database for offline access to found items

## What's Different from the Python Version?

This mobile app is a complete conversion of the Python Vinted-Notifications project with the following changes:

**Removed Features:**
- Telegram bot integration
- RSS feed support

**Converted Features:**
- All core monitoring functionality
- Vinted API integration
- Search query management
- Item filtering (allowlist, banwords)
- Notification system (using native push notifications instead of Telegram)
- Web UI (converted to native mobile screens)
- Database storage (SQLite)
- Configuration settings

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v16 or higher)
- **npm** or **yarn**
- **Xcode** (for iOS development)
- **CocoaPods** (for iOS dependencies)
- **React Native CLI**

### Install Prerequisites

```bash
# Install Node.js (using Homebrew on macOS)
brew install node

# Install Watchman
brew install watchman

# Install CocoaPods
sudo gem install cocoapods

# Install React Native CLI
npm install -g react-native-cli
```

## Installation

1. **Navigate to the MobileApp directory**:
   ```bash
   cd MobileApp
   ```

2. **Install Node dependencies**:
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Install iOS dependencies**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

## Running the App

### iOS

**IMPORTANT**: This app has been configured to work WITHOUT Metro bundler. You don't need to run `npm start`.

1. **Bundle the JavaScript code** (required before first run and after any code changes):
   ```bash
   npm run bundle:ios
   ```

2. **Run the iOS app**:
   ```bash
   npm run ios
   # or open in Xcode
   open ios/VintedNotifications.xcworkspace
   ```

**Note**: After making any code changes to JavaScript files, you must run `npm run bundle:ios` again to rebuild the bundle before running the app.

## Building for Production

The app is already configured to use bundled JavaScript. For production builds (TestFlight, App Store):

### Option 1: Quick Bundle (Development/Testing)

Bundle the JavaScript without Metro:
```bash
npm run bundle:ios
```

This creates a `main.jsbundle` file in the `ios/` directory that the app will use instead of connecting to Metro. After bundling, you can run the app from Xcode in Release mode.

### Option 2: Release Build (Full Build)

Build a complete release version:
```bash
npm run build:ios
```

This bundles the JavaScript and builds the app in Release configuration. The output will be in `ios/build/`.

### Option 3: Archive for Distribution (App Store/TestFlight)

Create an archive for submission to the App Store or TestFlight:
```bash
npm run build:ios:release
```

This creates an `.xcarchive` file in `ios/build/VintedNotifications.xcarchive` that you can upload using Xcode's Organizer.

### Building from Xcode

If you prefer to build from Xcode:

1. **Bundle the JavaScript first**:
   ```bash
   npm run bundle:ios
   ```

2. **Open the workspace in Xcode**:
   ```bash
   open ios/VintedNotifications.xcworkspace
   ```

3. **Select the scheme**: Choose "VintedNotifications" and your device/simulator

4. **Build configuration**:
   - For testing: Product → Scheme → Edit Scheme → Run → Build Configuration → **Release**
   - For distribution: Product → Archive

5. **Run or Archive**:
   - For testing: Product → Run (⌘R)
   - For distribution: Product → Archive (⌘⇧B), then use Organizer to upload

### Important Notes

- **The app now runs WITHOUT Metro bundler** in all modes (Debug and Release)
- Always run `npm run bundle:ios` after making code changes
- The `main.jsbundle` file should be committed to the repository for easy deployment
- For production releases, always bundle fresh JavaScript before creating archives

## Project Structure

```
MobileApp/
├── App.js                      # Main app component
├── index.js                    # Entry point
├── app.json                    # App configuration
├── package.json                # Dependencies
├── babel.config.js             # Babel configuration
├── metro.config.js             # Metro bundler configuration
├── src/
│   ├── api/
│   │   └── VintedAPI.js       # Vinted API client
│   ├── components/
│   │   ├── ItemCard.js        # Item display component
│   │   ├── QueryCard.js       # Query display component
│   │   ├── StatCard.js        # Statistics card component
│   │   └── index.js           # Component exports
│   ├── constants/
│   │   ├── config.js          # App configuration
│   │   └── theme.js           # Theme and styling
│   ├── models/
│   │   ├── Item.js            # Item data model
│   │   └── Query.js           # Query data model
│   ├── navigation/
│   │   └── AppNavigator.js    # Navigation setup
│   ├── screens/
│   │   ├── DashboardScreen.js # Dashboard with stats
│   │   ├── ItemsScreen.js     # Browse items
│   │   ├── QueriesScreen.js   # Manage queries
│   │   ├── SettingsScreen.js  # App settings
│   │   └── index.js           # Screen exports
│   └── services/
│       ├── DatabaseService.js     # SQLite database
│       ├── MonitoringService.js   # Background monitoring
│       └── NotificationService.js # Push notifications
└── ios/                       # iOS-specific files
    └── Podfile                # CocoaPods dependencies
```

## How to Use

### 1. Add a Search Query

1. Open the app and navigate to the **Queries** tab
2. Tap the **+** button (or "Add Your First Query" if it's your first time)
3. Go to Vinted.com in your browser and perform a search with your desired filters
4. Copy the full URL from the browser
5. Paste the URL into the app
6. Optionally, give it a custom name
7. Tap **Add Query**

**Example URLs:**
- `https://www.vinted.com/catalog?search_text=nike+shoes&price_from=10&price_to=50`
- `https://www.vinted.fr/catalog?brand_ids=53&size_ids=206`

### 2. Start Monitoring

1. Go to the **Dashboard** tab
2. Tap the **Start** button to begin monitoring
3. The app will check all your queries at the configured interval (default: 60 seconds)
4. You'll receive push notifications when new items are found

### 3. Browse Items

1. Navigate to the **Items** tab to see all found items
2. Tap on an item card to open it in Vinted
3. Filter by query by tapping a query card in the **Queries** tab

### 4. Configure Settings

Navigate to the **Settings** tab to customize:

**Monitoring:**
- **Refresh Delay**: How often to check for new items (in seconds)
- **Items Per Query**: Number of items to fetch per search

**Notifications:**
- **Enable Notifications**: Toggle push notifications on/off
- **Message Template**: Customize notification format using placeholders:
  - `{title}` - Item title
  - `{price}` - Item price
  - `{brand}` - Brand name
  - `{size}` - Size

**Filters:**
- **Banned Words**: Exclude items containing specific keywords (separate with `|||`)
  - Example: `replica|||fake|||damaged`

**Country Allowlist:**
- Add country codes (e.g., US, FR, DE) to only show items from sellers in those countries
- Leave empty to show items from all countries

## Background Monitoring (iOS)

The app uses iOS Background Fetch to check for new items even when closed:

- iOS limits background fetch to minimum 15-minute intervals
- The system determines the actual fetch frequency based on app usage patterns
- To ensure consistent monitoring, keep the app open in the background

## Notifications

### Enabling Notifications

1. When you first run the app, you'll be asked to allow notifications
2. If you declined, you can enable them in iOS Settings:
   - Settings → VintedNotifications → Notifications → Allow Notifications

### Notification Format

Customize the notification message in Settings using these placeholders:
- `{title}` - Item title
- `{price}` - Item price with currency
- `{brand}` - Brand name
- `{size}` - Size information

**Default template:**
```
🆕 Title: {title}
💶 Price: {price}
🛍️ Brand: {brand}
📏 Size: {size}
```

## Database

The app uses SQLite for local storage:

- **Location**: Device local storage
- **Tables**:
  - `queries` - Your search queries
  - `items` - Found items
  - `allowlist` - Country filters
  - `parameters` - App settings

All data is stored locally on your device and never sent to external servers.

## Troubleshooting

### Connection refused errors (Metro bundler)

If you see errors like `Connection refused` or `Could not connect to the server` on port 8081:

**This is expected!** The app no longer uses Metro bundler. Simply:
```bash
npm run bundle:ios
```

Then rebuild the app in Xcode.

### App shows old code after changes

If your code changes aren't appearing in the app:

1. Rebuild the bundle:
   ```bash
   npm run bundle:ios
   ```

2. Clean and rebuild in Xcode:
   - Product → Clean Build Folder (⌘⇧K)
   - Product → Build (⌘B)
   - Product → Run (⌘R)

### App won't build

1. Clean the build:
   ```bash
   cd ios
   rm -rf build
   pod deintegrate
   pod install
   cd ..
   ```

2. Ensure the bundle exists:
   ```bash
   npm run bundle:ios
   ```

### Notifications not working

1. Check notification permissions in iOS Settings
2. Ensure "Enable Notifications" is on in app Settings
3. Restart the app

### Items not being found

1. Check that your query URL is valid
2. Ensure monitoring is started (Dashboard → Start button)
3. Verify your refresh delay in Settings
4. Check your internet connection

### Background fetch not working

1. iOS controls background fetch frequency
2. Use the app regularly to improve background fetch priority
3. Keep the app running in the background for consistent monitoring

## Performance Tips

1. **Optimize Refresh Delay**: Set it to 60-120 seconds to balance between timeliness and battery life
2. **Limit Queries**: Keep active queries under 10 for better performance
3. **Use Filters**: Apply country allowlist and banwords to reduce unnecessary notifications
4. **Clean Old Items**: Periodically clear old items from the database (feature coming soon)

## Privacy & Security

- All data is stored locally on your device
- No external servers or third-party analytics
- Network requests only to Vinted.com API
- No personal data collection

## Technical Details

**Built with:**
- React Native 0.72.6
- React Navigation 6.x
- SQLite for storage
- Axios for HTTP requests
- Native push notifications
- Background fetch API

**Supported iOS versions:**
- iOS 13.0 and higher

## Contributing

This is a conversion of the Python Vinted-Notifications project. For issues or feature requests, please refer to the main project repository.

## License

Same license as the parent Vinted-Notifications project.

## Acknowledgments

- Original Python project: Vinted-Notifications
- Vinted API (unofficial)
- React Native community

---

**Note**: This app is not affiliated with Vinted. Use responsibly and in accordance with Vinted's terms of service.
