# App Icon Setup

## Instructions

To add your app icon:

1. Create or prepare your app icon as a **1024x1024 PNG** file
2. Name it **`AppIcon.png`**
3. Place it in this directory (replace this README if needed)

## Requirements

- Format: PNG
- Size: 1024x1024 pixels
- Color space: sRGB or Display P3
- No transparency (iOS will handle the rounded corners)

## Design Guidelines

- Keep important content within the safe area (avoid edges)
- Use a simple, recognizable design
- Test on both light and dark backgrounds
- Avoid using text if possible (icon should be clear at small sizes)

## Current Configuration

This asset catalog is configured for iOS 17+ using a single universal icon.
Xcode will automatically generate all required sizes from the 1024x1024 master.

## Note

Until you add your icon, the app may display a default/blank icon in Xcode previews and on device.
