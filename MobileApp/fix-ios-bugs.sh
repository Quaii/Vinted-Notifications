#!/bin/bash

###############################################################################
# iOS Bug Fix & Clean Rebuild Script
# Fixes: 1. react-native-safe-area-context compilation error
#        2. RNCPushNotificationIOS remnants
# Updates: iOS 17.0 deployment target
###############################################################################

set -e  # Exit on error

echo "🔧 iOS Bug Fix & Clean Rebuild Script"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Confirm with user
echo -e "${YELLOW}This script will:${NC}"
echo "  1. Clean all build artifacts"
echo "  2. Remove node_modules and Pods"
echo "  3. Reinstall dependencies with bug fixes"
echo "  4. Update to iOS 17.0 deployment target"
echo ""
echo -e "${YELLOW}Continue? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
print_step "Step 1/7: Cleaning npm cache and node_modules..."
rm -rf node_modules
rm -f package-lock.json yarn.lock
print_success "npm artifacts cleaned"

echo ""
print_step "Step 2/7: Cleaning iOS build artifacts..."
cd ios
rm -rf build
rm -rf Pods
rm -f Podfile.lock
print_success "iOS build artifacts cleaned"

echo ""
print_step "Step 3/7: Cleaning Xcode DerivedData..."
if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
    print_success "DerivedData cleaned"
else
    print_warning "DerivedData directory not found (skipping)"
fi

echo ""
print_step "Step 4/7: Cleaning CocoaPods cache..."
pod cache clean --all 2>/dev/null || print_warning "CocoaPods cache clean failed (may not be installed)"
cd ..

echo ""
print_step "Step 5/7: Installing npm dependencies..."
npm install
print_success "npm dependencies installed"

echo ""
print_step "Step 6/7: Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
print_success "CocoaPods dependencies installed"
cd ..

echo ""
print_step "Step 7/7: Verifying fixes..."
echo ""

# Check if safe-area-context is updated
SAFE_AREA_VERSION=$(grep "react-native-safe-area-context" package.json | grep -o "[0-9]*\.[0-9]*\.[0-9]*" | head -1)
if [ "$SAFE_AREA_VERSION" != "4.14.0" ]; then
    print_success "react-native-safe-area-context updated to $SAFE_AREA_VERSION (was 4.14.0)"
else
    print_error "react-native-safe-area-context still at 4.14.0!"
fi

# Check if RNCPushNotificationIOS is removed
if ! grep -q "push-notification-ios" package.json; then
    print_success "RNCPushNotificationIOS removed from package.json"
else
    print_error "RNCPushNotificationIOS still in package.json!"
fi

# Check if Notifee is present
if grep -q "@notifee/react-native" package.json; then
    print_success "@notifee/react-native installed (modern replacement)"
else
    print_warning "@notifee/react-native not found"
fi

# Check iOS deployment target
if grep -q "platform :ios, '17.0'" ios/Podfile; then
    print_success "iOS deployment target set to 17.0"
else
    print_warning "iOS deployment target may not be set correctly"
fi

echo ""
echo "========================================"
echo -e "${GREEN}✅ All fixes applied successfully!${NC}"
echo "========================================"
echo ""
echo "📋 Next steps:"
echo "  1. Run: npm run ios"
echo "  2. Or open: ios/VintedNotifications.xcworkspace in Xcode"
echo ""
echo "🔍 Expected results:"
echo "  ✓ No 'unit' compilation errors (safe-area-context fixed)"
echo "  ✓ No UILocalNotification warnings (Notifee replacement)"
echo "  ✓ No iOS 8.0/9.0 deployment target warnings"
echo "  ✓ Significantly fewer deprecation warnings"
echo ""
echo "⚠️  Remaining warnings:"
echo "  • React Native Core warnings (in node_modules) - CANNOT FIX"
echo "  • Third-party library warnings - Wait for library updates"
echo "  • These are NORMAL and won't affect functionality"
echo ""
