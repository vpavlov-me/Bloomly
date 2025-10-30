# DesignSystem Usage Guide

## Overview
The DesignSystem module provides a comprehensive design system with colors, typography, spacing, radii, and animation constants for the bloomy app.

## Theme Structure

### Palette
Access via `BloomyTheme.palette`

#### Base Colors
```swift
BloomyTheme.palette.background           // System background
BloomyTheme.palette.secondaryBackground  // Secondary background
BloomyTheme.palette.elevatedSurface      // Elevated cards/surfaces
BloomyTheme.palette.accent               // Primary accent color
BloomyTheme.palette.success              // Success states
BloomyTheme.palette.warning              // Warning states
BloomyTheme.palette.destructive          // Destructive actions
BloomyTheme.palette.primaryText          // Primary text
BloomyTheme.palette.mutedText            // Secondary/muted text
```

#### Event-Specific Colors
Each event type has a semantic color:

```swift
BloomyTheme.palette.sleep        // #667BC6 - Soft blue
BloomyTheme.palette.feeding      // #DA7297 - Warm pink
BloomyTheme.palette.diaper       // #FFDC7F - Soft yellow
BloomyTheme.palette.pumping      // #7BA8E5 - Light blue
BloomyTheme.palette.measurement  // #9B85C9 - Purple
BloomyTheme.palette.medication   // #82C997 - Green
BloomyTheme.palette.note         // #95A5A6 - Gray
```

**Usage Example:**
```swift
Tag(title: "Sleep", color: BloomyTheme.palette.sleep, icon: "moon.fill")

Circle()
    .fill(BloomyTheme.palette.feeding)
```

### Typography
Access via `BloomyTheme.typography`

```swift
BloomyTheme.typography.largeTitle  // Large title style
BloomyTheme.typography.title       // Title 2 style
BloomyTheme.typography.title3      // Title 3 style
BloomyTheme.typography.headline    // Headline style
BloomyTheme.typography.body        // Body text
BloomyTheme.typography.callout     // Callout style
BloomyTheme.typography.footnote    // Footnote style
BloomyTheme.typography.caption     // Caption style
```

**Usage Example:**
```swift
BloomyTheme.typography.title.text("Hello, World!")

// Or apply manually:
Text("Custom Text")
    .font(BloomyTheme.typography.body.font)
    .foregroundStyle(BloomyTheme.typography.body.color)
```

### Spacing
Access via `BloomyTheme.spacing`

```swift
BloomyTheme.spacing.xxs  // 4pt
BloomyTheme.spacing.xs   // 8pt
BloomyTheme.spacing.sm   // 12pt
BloomyTheme.spacing.md   // 16pt
BloomyTheme.spacing.lg   // 24pt
BloomyTheme.spacing.xl   // 32pt
```

**Usage Example:**
```swift
VStack(spacing: BloomyTheme.spacing.md) {
    Text("Item 1")
    Text("Item 2")
}
.padding(BloomyTheme.spacing.lg)
```

### Corner Radii
Access via `BloomyTheme.radii`

```swift
BloomyTheme.radii.pill  // 20pt - For pill-shaped buttons
BloomyTheme.radii.soft  // 12pt - For moderate rounding
BloomyTheme.radii.card  // 18pt - For cards and containers
```

**Usage Example:**
```swift
RoundedRectangle(cornerRadius: BloomyTheme.radii.card)
    .fill(BloomyTheme.palette.elevatedSurface)

Text("Button")
    .padding()
    .background(BloomyTheme.palette.accent)
    .clipShape(RoundedRectangle(cornerRadius: BloomyTheme.radii.soft))
```

### Animations
Access via `BloomyTheme.animation`

```swift
BloomyTheme.animation.fast      // 0.2s - Micro-interactions
BloomyTheme.animation.standard  // 0.3s - Most UI changes
BloomyTheme.animation.slow      // 0.4s - Larger transitions
BloomyTheme.animation.spring    // Spring animation - Bouncy effects
BloomyTheme.animation.smooth    // Smooth animation - Fluid transitions
```

**Usage Example:**
```swift
withAnimation(BloomyTheme.animation.spring) {
    isExpanded.toggle()
}

Button("Animate") {
    withAnimation(BloomyTheme.animation.standard) {
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
.padding(BloomyTheme.spacing.md)
.foregroundStyle(BloomyTheme.palette.accent)
```

### 2. Use Semantic Color Names
❌ **Don't:**
```swift
.foregroundColor(.init(hex: "#667BC6"))
```

✅ **Do:**
```swift
.foregroundStyle(BloomyTheme.palette.sleep)
```

### 3. Consistent Animations
❌ **Don't:**
```swift
withAnimation(.easeInOut(duration: 0.25)) { ... }
```

✅ **Do:**
```swift
withAnimation(BloomyTheme.animation.standard) { ... }
```

### 4. Dark Mode Support
All theme colors automatically adapt to dark mode. No additional work needed!

```swift
// This works perfectly in both light and dark mode
Text("Hello")
    .foregroundStyle(BloomyTheme.palette.primaryText)
    .background(BloomyTheme.palette.background)
```

## Initialization

Call `BloomyTheme.configureAppearance()` at app launch to configure global UIKit appearance:

```swift
@main
struct BloomyApp: App {
    init() {
        BloomyTheme.configureAppearance()
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
