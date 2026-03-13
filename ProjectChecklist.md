# NFL2K5Tool Web — Project Checklist

**Spec version:** Requirements v1.1 · TestPlan v1.0
**Build target:** Dart → JS (`webdev build` / `dart compile js`)
**Testing:** Dart unit tests (data layer) + Playwright (UI/browser layer)

---

## Core Architecture Principles

### 1. Text is the only in-memory data model

When a gamesave is loaded, `nfl2k5tool_dart` decodes the binary and exposes it as text via
`tool.GetLeaguePlayers(...)`, `tool.GetSchedule()`, etc. That text string (`appState.textContent`)
is the single source of truth for the entire app.

All GUI screens are **views over that text**. When the user changes a value in the GUI, the
change is written **directly back into the text in-place**. The binary gamesave is never
modified until the user explicitly triggers a Save or Export, which calls
`InputParser(tool).ProcessText(textContent)`.

No object graph. No serialize-on-navigate. No Player or Team model classes.

```
Binary file
    ↓  nfl2k5tool_dart  (decode)
    ↓  tool.GetKey(...) + tool.GetLeaguePlayers(...) / GetSchedule() / etc.
┌─────────────────────────────────────┐
│   appState.textContent  (String)    │  ← sole source of truth
└─────────────────────────────────────┘
    ↑ read-for-display   ↑ in-place edits from all GUI screens
    │
    ├── Text Editor     — direct textarea view/edit
    ├── Player Editor   — parse Key + lines for display; field edits → replace value in text
    ├── Coach Editor    — parse CoachKey + lines for display; field edits → replace value in text
    └── Schedule Editor — parse YEAR=/WEEK/game lines for display; edits → replace lines in text
    ↓
    InputParser(tool).ProcessText(textContent)  (on Save/Export)
    ↓
Binary file  →  session.exportTo*()  →  browser download
```

### 2. The Key / CoachKey is the runtime UI schema

`tool.GetKey(showAttributes, showAppearance)` generates a Key string that is embedded at the
top of `textContent` (before the `#` column header line). The Key defines **which CSV columns
are present** in the player data rows for the current session. Coaches have an equivalent
`CoachKey`.

`InputParser.ProcessText()` requires the Key to match the columns in the CSV — a mismatch
produces incorrect or failed data application.

**The Player Editor and Coach Editor UIs are dynamically driven by the Key:**
- `kAttrGroups` defines all *possible* attribute cards
- At render time, the editor parses the active Key out of `appState.textContent` to get the
  *current* column set
- Attribute cards are shown or hidden based on whether their column is present in the Key
- The UI schema is the Key — not a hardcoded list

**Key-related operations:**
- Changing `showAttributes` / `showAppearance` options changes the Key → requires full text
  regeneration (not just filtering the existing text)
- **Reset Key** button → `InputParser(tool).ProcessText('Key=')` — resets the key section
  when it gets out of sync
- Coaches use `CoachKey` — same concept, separate key string

---

## How to use this file

Mark items `[x]` as completed. Add sub-items as needed.
Commit after each phase completes (SuperPowers §4 — atomic commits, human commits, AI suggests).

---

## Phase 0 — Project Setup & Prerequisites

### 0.1 pubspec.yaml
- [ ] Update `pubspec.yaml` to spec version (§3.1):
  - `web: ^1.1.0`
  - `archive: ^3.6.1`
  - `nfl2k5tool_dart` via git dep (`BAD-AL/nfl2k5tool_dart`, ref: main)
  - `webdev: ^3.0.0` (dev)
  - `build_runner: ^2.4.0` (dev)
- [ ] Run `dart pub get` — confirm no resolution errors
- [ ] Run `webdev serve` — confirm bare scaffold compiles

### 0.2 nfl2k5tool_dart API Audit *(complete)*

