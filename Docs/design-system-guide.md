# DesignSystem Usage Guide

## Overview
The DesignSystem module provides a comprehensive design system with colors, typography, spacing, radii, and animation constants for the BabyTrack app.

## Theme Structure

### Palette
Access via `BabyTrackTheme.palette`

#### Base Colors
```swift
BabyTrackTheme.palette.background           // System background
BabyTrackTheme.palette.secondaryBackground  // Secondary background
BabyTrackTheme.palette.elevatedSurface      // Elevated cards/surfaces
BabyTrackTheme.palette.accent               // Primary accent color
BabyTrackTheme.palette.success              // Success states
BabyTrackTheme.palette.warning              // Warning states
BabyTrackTheme.palette.destructive          // Destructive actions
BabyTrackTheme.palette.primaryText          // Primary text
BabyTrackTheme.palette.mutedText            // Secondary/muted text
```

#### Event-Specific Colors
Each event type has a semantic color:

```swift
BabyTrackTheme.palette.sleep        // #667BC6 - Soft blue
BabyTrackTheme.palette.feeding      // #DA7297 - Warm pink
BabyTrackTheme.palette.diaper       // #FFDC7F - Soft yellow
BabyTrackTheme.palette.pumping      // #7BA8E5 - Light blue
BabyTrackTheme.palette.measurement  // #9B85C9 - Purple
BabyTrackTheme.palette.medication   // #82C997 - Green
BabyTrackTheme.palette.note         // #95A5A6 - Gray
```

**Usage Example:**
```swift
Tag(title: "Sleep", color: BabyTrackTheme.palette.sleep, icon: "moon.fill")

Circle()
    .fill(BabyTrackTheme.palette.feeding)
```

### Typography
Access via `BabyTrackTheme.typography`

```swift
BabyTrackTheme.typography.largeTitle  // Large title style
BabyTrackTheme.typography.title       // Title 2 style
BabyTrackTheme.typography.title3      // Title 3 style
BabyTrackTheme.typography.headline    // Headline style
BabyTrackTheme.typography.body        // Body text
BabyTrackTheme.typography.callout     // Callout style
BabyTrackTheme.typography.footnote    // Footnote style
BabyTrackTheme.typography.caption     // Caption style
```

**Usage Example:**
```swift
BabyTrackTheme.typography.title.text("Hello, World!")

// Or apply manually:
Text("Custom Text")
    .font(BabyTrackTheme.typography.body.font)
    .foregroundStyle(BabyTrackTheme.typography.body.color)
```

### Spacing
Access via `BabyTrackTheme.spacing`

```swift
BabyTrackTheme.spacing.xxs  // 4pt
BabyTrackTheme.spacing.xs   // 8pt
BabyTrackTheme.spacing.sm   // 12pt
BabyTrackTheme.spacing.md   // 16pt
BabyTrackTheme.spacing.lg   // 24pt
BabyTrackTheme.spacing.xl   // 32pt
```

**Usage Example:**
```swift
VStack(spacing: BabyTrackTheme.spacing.md) {
    Text("Item 1")
    Text("Item 2")
}
.padding(BabyTrackTheme.spacing.lg)
```

### Corner Radii
Access via `BabyTrackTheme.radii`

```swift
BabyTrackTheme.radii.pill  // 20pt - For pill-shaped buttons
BabyTrackTheme.radii.soft  // 12pt - For moderate rounding
BabyTrackTheme.radii.card  // 18pt - For cards and containers
```

**Usage Example:**
```swift
RoundedRectangle(cornerRadius: BabyTrackTheme.radii.card)
    .fill(BabyTrackTheme.palette.elevatedSurface)

Text("Button")
    .padding()
    .background(BabyTrackTheme.palette.accent)
    .clipShape(RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft))
```

### Animations
Access via `BabyTrackTheme.animation`

```swift
BabyTrackTheme.animation.fast      // 0.2s - Micro-interactions
BabyTrackTheme.animation.standard  // 0.3s - Most UI changes
BabyTrackTheme.animation.slow      // 0.4s - Larger transitions
BabyTrackTheme.animation.spring    // Spring animation - Bouncy effects
BabyTrackTheme.animation.smooth    // Smooth animation - Fluid transitions
```

**Usage Example:**
```swift
withAnimation(BabyTrackTheme.animation.spring) {
    isExpanded.toggle()
}

Button("Animate") {
    withAnimation(BabyTrackTheme.animation.standard) {
        offset = 100
    }
}
```

## Best Practices

### 1. Always Use Theme Constants
❌ **Don't:**
```swift
.padding(16)
.foregroundColor(.blue)
```

✅ **Do:**
```swift
.padding(BabyTrackTheme.spacing.md)
.foregroundStyle(BabyTrackTheme.palette.accent)
```

### 2. Use Semantic Color Names
❌ **Don't:**
```swift
.foregroundColor(.init(hex: "#667BC6"))
```

✅ **Do:**
```swift
.foregroundStyle(BabyTrackTheme.palette.sleep)
```

### 3. Consistent Animations
❌ **Don't:**
```swift
withAnimation(.easeInOut(duration: 0.25)) { ... }
```

✅ **Do:**
```swift
withAnimation(BabyTrackTheme.animation.standard) { ... }
```

### 4. Dark Mode Support
All theme colors automatically adapt to dark mode. No additional work needed!

```swift
// This works perfectly in both light and dark mode
Text("Hello")
    .foregroundStyle(BabyTrackTheme.palette.primaryText)
    .background(BabyTrackTheme.palette.background)
```

## Initialization

Call `BabyTrackTheme.configureAppearance()` at app launch to configure global UIKit appearance:

```swift
@main
struct BabyTrackApp: App {
    init() {
        BabyTrackTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Components

The DesignSystem also provides pre-built components:
- `Card` - Elevated card container
- `PrimaryButton` - Primary action button
- `Tag` - Colored label/tag
- `Toast` - Toast notification
- `EmptyStateView` - Empty state placeholder
- `ErrorView` - Error state display
- `ChartCard` - Card for charts
- `FormField` - Form input field
- `SegmentedControl` - Segmented picker
- `SectionHeader` - Section header

See component files for detailed usage.
