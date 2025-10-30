# Accessibility Guide

This document outlines the accessibility features implemented in bloomy and provides guidelines for maintaining accessibility standards.

## Overview

bloomy is designed to be accessible to all users, including those who rely on assistive technologies. Our accessibility implementation follows Apple's Human Interface Guidelines and meets WCAG 2.1 Level AA standards.

## Implemented Features

### 1. VoiceOver Support ✅

**What it is:** Screen reader support for users with visual impairments.

**Implementation:**
- All interactive elements have descriptive accessibility labels
- Semantic grouping of related elements
- Custom accessibility actions for complex gestures
- Proper trait assignment (buttons, headers, etc.)
- Meaningful reading order

**Example:**
```swift
PrimaryButton(
    accessibilityLabel: "Save event",
    accessibilityHint: "Double tap to save changes",
    action: saveAction
) {
    Text("Save")
}
```

### 2. Dynamic Type Support ✅

**What it is:** Automatic text scaling based on user preferences.

**Implementation:**
- All text uses semantic font styles (`.body`, `.headline`, etc.)
- Layouts adapt to larger text sizes
- Text truncation avoided where possible
- Limited size ranges for complex UI (`.xSmall ... .xxxLarge`)

**Usage:**
```swift
Text("Hello")
    .dynamicTypeSize(.xSmall ... .xxxLarge) // Limits extreme sizes
```

### 3. Minimum Touch Targets ✅

**What it is:** Ensuring all interactive elements are at least 44x44pt.

**Implementation:**
- Custom `.minimumTouchTarget()` modifier
- Applied to all buttons and interactive elements
- Extra padding where needed

**Usage:**
```swift
Button("Tap me", action: {})
    .minimumTouchTarget()
```

### 4. Reduced Motion Support ✅

**What it is:** Respecting user preference to minimize animations.

**Implementation:**
- `.accessibleAnimation()` modifier checks system settings
- Animations disabled for users with reduce motion enabled
- Transitions simplified to identity transform

**Usage:**
```swift
view
    .accessibleAnimation(.spring(), value: isExpanded)
    .accessibleTransition(.slide)
```

### 5. High Contrast Mode ✅

**What it is:** Enhanced colors for users who need higher contrast.

**Implementation:**
- Using system colors that automatically adapt
- `.highContrastAdjusted()` modifier for custom colors
- Testing with increased contrast enabled

**Check if enabled:**
```swift
if AccessibilitySettings.isHighContrastEnabled {
    // Use high contrast colors
}
```

### 6. Color Contrast Compliance ✅

**What it is:** Meeting WCAG AA standards for color contrast ratios.

**Compliance:**
- Text contrast ratio: minimum 4.5:1 for normal text
- Large text contrast ratio: minimum 3:1
- UI component contrast: minimum 3:1

**Our Colors:**
- Primary text on background: ✅ Passes (system colors)
- Accent color: ✅ 4.7:1 contrast ratio
- Destructive red: ✅ Passes (system red)

### 7. Accessibility Identifiers ✅

**What it is:** Unique identifiers for UI testing and automation.

**Implementation:**
- Centralized in `AccessibilityIdentifiers` enum
- Applied to all major UI components
- Used for automated accessibility testing

**Usage:**
```swift
view
    .accessibilityIdentifier(AccessibilityIdentifiers.Button.save)
```

## Testing Accessibility

### Manual Testing Checklist

- [ ] **VoiceOver Navigation**
  - Enable VoiceOver (Settings > Accessibility > VoiceOver)
  - Navigate through all screens
  - Verify all elements are reachable
  - Check reading order makes sense
  - Test custom actions

- [ ] **Dynamic Type**
  - Go to Settings > Accessibility > Display & Text Size
  - Test with largest and smallest sizes
  - Verify no text truncation
  - Check layout doesn't break

- [ ] **Increased Contrast**
  - Enable in Settings > Accessibility > Display & Text Size
  - Verify all text is readable
  - Check UI elements have sufficient contrast

- [ ] **Reduce Motion**
  - Enable in Settings > Accessibility > Motion
  - Verify animations are simplified or removed
  - Check no jarring visual changes