- [x] **SaveSession** constructors confirmed: `fromXboxZip`, `fromRawDat`, `fromPs2Save`, `fromPs2Card`, `fromXboxMU`
- [x] **SaveSession** export methods confirmed: `exportToXboxZip()`, `exportToPs2Max()`, `exportToPs2Psu()`, `injectIntoPs2Card()`, `injectIntoXboxMU()`
- [x] **Raw DAT export**: `tool.GameSaveData` (`Uint8List?` property on GamesaveTool, not a method)
- [x] **GamesaveTool** text extraction confirmed: `GetKey(bool attributes, bool appearance)`, `GetLeaguePlayers(bool attributes, bool appearance, bool specialTeamers)`, `GetTeamPlayers(String team, bool attributes, bool appearance, bool specialTeams)`, `GetCoachDataAll()`, `GetSchedule()`
- [x] **SaveType** enum values: `SaveType.Roster`, `SaveType.Franchise` (map to "ROSTER" / "FRANCHISE" in UI)
- [x] **InputParser**: `InputParser(GamesaveTool tool)` + `void ProcessText(String text)` — confirmed
- [x] **CoachKey**: property on `GamesaveTool` — `String CoachKey` getter/setter. `String CoachKeyAll` getter.
- [x] **SetKey**: `tool.SetKey(String line)` — sets custom key for parsing
- [x] **Teams**: `GamesaveTool.Teams` is a **static getter** (not instance) — list of 32 NFL teams. `GamesaveTool.sTeamsDataOrder` is also static, includes FreeAgents and DraftClass.
- [x] **PBP/Announcer data**: `kEnfNameIndexContent` in `enf_name_index.dart` — raw string data (numbered ID → name mappings). Parse this for `pbpOptions`.
- [x] **Photo index data**: `kEnfPhotoIndexContent` in `enf_photo_index.dart` — raw string (player name → 4-digit photo ID). Parse for `photoOptions`.
- [x] **Error accumulation**: `StaticUtils.Errors` (static `List<String>`) accumulates errors during ProcessText — useful for error handling and the Apply-to-Save feedback modal.
- [x] **Player search**: `tool.FindPlayer(String? pos, String firstName, String lastName)` → `List<int>` (player indices)

### 0.3 Photo Resource File
- [x] Run: `dart tool/make_resource_file.dart -f tool/PlayerData.zip -n PlayerDataFile -o lib/data/`
- [x] Confirm `lib/data/PlayerDataFile.dart` is generated with `kPlayerDataFile` getter
- [x] Verify it compiles (temporary import test, then remove)

### 0.4 Folder & File Skeleton
- [x] Create `lib/` subdirectories: `shell/`, `screens/`, `widgets/`, `data/`
- [x] Move generated `web/main.dart` and `web/styles.css` to `remove_this/` (SuperPowers §3.1)
- [x] Create empty placeholder Dart files (so imports resolve during development):
  - `lib/main.dart`, `lib/app_state.dart`
  - `lib/shell/shell.dart`
  - `lib/screens/player_editor_screen.dart`, `schedule_editor_screen.dart`, `text_editor_screen.dart`, `options_screen.dart`, `coach_editor_screen.dart`
  - `lib/widgets/top_bar.dart`, `nav_rail.dart`, `status_bar.dart`, `dialogs.dart`, `numeric_field.dart`
  - `lib/data/text_parser.dart`, `schedule_data.dart`, `attr_groups.dart`, `player_mappings.dart`, `player_data_cache.dart`, `app_options.dart`

### 0.5 Reference Mockups
- [ ] Review `Spec/mockup.html` and `Spec/mock_schedule_editor.html` — use as visual reference throughout

---

## Phase 1 — Data Utilities

> These files support **reading** text for display and **in-place editing** of the text.
> They do not own state — `appState.textContent` does.
> Each utility must be verified with a standalone test before integration.

### 1.1 `text_parser.dart` — Text Reading & In-Place Editing (§15.3)

**Purpose:** Three jobs — (1) parse the active Key to determine the current column schema,
(2) parse text into a display-friendly structure for the Player/Coach Editor list/cards,
and (3) locate and replace a field value in the raw text when the user edits it.

- [ ] Implement `parseKey(String text)` → `List<String>` (active column names)
  - Reads the Key section from `textContent` (lines before the `#` header)
  - Returns the ordered list of column names the Key declares as present
  - Same logic for `CoachKey` (same parser, different section marker)
- [ ] Implement `splitCsv(String line)` → `List<String>`
  - `"` only opens a quoted field at the very start of a field
  - Mid-field `"` (e.g. inch mark in `6'0"`) is a literal character
  - Inside a quoted field, `""` = escaped double-quote
- [ ] Implement `quoteCsvField(String field)` → `String`
  - Only adds quotes when the field contains a comma or newline
  - Bare `"` (inch mark) is NOT requoted
- [ ] Implement a **read-only** parse pass for display:
  - Extracts team names and their player rows (as raw `List<String>` CSV fields per row, keyed by column header from the `#` header line)
  - Result is transient — used only to populate the Player Editor list and attribute cards; never stored as the source of truth
- [ ] Implement `findPlayerLineIndex(String text, String teamName, int playerIndexInTeam)` → `int` (line number in text)
- [ ] Implement `setFieldInLine(String text, int lineIndex, String columnHeader, String newValue, List<String> headers)` → `String`
  - Returns a new text string with that field replaced in-place
  - Uses `splitCsv` + `quoteCsvField` to roundtrip the line safely
