# Franken Shell — Calendar

> **Path:** `docs/features/calendar.md`
> **Status:** Implementation specification
> **Primary phases:** Phase 6 — Local Calendar; Phase 8 — Google Calendar Integration
> **Related specifications:** `bar.md`, `control-centre.md`, `notifications.md`, `multi-monitor.md`

This document specifies the dedicated calendar surface opened by the combined date/time bar item. A full calendar must not be duplicated in the control centre.

---

# 1. Product Role

The first version is a fast local month calendar. Immediately after the working prototype, a provider-neutral event model adds Google Calendar without making local date navigation depend on network, accounts, or sync.

# 2. Settled Requirements

- Date and time are one bar control using 24-hour time by default.
- Primary activation opens the dedicated calendar surface.
- The prototype includes current full date, month grid, previous/next month, Today, selected day, and keyboard/pointer navigation.
- It does not show a large permanently empty agenda area.
- Weather is not added as filler.
- Google Calendar follows the prototype through a provider-neutral model.
- Local month navigation remains usable offline and when every provider is disabled or failed.
- Secrets/tokens never live in shell configuration.
- Routine calendar reminders respect DND/fullscreen by default.

# 3. Ownership

Calendar owns local date/month state, selected-date policy, month grid, provider-neutral accounts/calendars/events/sync models, and calendar-specific actions.

It does not own:

- bar date/time formatting beyond its trigger contract;
- control-centre layout;
- notification popup/DND policy;
- browser or external calendar application execution;
- OAuth/token-storage implementation in view QML;
- a todo system.

# 4. Proposed Structure

```text
services/calendar/
├── CalendarService.qml
├── CalendarProvider.qml
└── GoogleCalendarProvider.qml

features/calendar/
├── CalendarController.qml
├── CalendarPopover.qml
├── MonthGrid.qml
├── AgendaView.qml
└── fixtures/CalendarFixtureModel.qml
```

Calendar providers own account/sync transport and provider-specific mapping. `CalendarController` owns local month/selection presentation state and merges provider-neutral event models. Month/agenda views render state and request controller/provider capabilities without parsing provider payloads.

# 5. State and Models

Local state:

```text
today
visibleMonth
selectedDate
firstDayOfWeek
weekRows[]
locale
```

Provider-neutral state anticipates:

```text
accounts[]
calendars[]
eventsForVisibleRange[]
selectedDateEvents[]
syncState
offline
lastSuccessfulSync
lastError
```

Events need stable provider ID, calendar ID, title, start/end, all-day flag, timezone, recurrence identity, colour role, status, location/link metadata as allowed, and capability flags. Google response objects must not leak into views.

# 6. Controller and Provider Contract

```text
showPreviousMonth()
showNextMonth()
showToday()
selectDate(date)
openEvent(eventId)
createEvent(initialDate)
refresh()
```

Provider contract:

```text
eventsForRange(start, end)
createEvent(data)
updateEvent(id, data)
deleteEvent(id)
sync()
```

Create/update/delete may be deferred until the Phase 8 provider scope is confirmed; the interface must not imply unsupported capability.

# 7. Interaction

- Primary activation toggles the calendar popover.
- No month-change scroll action is required initially. Scroll belongs to agenda content when an agenda exists; a later month-header mapping requires explicit prototype validation.
- Hover provides date/event summaries without changing selection.
- Drag does not create or move events in the initial scope.
- Primary click or `Enter` selects a date or invokes the focused visible action. Secondary and middle-click have no initial action.
- `Left`/`Right` move by day, `Up`/`Down` move by week, `PageUp`/`PageDown` change month, and `Home` or the visible Today action returns to the current date.
- Focused date and selected date remain visually distinct.
- The configurable calendar shortcut uses the same `SurfaceCoordinator` opening path as the date/time bar item.

Today, selected date, keyboard focus, outside-month dates, and event presence must not rely on colour alone. Accessible date labels include full unambiguous dates, and text scaling/reduced motion preserve the month-grid reading order.

# 8. Opening, Dismissal, and Focus

On keyboard open, focus the current day when it is in the visible month; otherwise navigate to the current month and focus the current day. Pointer opening does not steal keyboard focus until keyboard navigation begins. The panel opens inward from the bar edge and remains an ordinary globally exclusive bar popover.

