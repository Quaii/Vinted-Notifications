# iOS App Icon Setup Guide

## Overview
App icon support has been successfully added to the VintedNotifications iOS app. The asset catalog structure is now in place and configured in the Xcode project.

## Asset Catalog Structure
```
VintedNotifications/
└── Assets.xcassets/
    ├── Contents.json
    └── AppIcon.appiconset/
        └── Contents.json
```

## Required Icon Sizes

The app is configured to use the following icon sizes:

### iPhone Icons
- **20x20** - @2x (40x40px) and @3x (60x60px) - Notification icon
- **29x29** - @2x (58x58px) and @3x (87x87px) - Settings icon  
- **40x40** - @2x (80x80px) and @3x (120x120px) - Spotlight icon
- **60x60** - @2x (120x120px) and @3x (180x180px) - App icon

### iPad Icons
- **20x20** - @1x (20x20px) and @2x (40x40px) - Notification icon
- **29x29** - @1x (29x29px) and @2x (58x58px) - Settings icon
- **40x40** - @1x (40x40px) and @2x (80x80px) - Spotlight icon
- **76x76** - @1x (76x76px) and @2x (152x152px) - App icon
- **83.5x83.5** - @2x (167x167px) - iPad Pro icon

### App Store
- **1024x1024** - @1x (1024x1024px) - App Store icon

## How to Add Your Icon Images

### Option 1: Using Xcode (Recommended)
1. Open `VintedNotifications.xcodeproj` in Xcode
2. In the Project Navigator, navigate to `VintedNotifications/Assets.xcassets/AppIcon`
3. Drag and drop your icon images into the appropriate slots
4. Xcode will automatically resize images if they match the expected dimensions

### Option 2: Manual File Placement
1. Create PNG images with the exact dimensions listed above
2. Name them according to the filenames in `Contents.json`:
   - `AppIcon-20x20@2x.png` (40x40px)
   - `AppIcon-20x20@3x.png` (60x60px)
   - `AppIcon-29x29@2x.png` (58x58px)
   - `AppIcon-29x29@3x.png` (87x87px)
   - `AppIcon-40x40@2x.png` (80x80px)
   - `AppIcon-40x40@3x.png` (120x120px)
   - `AppIcon-60x60@2x.png` (120x120px)
   - `AppIcon-60x60@3x.png` (180x180px)
   - `AppIcon-20x20@1x.png` (20x20px)
   - `AppIcon-29x29@1x.png` (29x29px)
   - `AppIcon-40x40@1x.png` (40x40px)
   - `AppIcon-76x76@1x.png` (76x76px)
   - `AppIcon-76x76@2x.png` (152x152px)
   - `AppIcon-83.5x83.5@2x.png` (167x167px)
   - `AppIcon-1024x1024@1x.png` (1024x1024px)
3. Place all images in: `VintedNotifications/Assets.xcassets/AppIcon.appiconset/`

### Option 3: Using Icon Generator Tools
You can use online tools or apps to generate all required sizes from a single 1024x1024px icon:
- [MakeAppIcon](https://makeappicon.com/)
- [AppIconMaker](https://appiconmaker.co/)
- [IconKitchen](https://icon.kitchen/)

## Icon Design Guidelines

### Requirements
- **Format**: PNG (no transparency for iOS)
- **Color Space**: sRGB or P3
- **No Alpha Channel**: iOS app icons cannot have transparency

### Best Practices
1. **Simple and Clear**: Icons should be recognizable at small sizes
2. **No Text**: Avoid text in the icon; it won't be readable at small sizes
3. **Consistent Style**: Match iOS design language
4. **Test on Device**: Always test how your icon looks on an actual device
5. **Safe Area**: Keep important content within the safe area (avoid corners that get rounded)

### Vinted Theme Suggestions
Consider incorporating Vinted's brand colors and style:
- Primary color: Teal/Turquoise (#09B1BA)
- Secondary accents that reflect the notification/monitoring purpose
- Simple iconography related to shopping, items, or notifications

## Project Configuration

The following has been configured in the Xcode project:

### Build Settings
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
- Asset catalog properly linked in both Debug and Release configurations

### Project References
- Assets.xcassets added to the project's resource bundle
- Properly referenced in `project.pbxproj`

## Verification

To verify the app icon is working:
1. Build and run the app in Xcode
2. Check that the icon appears on the simulator/device home screen
3. Test in both light and dark mode appearances
4. Verify in Settings and Spotlight search

## Troubleshooting

### Icon Not Appearing
- Ensure all required icon sizes are present
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Delete app from simulator/device and reinstall
- Verify file names match exactly what's in Contents.json

### Xcode Warnings
- If you see "AppIcon - The app icon set has X unassigned children"
  - This means some icon sizes are missing
  - Add the missing sizes or update Contents.json to remove unused entries

### Build Errors
- Check that Assets.xcassets is properly added to the project target
- Verify Contents.json is valid JSON
- Ensure all image files are actual PNGs (not renamed JPEGs)

## Next Steps

1. Create or obtain your app icon design (1024x1024px)
2. Generate all required sizes using one of the methods above
3. Add the images to the asset catalog
4. Build and test the app

The infrastructure is now ready - you just need to add your icon images!