- [ ] **TDD verify (standalone) — before integration:**
  - `parseKey`: returns correct column list when showAttributes=true vs false (different column sets)
  - `parseKey` with showAppearance=false: appearance columns absent from result
  - T-PARSE-01: Basic player row splits correctly
  - T-PARSE-02: `6'0"` survives a splitCsv → quoteCsvField → rejoin roundtrip
  - T-PARSE-03: Quoted field with comma parses correctly
  - T-PARSE-04: `quoteCsvField` only quotes when comma/newline present
  - Roundtrip: `setFieldInLine` replaces exactly one field, all other fields unchanged, text outside the line unchanged

### 1.2 `schedule_data.dart` — Schedule Display & In-Place Editing (§10.3, §15.7)

**Purpose:** Parse the YEAR=/WEEK/game text block for display in the Schedule Editor, and replace game lines in-place when the user edits them.

- [ ] Implement `kTeamAbbr` map (32 NFL teams, 2004 rosters — §15.7)
- [ ] Implement `kTeamNamesSorted` and `teamAbbr(String name)` helper
- [ ] Implement a **read-only** schedule parse for display:
  - Extracts year, week numbers, and game pairs (`away`, `home` as lowercase full team names)
  - Result is transient — used only to render the schedule grid; never stored as source of truth
- [ ] Implement `setGameInText(String text, int weekNumber, int gameIndex, String newAway, String newHome)` → `String`
  - Returns updated text with that specific `"away at home"` line replaced
- [ ] Implement `removeGameFromText(String text, int weekNumber, int gameIndex)` → `String`
- [ ] Implement `addGameToText(String text, int weekNumber, String away, String home)` → `String`
- [ ] Implement schedule integrity helpers (for Integrity tab, read-only):
  - `gameCountByTeam(String scheduleText)` → `Map<String, int>`
  - `duplicatesByWeek(String scheduleText)` → `List<Set<String>>`
- [ ] **TDD verify (standalone) — before integration:**
  - T-SCHED-PARSE-01: Year extraction
  - T-SCHED-PARSE-02: Week and game parsing
  - T-SCHED-PARSE-03: `setGameInText` replaces exactly the right line; all other lines unchanged
  - Remove game: correct line removed, week game-count comment updated
  - Add game: new line appears in correct week block

### 1.3 `attr_groups.dart` — Attribute Definitions (§9.4)
- [ ] Implement `AttrType` enum: `numeric`, `text`, `dropdown`, `slider`, `datePicker`, `autocomplete`, `mappedId`
- [ ] Implement `AttrDef` (`key`, `label`, `type`, `options`, `min`, `max`)
- [ ] Implement `AttrGroup` (`tabLabel`, `attrs`)
- [ ] Implement `kAttrGroups` — all 5 tabs with correct attrs and types per §9.4
- [ ] Implement `kHeightOptions` — `5'0"` through `7'0"` in 1-inch steps (73 values)

### 1.4 `app_options.dart` — Options & Persistence (§13.3–13.5)
- [ ] Implement `AppOptions` class with all fields and defaults (§13.3, §13.4)
- [ ] `AppOptions.load()` from `window.localStorage`
- [ ] `void save()` to `window.localStorage`
- [ ] **TDD verify:** default values match the spec tables

### 1.5 `player_data_cache.dart` — Photo Cache (§16)
- [ ] Use `kPlayerDataFile` (from generated `lib/data/PlayerDataFile.dart`) — no `fetch` needed
- [ ] Lazy-init: decode ZIP on first access via `package:archive` `ZipDecoder`
- [ ] Parse `PlayerData/FaceFormCategories.json` from within the ZIP for `faceCategories`
- [ ] `getPhoto(int id)` → `Uint8List?` (zero-pads to 4 digits → `PlayerData/NNNN.jpg`)
- [ ] `allPhotoIds` (sorted ascending)
- [ ] `faceCategories` → `Map<String, List<int>>`
- [ ] `photoIdsForCategory(String category)` → `List<int>`
- [ ] **TDD verify:**
  - T-PHOTO-02: `getPhoto(validId)` returns bytes starting with `FF D8 FF`
  - T-PHOTO-03: `getPhoto(99999)` returns null
  - T-PHOTO-04: `allPhotoIds` sorted ascending
  - T-PHOTO-05: `faceCategories` has expected keys
  - T-PHOTO-06: `photoIdsForCategory('darkPlayers')` non-empty subset
  - T-PHOTO-07: ID 4 → `PlayerData/0004.jpg`

### 1.6 `player_mappings.dart` — Photo & PBP Lookups (§15.5)
- [ ] Implement `MappedEntry` (`id`, `name`)
- [ ] `photoOptions` list — from `FaceFormCategories.json` or nfl2k5tool_dart if exposed
- [ ] `pbpOptions` list — from nfl2k5tool_dart or constructed separately (record decision here)
- [ ] `photoIdToDisplayName(String id)` and `pbpIdToDisplayName(String id)`