Nested event/agenda views return to the month view before closure. `Escape` unwinds nested navigation, then closes and restores focus to the date/time item. Provider loading must not block opening or local navigation.

Outside click closes ordinary calendar state. It must not silently discard a future event edit or authentication flow.

# 9. Loading, Empty, Offline, and Failure States

- Local month data is always immediately available.
- No events produces a compact selected-day empty state, not a large blank region.
- Provider disabled/unauthenticated/offline/syncing/stale/failed are distinct.
- Stale cached events may remain labeled with last sync time.
- Authentication expiry offers Reconnect without exposing tokens.
- Permission-denied calendars are omitted or explained.
- One provider failure does not hide local calendar or other providers.
- Timezone/recurrence parse failures isolate affected events and create diagnostics.

# 10. Dependencies, Privacy, and Configuration

Dependencies:

- system date/time and locale;
- `ConfigService`, `CapabilityRegistry`, `Diagnostics`;
- `SurfaceCoordinator`, `MonitorRegistry`, `CommandRegistry`;
- secure credential store and Google provider/helper in Phase 8;
- notification/reminder publisher.

Configuration owns first day of week, week-number preference, enabled providers, non-secret account/calendar preferences, and sync cadence. Event contents and tokens are not logged.

# 11. Multi-Monitor and Performance

Provider/account/event data is global. Whether visible-month and selected-date presentation state is shared across invocations or restored per invocation remains unresolved. Popover monitor ownership follows the trigger and `multi-monitor.md`. Owner removal closes safely and restores focus through fallback policy.

Month-grid calculation is deterministic and cheap. Provider range queries are bounded to visible/agenda ranges, cached, asynchronous, and cancellable where practical. Hidden surfaces stop presentation timers; network sync follows provider cadence, not animation frames.

# 12. Fixtures

- each month start/end shape, leap year, locale and first-day variants;
- today in/out of visible month;
- no events; all-day/timed/overlapping/multi-calendar events;
- long titles, timezone transitions, recurrence;
- provider disabled, unauthenticated, syncing, offline, stale, failed;
- token expiry and permission denied;
- mixed-scale/rotated owner monitor.

# 13. Implementation Phases

1. **Phase 2 trigger fixture:** date/time activation, inward anchor, and placeholder focus/restoration.
2. **Phase 6 local calendar:** controller, month grid, Today/selection, keyboard navigation, and all bar orientations with no provider dependency.
3. **Phase 8 provider foundation:** neutral models, account/sync/error contracts.
4. **Phase 8 Google integration:** secure auth, selected calendars, events, offline/cache, open/create as approved.
5. **Phase 10/11:** monitor, locale, accessibility, and visual hardening.

# 14. Acceptance Criteria

- The local month grid and current-day focus become usable without waiting for network or provider-account state.
- Previous/next and PageUp/PageDown change month; Today and Home return to the current date; arrow keys move the focused date by day or week.
- No full calendar appears in the control centre.
- Empty days do not reserve a large empty agenda.
- Provider loading/failure cannot block local month navigation.
- Tokens are absent from configuration, diagnostics, and logs.
- Multiple calendars/events use provider-neutral models.
- `Escape` unwinds nested views and restores focus correctly.
- Keyboard opening focuses the current day, and pointer/keyboard date selection have equivalent results.
- The configurable calendar shortcut and the bar item use the same controller and `SurfaceCoordinator` opening path; they do not create parallel calendar surfaces.

# 15. Unresolved Questions

- **Q-068:** provider-neutral operations, recurrence, timezone, cache, and mutation depth.
- **Q-069:** Google authentication flow.
- **Q-070:** secure credential storage.
- **Q-071:** post-integration month/agenda hierarchy.
- **Q-072:** reminder/DND/sound policy.
- Exact event creation/editing scope and per-invocation viewport restoration remain open.

# 16. Codex Implementation Guardrails

- Do not couple local month rendering to Google.
- Do not store OAuth tokens in config or ordinary state files.
- Do not add weather or todo content.
- Do not duplicate the calendar in the control centre.
