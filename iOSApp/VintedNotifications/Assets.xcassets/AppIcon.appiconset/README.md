# App Icon Setup

## Current Status

A placeholder app icon has been created with:
- **Size**: 1024x1024 pixels
- **Color**: Purple (#9333EA) - inspired by Vinted branding
- **Format**: PNG with RGB color space

## How to Replace with Your Custom Icon

### Option 1: Replace the PNG file directly

1. Create or obtain your app icon design (1024x1024 pixels, PNG format)
2. Name it `AppIcon-1024.png`
3. Replace the existing file in this directory
4. The icon should:
   - Be exactly 1024x1024 pixels
   - Use RGB color space (not CMYK)
   - Have no transparency (solid background)
   - Have no rounded corners (iOS handles this automatically)

### Option 2: Use Xcode Asset Catalog

1. Open the project in Xcode
2. Navigate to `Assets.xcassets` in the Project Navigator
3. Click on `AppIcon`
4. Drag and drop your 1024x1024 icon into the "1024pt" slot
5. Xcode will automatically generate all required sizes

### Icon Design Guidelines

- **Simplicity**: Keep the design simple and recognizable at small sizes
- **No text**: Avoid small text that becomes unreadable when scaled down
- **Consistent branding**: Match your app's color scheme and style
- **Test at different sizes**: Preview how it looks on home screen, Settings, etc.

### Using Design Tools

Popular tools for creating app icons:
- **Figma**: Free, web-based design tool
- **Sketch**: Mac-only design software
- **Affinity Designer**: Affordable alternative to Adobe
- **Canva**: Easy-to-use templates

### Online Icon Generators

- [appicon.co](https://appicon.co) - Upload 1024x1024 and generate all sizes
- [makeappicon.com](https://makeappicon.com) - Free icon generator
- [AppIconBuilder](https://appiconbuilder.com) - Generate all iOS icon sizes

## Current Placeholder

The current purple placeholder is intentionally simple. Replace it with your branded icon before release.
