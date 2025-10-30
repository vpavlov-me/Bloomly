# Apple Watch App Guide

## Overview
The bloomy Apple Watch app provides quick, convenient event logging right from your wrist. With large, easy-to-tap buttons and haptic feedback, you can track events without reaching for your iPhone.

## Features

### Quick Actions View
The main interface features large, prominent buttons for the most common tracking actions:

#### 🌙 Sleep Tracking
- **Start/Stop Sleep Session**: Tap the large sleep button to start or stop a sleep session
- **Smart Timer**: If a sleep session is active, tapping again will stop it and log the duration
- **Instant Feedback**: Get haptic feedback and see the duration logged

#### 🍼 Feeding
- **Repeat Last Feed**: Automatically logs a feeding with the same duration as your last feed
- **Default Duration**: If no previous feed exists, logs 15 minutes by default
- **One-Tap Logging**: Perfect for quick logging during busy moments

#### 🧷 Diaper Changes
- **Three Options**: Choose between Wet, Dirty, or Both
- **Tap to Select**: Tap the diaper button to see options
- **Quick Notes**: Automatically adds the type as a note

#### 💧 Pumping
- **Quick Log**: Tap to log a 10-minute pumping session
- **Future Enhancement**: Volume input coming soon

### Haptic Feedback
Every action provides tactile feedback:
- **Tap Feedback**: When you press a button
- **Success Feedback**: When an event is successfully logged
- **Error Feedback**: If something goes wrong

### Watch Connectivity
All events logged on Apple Watch are automatically synced to your iPhone:
- **Real-time Sync**: Events appear on iPhone immediately when connected
- **Background Sync**: Events sync when iPhone becomes available
- **Local Storage**: Events are stored locally on Watch until sync completes

## Complications

### Available Complications
1. **Circular Small** - Shows time since last feed (🍼 2h)
2. **Rectangular** - Shows today's stats (events count + sleep total)
3. **Corner** - Shows today's event count

### Real Data
Complications display actual data from your tracking:
- Time since last feeding
- Total sleep duration today
- Number of events logged today

### Updating Complications
Complications update automatically when new events are logged.

## Navigation

The Watch app has three tabs:

### 1. Quick Log (New!)
- Large action buttons for fast logging
- Haptic feedback on every action
- Success/error messages
- Smart repeat for feeding

### 2. Recent Events
- View your most recent events
- See event types and times
- Quick reference for patterns

### 3. Measurements
- Add weight, height, and head circumference
- Track growth milestones
- View measurement history

## Tips & Best Practices

### For Quick Logging
1. **Raise to Wake**: Enable raise-to-wake for instant access
2. **Add to Dock**: Add bloomy to your Watch dock for quick switching
3. **Use Complications**: Tap your complication to jump directly to the app

### Battery Optimization
- Events are queued for sync when iPhone is unavailable
- Background refresh is optimized to preserve battery
- Local storage ensures no data loss

### During Nighttime
- **Theater Mode**: Use theater mode for nighttime logging
- **Silent Mode**: All haptics work in silent mode
- **Auto-Lock**: The app respects your auto-lock settings

## Analytics

The Watch app tracks anonymous usage:
- `watch.app.opened` - When app is launched
- `watch.event.logged` - When any event is logged
- `watch.quickAction.used` - When quick action buttons are used
- `watch.sync.completed` - When sync with iPhone completes

## Troubleshooting

### Events Not Syncing
1. Ensure Watch and iPhone are connected (check Bluetooth)
2. Open the iPhone app to trigger sync
3. Check Watch Connectivity status in iPhone app settings

### Complications Not Updating
1. Force touch the watch face and select "Edit"
2. Remove and re-add the bloomy complication
3. Log a new event to trigger an update

### Haptic Feedback Not Working
1. Check that Silent Mode is off (or haptics are enabled in silent mode)
2. Ensure your Watch's Taptic Engine is working (Settings → Sounds & Haptics)

## Future Enhancements

Planned features:
- [ ] Volume input for pumping
- [ ] Quick note dictation via Siri
- [ ] Customizable quick actions
- [ ] Watch face widgets (watchOS 10+)
- [ ] Standalone Watch mode (no iPhone required)

## Technical Details

### Requirements
- watchOS 10.0 or later
- iPhone with iOS 17.0 or later
- Watch paired with iPhone

### Architecture
- **WatchApp** SPM module with all Watch-specific code
- **WatchConnectivity** framework for iPhone ↔ Watch communication
- **ClockKit** for complications
- **WatchKit** for haptic feedback
- **Local Core Data** for offline storage

### Dependencies
- AppSupport (analytics, utilities)
- Tracking (event models and repositories)
- Content (localizations)
- Sync (CloudKit integration)
- Measurements (measurement tracking)

## See Also
- [Main README](../README.md)
- [Architecture Documentation](architecture.md)
- [CloudKit Sync Guide](cloudkit.md)
