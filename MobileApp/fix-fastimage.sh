#!/bin/bash
set -e

echo "🔧 Fixing FastImageView Configuration Issue"
echo "=========================================="
echo ""

# Navigate to MobileApp directory
cd "$(dirname "$0")"

echo "📦 Step 1: Clean node_modules and reinstall dependencies..."
rm -rf node_modules
npm install

echo ""
echo "🍎 Step 2: Clean iOS build artifacts..."
rm -rf ios/Pods
rm -rf ios/build
rm -rf ios/Podfile.lock

echo ""
echo "📱 Step 3: Install CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

echo ""
echo "🧹 Step 4: Clean Metro bundler cache..."
rm -rf $TMPDIR/metro-* 2>/dev/null || true
rm -rf $TMPDIR/haste-map-* 2>/dev/null || true
watchman watch-del-all 2>/dev/null || echo "Watchman not installed, skipping..."

echo ""
echo "✅ Fix complete!"
echo ""
echo "Next steps:"
echo "  1. Close the Metro bundler if it's running"
echo "  2. Rebuild the iOS app:"
echo "     npm run ios"
echo "     or open ios/VintedNotifications.xcworkspace in Xcode and build"
echo ""
echo "The FastImageView configuration should now be properly registered!"
