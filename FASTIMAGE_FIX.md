# FastImageView ViewConfig Fix

## Problem

After disabling Fabric (New Architecture) in commits `f104827` and `e55b54e`, the app crashes with:

```
ViewConfig not found for name FastImageView
Invariant Violation in react-native-view-config-registry.js line 113
```

## Root Cause

The `@d11/react-native-fast-image` package requires native module linking through CocoaPods. After the Fabric disable changes, the iOS Pods need to be reinstalled to properly register the native ViewConfig for FastImageView.

## Solution

### Quick Fix (Automated)

Run the automated fix script from the `MobileApp` directory:

```bash
cd MobileApp
./fix-fastimage.sh
```

This script will:
1. Clean and reinstall npm dependencies
2. Remove old iOS build artifacts
3. Reinstall CocoaPods dependencies
4. Clear Metro bundler cache
5. Provide instructions for rebuilding

### Manual Fix

If you prefer to do it manually:

```bash
cd MobileApp

# 1. Reinstall npm dependencies (optional but recommended)
rm -rf node_modules
npm install

# 2. Clean and reinstall iOS Pods (REQUIRED)
cd ios
rm -rf Pods Podfile.lock build
pod install --repo-update
cd ..

# 3. Clear Metro cache (optional but recommended)
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/haste-map-*
watchman watch-del-all  # if you have watchman installed

# 4. Rebuild the app
npm run ios
```

## Why This Happened

The `@d11/react-native-fast-image` package supports both old and new architectures, but after explicitly disabling Fabric in `AppDelegate.mm`:

```objc
- (BOOL)fabricEnabled { return NO; }
- (BOOL)bridgelessEnabled { return NO; }
- (BOOL)concurrentRootEnabled { return NO; }
```

The native modules need to be rebuilt to properly register with the legacy bridge system. The CocoaPods installation ensures the native FastImageView component is correctly linked and its ViewConfig is registered in the ViewConfigRegistry.

## Verification

After running the fix and rebuilding, the `FastImage` component in `ItemCard.js` should work without errors:

```javascript
import FastImage from '@d11/react-native-fast-image';

<FastImage
  style={styles.thumbnail}
  source={{uri: imageUrl}}
  resizeMode={FastImage.resizeMode.cover}
/>
```

## Technical Details

- **Package**: `@d11/react-native-fast-image` v8.11.1
- **Architecture**: Old Architecture (Fabric disabled)
- **React Native**: 0.81.4
- **iOS Target**: 17.0+
- **Auto-linking**: Enabled via CocoaPods
