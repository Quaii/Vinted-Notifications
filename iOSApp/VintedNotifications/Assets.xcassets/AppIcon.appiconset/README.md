# App Icon Setup

## Quick Setup (Recommended)

The **easiest way** to add your app icon:

1. Create a **1024x1024 PNG** file of your icon
2. Name it **`AppIcon-1024.png`**
3. Drop it in this directory
4. Use a tool like **AppIconGenerator** or **Xcode** to generate all sizes automatically

### Automatic Generation Tools

- **Xcode**: Drag your 1024x1024 icon to the App Store slot in Xcode, it will offer to generate all sizes
- **Online**: https://www.appicon.co/ - Upload your 1024x1024 icon
- **CLI**: `brew install imagemagick` then run the generation script below

## Manual Setup (All Sizes)

If you want to manually provide all icon sizes, place these PNG files in this directory:

### iPhone Icons

| Usage | Filename | Size (px) | Description |
|-------|----------|-----------|-------------|
| **Notification** | `AppIcon-20@2x.png` | 40×40 | Notification icon @2x |
| | `AppIcon-20@3x.png` | 60×60 | Notification icon @3x |
| **Settings** | `AppIcon-29@2x.png` | 58×58 | Settings icon @2x |
| | `AppIcon-29@3x.png` | 87×87 | Settings icon @3x |
| **Spotlight** | `AppIcon-40@2x.png` | 80×80 | Spotlight @2x |
| | `AppIcon-40@3x.png` | 120×120 | Spotlight @3x |
| **App** | `AppIcon-60@2x.png` | 120×120 | iPhone app @2x |
| | `AppIcon-60@3x.png` | 180×180 | iPhone app @3x |

### iPad Icons (Optional - if supporting iPad)

| Usage | Filename | Size (px) | Description |
|-------|----------|-----------|-------------|
| **Notification** | `AppIcon-20-iPad.png` | 20×20 | Notification @1x |
| | `AppIcon-20@2x-iPad.png` | 40×40 | Notification @2x |
| **Settings** | `AppIcon-29-iPad.png` | 29×29 | Settings @1x |
| | `AppIcon-29@2x-iPad.png` | 58×58 | Settings @2x |
| **Spotlight** | `AppIcon-40-iPad.png` | 40×40 | Spotlight @1x |
| | `AppIcon-40@2x-iPad.png` | 80×80 | Spotlight @2x |
| **App** | `AppIcon-76-iPad.png` | 76×76 | iPad app @1x |
| | `AppIcon-76@2x-iPad.png` | 152×152 | iPad app @2x |
| **iPad Pro** | `AppIcon-83.5@2x-iPad.png` | 167×167 | iPad Pro @2x |

### App Store

| Usage | Filename | Size (px) | Description |
|-------|----------|-----------|-------------|
| **App Store** | `AppIcon-1024.png` | 1024×1024 | App Store icon |

## ImageMagick Generation Script

If you have ImageMagick installed, save this as `generate-icons.sh` and run it:

```bash
#!/bin/bash

# Requires a source image named "icon-source.png" at 1024x1024
SOURCE="icon-source.png"

# iPhone
convert $SOURCE -resize 40x40 AppIcon-20@2x.png
convert $SOURCE -resize 60x60 AppIcon-20@3x.png
convert $SOURCE -resize 58x58 AppIcon-29@2x.png
convert $SOURCE -resize 87x87 AppIcon-29@3x.png
convert $SOURCE -resize 80x80 AppIcon-40@2x.png
convert $SOURCE -resize 120x120 AppIcon-40@3x.png
convert $SOURCE -resize 120x120 AppIcon-60@2x.png
convert $SOURCE -resize 180x180 AppIcon-60@3x.png

# iPad
convert $SOURCE -resize 20x20 AppIcon-20-iPad.png
convert $SOURCE -resize 40x40 AppIcon-20@2x-iPad.png
convert $SOURCE -resize 29x29 AppIcon-29-iPad.png
convert $SOURCE -resize 58x58 AppIcon-29@2x-iPad.png
convert $SOURCE -resize 40x40 AppIcon-40-iPad.png
convert $SOURCE -resize 80x80 AppIcon-40@2x-iPad.png
convert $SOURCE -resize 76x76 AppIcon-76-iPad.png
convert $SOURCE -resize 152x152 AppIcon-76@2x-iPad.png
convert $SOURCE -resize 167x167 AppIcon-83.5@2x-iPad.png

# App Store
cp $SOURCE AppIcon-1024.png

echo "✅ All icon sizes generated!"
```

## Icon Requirements

- **Format**: PNG (no JPEG, no GIF)
- **Color Space**: sRGB or Display P3
- **Transparency**: None (iOS adds rounded corners automatically)
- **Compression**: Standard PNG compression is fine
- **Color Profile**: Embedded color profile recommended

## Design Guidelines

1. **Safe Area**: Keep important content within 80% of the icon area
2. **Simplicity**: Icon should be recognizable at 40×40 pixels
3. **No Text**: Avoid text if possible (becomes unreadable at small sizes)
4. **Backgrounds**: Test on both light and dark backgrounds
5. **Consistency**: Match your brand colors and style
6. **Platform Guidelines**: Follow [Apple's Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)

## Testing

After adding your icons:

1. Open the project in Xcode
2. Select the Assets.xcassets folder
3. Click on AppIcon to verify all icons are present
4. Build and run on simulator to test appearance
5. Test on physical device for real-world appearance

## Troubleshooting

**Icons not showing in Xcode?**
- Ensure filenames match exactly (case-sensitive)
- Verify PNG format (not JPEG renamed to .png)
- Clean build folder (Cmd+Shift+K) and rebuild

**Icons blurry on device?**
- Check that you're using the correct sizes
- Ensure source image is high quality
- Verify @2x and @3x versions are sharp

**Wrong colors on device?**
- Check color profile (should be sRGB or Display P3)
- Verify no transparency in icons
- Test in both light and dark mode