---

## Phase 2 — App Shell

### 2.1 `web/index.html`
- [ ] Static HTML skeleton with CSS grid areas: `topbar`, `rail`, `content`, `status`
- [ ] Link `app.css`; add `<script defer src="main.dart.js"></script>`
- [ ] Material Symbols font (CDN link)
- [ ] All shell DOM elements with stable IDs/classes for Dart wiring:
  - Top bar: logo, Open/Save/Export buttons, file badge, theme toggle
  - Nav rail: 5 nav items + "EDITORS" label + collapse toggle
  - Status bar: dot, text, counts, version label

### 2.2 `web/app.css`
- [ ] All 13 labeled sections per §19:
  - [ ] §1 CSS Custom Properties — dark `:root` + light `[data-theme="light"]` overrides (§4.1–4.3)
  - [ ] §2 Reset & Base Styles
  - [ ] §3 Shell Layout — body CSS grid, `height: 100vh`, `overflow: hidden` (§5)
  - [ ] §4 Top Bar (§6)
  - [ ] §5 Navigation Rail (§7)
  - [ ] §6 Status Bar (§8)
  - [ ] §7 Player Editor (§9)
  - [ ] §8 Schedule Editor (§10)
  - [ ] §9 Text Editor (§12)
  - [ ] §10 Options Screen (§13)
  - [ ] §11 Dialogs and Modals (§14)
  - [ ] §12 Shared Components — buttons, chips, badges, inputs, toggle switches, placeholders
  - [ ] §13 Light Theme Overrides
- [ ] **Verify:** body fills 100vw × 100vh, no document scroll (T-SHELL-01, T-SHELL-03)
- [ ] **Verify:** grid row heights — topbar 42px, status 24px, content fills remainder (T-SHELL-02)

### 2.3 `lib/app_state.dart` — Global State (§17)
- [ ] `AppState` class:
  - `SaveSession? session`, `GamesaveTool? tool`
  - `String textContent` — **the single source of truth**
  - `String? fileName`, `String? fileType` (FRANCHISE | ROSTER | null)
  - `int teamCount`, `int playerCount`, `String? statusMessage`
  - `NavSection activeSection`, `bool railCollapsed`, `String themeMode`
  - `AppOptions options`
- [ ] `NavSection` enum: `options`, `players`, `schedule`, `coaches`, `textEditor`
- [ ] `hasFile`, `isFranchise` getters
- [ ] `scheduleText` getter and `updateScheduleInText()` (§15.9) — reads/writes slice of `textContent`
- [ ] Simple listener pattern (`addListener`, `notify`)
- [ ] `buildTextContent(GamesaveTool, AppOptions)` → `String` (§15.8)

### 2.4 `lib/main.dart` — Entry Point
- [ ] Initialize `AppState`; load options; apply saved theme to `<html>`
- [ ] Instantiate all screens and widgets
- [ ] Wire Open button → `openFile()` (§18.1)
- [ ] Wire Export button → export format dialog
- [ ] Wire theme toggle → flip `data-theme`, persist
- [ ] Wire nav items → `appState.activeSection` + `appState.notify()`
- [ ] Wire rail collapse toggle

### 2.5 `lib/widgets/top_bar.dart`
- [ ] Logo: "NFL" in `--color-gold`, "2K5 Tool" in `--color-text` (§6.1)
- [ ] Open / Save / Export buttons — correct enabled/disabled states (§6.2)
  - Save is always disabled (no filesystem overwrite in browser)
  - Export disabled until file loaded
- [ ] File badge (FRANCHISE/ROSTER + filename) — only when file loaded (§6.3)
- [ ] Theme toggle button — sun/moon, tooltip (§6.4)
- [ ] **Verify T-TOP-02, T-TOP-03, T-TOP-06**

### 2.6 `lib/widgets/nav_rail.dart`
- [ ] 5 items with icons and labels in correct order (§7.1)
- [ ] "EDITORS" section label
- [ ] Active item: `--color-active-bg`, 2px left gold border, gold icon+text
- [ ] Schedule: 35% opacity + no-op when roster loaded
- [ ] Collapse toggle — 220px ↔ 46px with `200ms ease-in-out`
- [ ] Collapsed: hide labels + section label, show tooltips on hover
- [ ] **Verify T-NAV-01 through T-NAV-07**