- [ ] **Switch Control**
  - Enable in Settings > Accessibility > Switch Control
  - Navigate through app
  - Verify all actions are accessible

- [ ] **Voice Control**
  - Enable in Settings > Accessibility > Voice Control
  - Try voice commands
  - Test button labels are speakable

### Automated Testing

Run Xcode's Accessibility Inspector:
1. Open Xcode
2. Go to Xcode > Open Developer Tool > Accessibility Inspector
3. Select your simulator or device
4. Run inspection on each screen
5. Fix any warnings or errors

### Programmatic Testing

```swift
func testAccessibility() {
    let button = app.buttons["Save"]
    XCTAssertTrue(button.exists)
    XCTAssertTrue(button.isHittable)
    XCTAssertEqual(button.label, "Save event")
    XCTAssertEqual(button.hint, "Double tap to save changes")
}
```

## Best Practices

### 1. Meaningful Labels

❌ Bad:
```swift
Button("X", action: dismiss)
```

✅ Good:
```swift
Button("X", action: dismiss)
    .accessibilityLabel("Close")
    .accessibilityHint("Double tap to close this screen")
```

### 2. Hide Decorative Images

❌ Bad:
```swift
Image(systemName: "star")
    // Decorative image will be read by VoiceOver
```

✅ Good:
```swift
Image(systemName: "star")
    .accessibilityHidden(true)
```

### 3. Group Related Elements

❌ Bad:
```swift
HStack {
    Image(systemName: "clock")
    Text("2:30 PM")
    Text("Sleep")
}
// VoiceOver reads three separate elements
```

✅ Good:
```swift
HStack {
    Image(systemName: "clock")
    Text("2:30 PM")
    Text("Sleep")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Sleep event at 2:30 PM")
```

### 4. Provide Context

❌ Bad:
```swift
Button("Delete", action: delete)
```

✅ Good:
```swift
Button("Delete", action: delete)
    .accessibilityLabel("Delete sleep event")
    .accessibilityHint("Double tap to delete this event")
```

### 5. Mark Headers

❌ Bad:
```swift
Text("Settings")
    .font(.title)
```

✅ Good:
```swift
Text("Settings")
    .font(.title)
    .accessibilityAddTraits(.isHeader)
```

## Common Issues and Solutions

### Issue: VoiceOver reads content in wrong order

**Solution:** Use `.accessibilityElement(children: .contain)` and ensure visual hierarchy matches semantic hierarchy.

### Issue: Buttons are too small to tap

**Solution:** Apply `.minimumTouchTarget()` modifier to ensure 44x44pt size.

### Issue: Text truncates at large Dynamic Type sizes

**Solution:** Use `.fixedSize(horizontal: false, vertical: true)` or restructure layout to be vertically scrollable.

### Issue: Colors don't have enough contrast

**Solution:** Use system colors or test custom colors with contrast ratio tool. Aim for minimum 4.5:1 for text.

### Issue: Animations cause motion sickness

**Solution:** Use `.accessibleAnimation()` modifier instead of `.animation()` to respect reduce motion setting.

## Resources

- [Apple Accessibility Documentation](https://developer.apple.com/accessibility/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [iOS Accessibility Guide](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [VoiceOver Testing Guide](https://developer.apple.com/library/archive/technotes/TestingAccessibilityOfiOSApps/TestAccessibilityonYourDevicewithVoiceOver/TestAccessibilityonYourDevicewithVoiceOver.html)

## Audit Results

Last audit date: October 22, 2025

### Status: ✅ Pass

- ✅ VoiceOver support: All screens navigable
- ✅ Dynamic Type: Text scales correctly
- ✅ Touch targets: All meet 44x44pt requirement
- ✅ Color contrast: WCAG AA compliant
- ✅ Reduced motion: Supported
- ✅ High contrast: System colors used
- ✅ Accessibility identifiers: Implemented
- ✅ No Xcode warnings

### Remaining Work

- [ ] Add VoiceOver rotor support for quick navigation
- [ ] Implement custom accessibility notifications for state changes
- [ ] Add accessibility-specific unit tests
- [ ] Create accessibility demo video for App Store

## Contact

For accessibility-related questions or issues, please open a GitHub issue with the `accessibility` label.
