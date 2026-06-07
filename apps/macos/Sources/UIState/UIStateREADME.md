# UI State Models

These source-only models describe the state that future SwiftUI/AppKit views will render.

- `IslandState` controls compact or persistent Island presentation.
- `TaskListItem` models Task Center rows.
- `NotificationItem` models internal notifications.
- `HermesUIStateReducer` maps Hermes events into UI state without depending on SwiftUI or an Xcode target.

The reducer intentionally treats normal chat message acceptance as passive so ordinary messages do not open the Island. Task failures and approval requests become persistent Island states and create internal notifications.
