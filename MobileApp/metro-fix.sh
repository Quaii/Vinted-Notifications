#!/bin/bash

###############################################################################
# Metro Bundler Fix Script
# Fixes: "No script URL provided" error
###############################################################################

set -e

echo "🔧 Metro Bundler Fix Script"
echo "============================"
echo ""

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "This script will:"
echo "  1. Kill any running Metro processes"
echo "  2. Clear Metro cache"
echo "  3. Clean iOS build"
echo "  4. Start Metro with reset cache"
echo ""

print_step "Step 1/4: Killing existing Metro processes..."
# Kill any node processes running Metro
pkill -f "react-native/cli" 2>/dev/null || true
pkill -f "metro" 2>/dev/null || true
lsof -ti:8081 | xargs kill -9 2>/dev/null || true
print_success "Metro processes killed"

echo ""
print_step "Step 2/4: Clearing Metro cache..."
rm -rf $TMPDIR/metro-* 2>/dev/null || true
rm -rf $TMPDIR/haste-* 2>/dev/null || true
rm -rf node_modules/.cache 2>/dev/null || true
print_success "Metro cache cleared"

echo ""
print_step "Step 3/4: Cleaning iOS build..."
cd ios
xcodebuild clean -workspace VintedNotifications.xcworkspace -scheme VintedNotifications 2>/dev/null || true
rm -rf build
cd ..
print_success "iOS build cleaned"

echo ""
print_step "Step 4/4: Starting Metro bundler with reset cache..."
echo ""
echo "========================================"
echo -e "${GREEN}Metro bundler starting...${NC}"
echo "========================================"
echo ""
echo "Once Metro is running:"
echo "  1. In a NEW terminal, run: cd MobileApp && npm run ios"
echo "  2. Or press 'i' in Metro to run iOS"
echo ""
echo "Press Ctrl+C to stop Metro when done"
echo ""

npm start -- --reset-cache
