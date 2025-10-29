# App Icon Assets

## Required Sizes for iOS

Place your app icon PNG files in this directory with the following names and sizes:

| Filename | Size (pixels) | Usage |
|----------|---------------|-------|
| `Icon-20@2x.png` | 40x40 | iPhone Notification |
| `Icon-20@3x.png` | 60x60 | iPhone Notification |
| `Icon-29@2x.png` | 58x58 | iPhone Settings |
| `Icon-29@3x.png` | 87x87 | iPhone Settings |
| `Icon-40@2x.png` | 80x80 | iPhone Spotlight |
| `Icon-40@3x.png` | 120x120 | iPhone Spotlight |
| `Icon-60@2x.png` | 120x120 | iPhone App |
| `Icon-60@3x.png` | 180x180 | iPhone App |
| `Icon-1024.png` | 1024x1024 | App Store |

## Design Guidelines

### General Requirements
- **Format**: PNG (no transparency/alpha channel)
- **Color Space**: sRGB or Display P3
- **No rounded corners**: iOS automatically applies corners
- **No text**: Icon should be recognizable without text

### Design Tips for BabyTrack
1. **Theme**: Baby care, growth, tracking
2. **Colors**: Soft, warm colors (pastels work well for baby apps)
3. **Style**: Modern, minimal, friendly
4. **Icon Elements** (suggestions):
   - Baby silhouette
   - Growth chart line
   - Heart symbol
   - Pacifier
   - Baby bottle
   - Simple geometric shapes

### Recommended Tools
- **Figma**: Design at 1024x1024, export all sizes
- **Sketch**: Use artboards for each size
- **Icon Generator**: https://www.appicon.co/ (quick generation from 1024x1024)
- **SF Symbols**: Consider using as inspiration

### Testing
1. Place icons in this directory
2. Open Xcode project
3. Check Assets.xcassets → AppIcon
4. Build and run to see icon on Home Screen

## watchOS Icons (Separate)

For Apple Watch companion app, create similar structure in:
`Targets/BabyTrackWatch/Assets.xcassets/AppIcon.appiconset/`

Required sizes:
- 48x48 (Notification Center - @2x)
- 55x55 (Notification Center - @3x)
- 58x58 (Companion Settings - @2x)
- 87x87 (Companion Settings - @3x)
- 80x80 (Home Screen - @2x, 40mm)
- 88x88 (Home Screen - @2x, 44mm)
- 92x92 (Home Screen - @2x, 45mm)
- 100x100 (Home Screen - @2x, 49mm)
- 1024x1024 (App Store)

## Widget Icons (Optional)

For widgets, consider creating additional assets:
- Widget preview images
- Placeholder graphics