### 2.7 `lib/widgets/status_bar.dart`
- [ ] Always `#1A6B3C` regardless of theme
- [ ] Status dot + text: "No File Loaded" / "ROSTER File Loaded" / "FRANCHISE File Loaded"
- [ ] File loaded + counts: separator + `{N} Teams · {M} Players`
- [ ] Transient message support (replaces counts temporarily)
- [ ] Right: version label
- [ ] **Verify T-STATUS-01 through T-STATUS-04**

### 2.8 `lib/shell/shell.dart` — Section Routing
- [ ] Listen to `appState` — show/hide screen elements based on `activeSection`
- [ ] No serialization needed on section switch (text is already authoritative)

---

## Phase 3 — Player Editor Screen

### 3.1 Section Header
- [ ] 44px header: person icon (gold) + "Player Editor" title + subtitle (team name + count, or "No file loaded")

### 3.2 Player List Panel (§9.2.1)
- [ ] On file load: parse `appState.textContent` (read-only pass) to build display list — team names + per-team player rows (position, name, jersey #, years pro)
- [ ] Team dropdown populated from parsed team names
- [ ] Search field (substring match on name or position)
- [ ] Position filter chips: All, QB, RB, WR, TE, OL, DL, LB, DB, K/P (with correct CSV mappings §9.2.1)
- [ ] Scrollable player list rows: position badge, full name, jersey # · years pro
- [ ] Up/Down reorder arrows on selected row — swap rows in `appState.textContent` directly
- [ ] Collapse toggle — 260px ↔ 48px; collapsed shows only position badges with tooltips
- [ ] **Verify T-PLAY-02, T-PLAY-03, T-PLAY-05–T-PLAY-09, T-PLAY-26, T-PLAY-27**

### 3.3 Player Attribute Panel — Header (§9.2.2)
- [ ] "Select a player" placeholder when nothing selected
- [ ] On player select: read fields from the correct line in `appState.textContent` (via `text_parser.dart` read pass)
- [ ] Photo box (56×56px, gold border): shows JPEG from `PlayerDataCache`; hover overlay; click → Face Picker
- [ ] Name (18px bold), meta chips (position, jersey #, team, years pro, handedness, height · weight)

### 3.4 Attribute Tab Bar + Grid
- [ ] On render: call `parseKey(appState.textContent)` to get the active column set
- [ ] Filter `kAttrGroups` against the active column set — only render cards whose key is present in the Key
- [ ] Tabs with no visible cards can be hidden or shown as empty (decide during implementation)
- [ ] 5 possible tabs: Athletic, Skills, Mental, Appearance, Identity
- [ ] Active tab: 2px bottom gold border, gold bold text
- [ ] Flex-wrap grid: 148px cards (240px slider), 8px gap, 16px padding

### 3.5 `lib/widgets/numeric_field.dart` — Numeric Attr Card (§9.3)
- [ ] Integer input 0–99
- [ ] ↑/↓ keys: ±1, clamped — writes new value to `appState.textContent` via `setFieldInLine`
- [ ] Left-half card click → −1; right-half → +1 — same write path
- [ ] Drag bar (4px, gold fill, proportional) — drag sets value, same write path
- [ ] **Verify T-PLAY-15 through T-PLAY-19**

### 3.6 Other Attribute Types (§9.3)
Each type reads from the current player's CSV line and writes changes via `setFieldInLine`:
- [ ] `text` — plain text input
- [ ] `dropdown` — styled `<select>`
- [ ] `slider` — value display + `−` button + `<input type="range">` + `+` button, clamped (§9.3)
- [ ] `datePicker` — M/D/YYYY display + calendar icon → native `<input type="date">`
- [ ] `autocomplete` — text input + dropdown (max 8 suggestions) from college names in loaded text
- [ ] `mappedId` — display name + `id: N` + search icon; Photo → Face Picker, PBP → PBP Picker
- [ ] **Verify T-PLAY-20 through T-PLAY-25, T-PLAY-28, T-PLAY-29**

### 3.7 `lib/widgets/dialogs.dart` — Face Picker Dialog (§14.1)
- [ ] 80vw × 80vh, max 900×700px; ESC closes
- [ ] Header + category dropdown + "Show IDs" checkbox
- [ ] 10-column thumbnail grid; selected photo has gold border; auto-scroll to current on open
- [ ] Click thumbnail → write plain integer ID back to `Photo` field in `appState.textContent` via `setFieldInLine`
- [ ] Object URL caching + revoke on close
- [ ] **Verify T-FACE-01 through T-FACE-06, T-PLAY-30**

---

## Phase 4 — Text Editor Screen

### 4.1 Layout
- [ ] Two-column: Advanced Sidebar (left, collapsible) + Editor Column (right)

### 4.2 Advanced Sidebar (§12.1)
- [ ] Collapsed: 24px strip + right-chevron; expanded: 180px default + resize handle (120–400px)
- [ ] "ADVANCED" header + left-chevron, 5 buttons
- [ ] Button states: all except Clear require file loaded (40% opacity when disabled)
- [ ] **Apply to Save:** `InputParser(tool).ProcessText(appState.textContent)` → feedback modal
- [ ] **List Contents:** `appState.buildTextContent(tool, opts)` → replace `appState.textContent`
- [ ] **Reset Key:** `InputParser(tool).ProcessText('Key=')`
- [ ] **Auto Fix Skin/Face:** `InputParser(tool).ProcessText('AutoFixSkinFromPhoto')`
- [ ] **Clear:** set `appState.textContent = ''`
- [ ] **Verify T-TEXT-14 through T-TEXT-18**

### 4.3 Toolbar (§12.2)
- [ ] Find button: "Find" / "Find  N/M"
- [ ] Wrap toggle: "Wrap: On/Off"; Syntax toggle: "Syntax: On/Off"
- [ ] Active toggle styling: `--color-active-bg`, gold icon+text

### 4.4 Editor Area — Line Gutter + Textarea (§12.2)
- [ ] 48px gutter: chip bg, right-aligned monospace line numbers, `--color-muted` 11px
- [ ] Textarea bound to `appState.textContent` (any edit updates `textContent` directly)
- [ ] Wrap off: horizontal scroll + synchronized 12px scrollbar
- [ ] Line numbers stay synchronized
- [ ] **Verify T-TEXT-01, T-TEXT-02, T-TEXT-03**

### 4.5 Syntax Highlighting (§12.3)
- [ ] Per-line span injection:
  - Line 0 (col header `#` row): italic, `--syntax-header`
  - `Team =` lines: bold, `--syntax-team`
  - Player rows: field 0 → `--syntax-position`; comma → `--syntax-comma`; fields 1–2 → `--syntax-name`; rest → `--syntax-base`
- [ ] **Performance:** only color visible viewport ± 60 lines
- [ ] Search matches: `--syntax-hit` / `--syntax-active`
- [ ] **Verify T-TEXT-04 through T-TEXT-06**

### 4.6 Search (§12.4)
- [ ] Ctrl+F → search input; F3 → next; Shift+F3 → prev
- [ ] All matches highlighted; active match scrolled into view
- [ ] Toolbar shows "N/M"
- [ ] **Verify T-TEXT-07 through T-TEXT-11**

### 4.7 Editor Status Bar
- [ ] `Ln N, Col M   X lines   Y chars` + `  •  N/M matches` when searching
- [ ] **Verify T-TEXT-12, T-TEXT-13**

### 4.8 Apply-to-Save Feedback Modal (§12.5)
- [ ] Scrollable `<pre>` + "Copy to Clipboard" + "Close"

---

## Phase 5 — Schedule Editor Screen

### 5.1 Placeholder State
- [ ] When no franchise loaded: centered icon + "Not available — open a Franchise file…"
- [ ] **Verify T-SCHED-01**

### 5.2 Weekly Grid Tab (§10.2.1)
- [ ] Week picker chips W1–W17
- [ ] On week select: read-only parse of `appState.scheduleText` to render game cards for that week
- [ ] Game card: away team (amber, 900 weight) + "@" + home team (emerald) + × remove
- [ ] Click team box → Team Picker Dialog → on confirm: `setGameInText` → `appState.textContent`
- [ ] × button → `removeGameFromText` → `appState.textContent`
- [ ] "Add Game" (shown when < 16 games) → `addGameToText` → `appState.textContent`
- [ ] **Verify T-SCHED-02 through T-SCHED-10, T-SCHED-15**

### 5.3 Team Matrix Tab (§10.2.2)
- [ ] Read-only parse of `appState.scheduleText` each render
- [ ] 32 rows × W1–W17 + team name; away = amber, home = emerald, bye = `·`
- [ ] **Verify T-SCHED-11, T-SCHED-12**

### 5.4 Integrity Tab (§10.2.3)
- [ ] 4 checks using `gameCountByTeam` and `duplicatesByWeek` (read from `appState.scheduleText`)
- [ ] Pass/fail cards; "N/M checks passed" header
- [ ] **Verify T-SCHED-13, T-SCHED-14**

### 5.5 Team Picker Dialog (§14.4)
- [ ] 320px wide; 4-column grid of `kTeamNamesSorted` abbreviations
- [ ] Selected: gold background; Cancel button; ESC closes
- [ ] **Verify T-SCHED-05, T-SCHED-06**

---

## Phase 6 — Options Screen & Remaining Dialogs

### 6.1 Options Screen (§13)
- [ ] Section cards with gold titles, toggle rows, CSS toggle switches (gold thumb when on)
- [ ] "Text View" section: 8 toggles + confirmation dialog on change when file loaded
  - Confirm → `appState.textContent = appState.buildTextContent(tool, opts)`
  - Cancel → revert toggle (option unchanged)
- [ ] "Auto Update" section: 3 toggles → append/strip text tags in `appState.textContent`
- [ ] Persist all to `window.localStorage` via `AppOptions.save()`
- [ ] **Verify T-OPT-01 through T-OPT-08**

### 6.2 Export Format Picker Dialog (§14.3)
- [ ] 6 format rows; clicking triggers export (see Phase 7.2)
- [ ] **Verify T-FILE-05, T-FILE-06**

### 6.3 PBP Picker Dialog (§14.2)
- [ ] 420×520px; autofocused search; scrollable list; click → write to `PBP` field in text via `setFieldInLine`

### 6.4 Coach Editor Placeholder (§11)
- [ ] Graduation cap icon + "Coach Editor" + subtitle
- [ ] *(When built out: same Key-driven pattern as Player Editor — parse `CoachKey` from `appState.textContent` to determine which attribute cards to render)*

---

## Phase 7 — File I/O & Integration

### 7.1 File Open (§18.1)
- [ ] `<input type="file">` accept: `.ps2,.zip,.dat,.max,.psu,.bin,.img`
- [ ] Read bytes; route to correct `SaveSession.*` constructor by extension (§15.6)
- [ ] Determine `fileType` from `tool.saveType` (FRANCHISE vs ROSTER)
- [ ] Call `appState.buildTextContent(tool, opts)` → set `appState.textContent`
- [ ] Count teams and players (read-only parse pass for status bar)
- [ ] `appState.notify()` to refresh all screens
- [ ] Error → transient status message, no crash
- [ ] **Verify T-FILE-01 through T-FILE-04**

### 7.2 File Export (§18.2)
- [ ] `InputParser(tool).ProcessText(appState.textContent)` — apply text to binary
- [ ] Route to correct `session.export*()` by format (§15.6)
- [ ] `downloadBytes(bytes, filename)` (§18.2)
- [ ] Transient status: "Downloaded: {filename}"
- [ ] **Verify T-FILE-05, T-FILE-06**

### 7.3 Theme Toggle
- [ ] Toggle `data-theme` on `<html>`; persist to localStorage; restore on load (default dark)
- [ ] **Verify T-THEME-01 through T-THEME-04**

### 7.4 Nav Rail Collapse
- [ ] Persist collapsed state to localStorage
- [ ] **Verify T-NAV-02, T-NAV-03, T-NAV-07**

---

## Phase 8 — Dart Unit Tests

### 8.1 Setup
- [ ] Add `test: ^1.25.0` to `dev_dependencies`
- [ ] Create `test/` with `text_parser_test.dart`, `schedule_data_test.dart`, `player_data_cache_test.dart`
- [ ] Create `test/fixtures/` — add `test_franchise.zip`, `test_roster.max`, `test_invalid.txt`

### 8.2 CSV Parser Tests (`text_parser_test.dart`)
- [ ] T-PARSE-01: Basic row splits correctly
- [ ] T-PARSE-02: `6'0"` roundtrips without parse error
- [ ] T-PARSE-03: `"Smith, Jr."` quoted field with comma
- [ ] T-PARSE-04: `quoteCsvField` only quotes when comma/newline present
- [ ] T-PARSE-05/06: Team count and keySection preserved in read pass
- [ ] `setFieldInLine` roundtrip: one field changed, all others identical, rest of text unchanged

### 8.3 Schedule Tests (`schedule_data_test.dart`)
- [ ] T-SCHED-PARSE-01: Year extraction
- [ ] T-SCHED-PARSE-02: Week and game parsing
- [ ] `setGameInText`: correct line replaced, all other lines unchanged
- [ ] `removeGameFromText`: correct line removed
- [ ] `addGameToText`: new line in correct week, count updated

### 8.4 Photo Cache Tests (`player_data_cache_test.dart`)
- [ ] T-PHOTO-02 through T-PHOTO-07 (see Phase 1.5)

### 8.5 CI Gate
- [ ] `dart test` exits 0
- [ ] `dart analyze` exits 0

---

## Phase 9 — Playwright UI Tests

### 9.1 Setup
- [ ] `npm init playwright@latest` in project root — creates `playwright.config.js`, `tests/`, installs browsers
- [ ] Set `baseURL: 'http://localhost:8080'` in `playwright.config.js`
- [ ] Add `"test:e2e": "playwright test"` to `package.json`
- [ ] Confirm `npx playwright test` runs without error (zero tests is fine at this point)
- [ ] Copy test fixture files into a location accessible to Playwright tests

### 9.2 Shell Tests (`tests/shell.spec.js`)
- [ ] T-SHELL-01: No document scroll, body fills full viewport
- [ ] T-SHELL-02: Top bar 42px, status bar 24px
- [ ] T-THEME-01: Default dark — background `#0D1117`
- [ ] T-THEME-02: Click toggle → `html[data-theme="light"]`, background `#F6F8FA`
- [ ] T-THEME-03: Light mode persists after reload
- [ ] T-TOP-02: Save button 50% opacity
- [ ] T-TOP-03: Export button 50% opacity before load
- [ ] T-NAV-02: Rail collapses to 46px

### 9.3 File Operation Tests (`tests/file-ops.spec.js`)
- [ ] T-FILE-02: Franchise load → badge "FRANCHISE", no error
- [ ] T-FILE-03: Roster load → badge "ROSTER", Schedule nav disabled
- [ ] T-NAV-05: Franchise load → Schedule nav enabled
- [ ] T-TOP-06: Export enabled after load
- [ ] T-STATUS-02: "No File Loaded" state
- [ ] T-STATUS-03: Team/player counts shown after load

### 9.4 Player Editor Tests (`tests/player-editor.spec.js`)
- [ ] T-PLAY-05: QB filter shows only QBs
- [ ] T-PLAY-06: OL filter shows G/T/C only
- [ ] T-PLAY-07: DB filter shows CB/FS/SS only
- [ ] T-PLAY-15: ArrowUp ×3 on Speed increments by 3 (verify in text content too)
- [ ] T-PLAY-16: ArrowDown at 0 stays at 0

### 9.5 Text Editor Tests (`tests/text-editor.spec.js`)
- [ ] T-TEXT-02: Line numbers start at 1, increment correctly
- [ ] T-TEXT-07: Ctrl+F opens search
- [ ] T-TEXT-08: Search finds matches, shows "1/N"
- [ ] T-TEXT-13: Status bar shows line/char count
- [ ] T-TEXT-16: Advanced buttons disabled without file

### 9.6 Options Tests (`tests/options.spec.js`)
- [ ] T-OPT-01: All default values correct
- [ ] T-OPT-02: Toggle persists across reload

### 9.7 Theme / Color Regression (`tests/theme.spec.js`)
- [ ] T-STATUS-01: Status bar `#1A6B3C` in both themes
- [ ] No hardcoded hex values leaking outside CSS palette definitions

---

## Phase 10 — Build & Regression

### 10.1 Production Build
- [ ] `webdev build` exits 0; output in `build/web/`
- [ ] Serve `build/web/` statically — smoke-test load, edit, export, theme

### 10.2 Full Regression Checklist
*(Run after any significant change — per TestPlan §16)*
- [ ] Both franchise and roster file types load correctly
- [ ] Player GUI edits appear immediately in Text Editor (text is updated in-place)
- [ ] Schedule GUI edits appear immediately in Text Editor
- [ ] Options changes persist after reload
- [ ] Dark and light themes render correctly; no missing color tokens
- [ ] Face Picker opens, shows photos, returns correct ID written to text
- [ ] Export download works for at least one format
- [ ] No hardcoded hex values outside CSS palette definition

### 10.3 Accessibility
- [ ] Tab through app — all interactive elements have visible focus rings (T-UX-01)
- [ ] Pointer cursor on all clickable elements (T-UX-02)
- [ ] Focus trap in dialogs; ESC closes (T-UX-03)

---

## Appendix A — Test Fixtures Needed

| File | Purpose |
|---|---|
| `test/fixtures/test_franchise.zip` | Valid Xbox Zip franchise (provides schedule data) |
| `test/fixtures/test_roster.max` | Valid PS2 Max roster-only save |
| `test/fixtures/test_invalid.txt` | Wrong content — for error handling tests |

---

## Appendix B — Key Decisions

| Decision | Rationale |
|---|---|
| Text is the only data model | Core philosophy: nfl2k5tool's superpower is text. GUI is a view over the text string. Binary only changes on explicit Save/Export. |
| No Player/Team model classes | Unnecessary abstraction — player data lives in the text. Parser reads fields transiently for display only. |
| In-place text editing (Option A) | All GUI edits go directly to `appState.textContent` via `setFieldInLine` / `setGameInText` etc. No serialize-on-navigate. |
| JS build target | Simpler setup vs WASM; both are spec-valid |
| Embedded `kPlayerDataFile` resource | `make_resource_file.dart` already provided; no static asset fetch needed |
| Dart unit tests + Playwright | Unit tests for data utilities (fast, no browser); Playwright for all DOM/UI interactions |
