# NFL2K5Tool Web App — Requirements

**Version:** 1.1 (revised: Dart/HTML instead of vanilla JS)
**Purpose:** Specification for a single-page Dart/HTML application that replicates the NFL2K5Tool Flutter GUI exactly — same functionality, same visual design, dramatically better browser performance than Flutter web.

---

## 1. Project Overview

NFL2K5Tool is a gamesave editor for the 2004 video game ESPN NFL 2K5. The tool reads proprietary binary save files (PS2 memory card, Xbox Memory Unit, etc.) and presents them as an editable CSV-like text format. This web app is a full GUI for viewing and editing those files in the browser.

**Key characteristics:**
- Single-page app — no page navigation, no server required (static files only after build)
- All file I/O is client-side: files opened via `<input type="file">`, downloaded via `Blob` + `<a download>`
- Binary decode/encode is handled by `nfl2k5tool_dart` — imported directly as a Dart package dependency (no JS bridge needed)
- Supports dark mode and light mode, togglable at runtime
- Logic is written in Dart, compiled to JavaScript via `dart compile js` or `webdev build`
- HTML and CSS are static, framework-free source files — no widget tree, native DOM rendering

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Structure | Plain HTML5 — `index.html` is a static source file, not generated |
| Styling | Plain CSS3 — `app.css` is a static source file; no CSS framework |
| Logic | Dart (`package:web` for DOM access) |
| Binary parsing | `package:nfl2k5tool_dart` — direct Dart import, no bridge |
| ZIP extraction | `package:archive` — Dart ZIP/archive library |
| Icons | Google Material Symbols font (CDN or self-hosted) |
| Fonts | System monospace for editor; system sans-serif for UI |
| Build | `webdev build` / `dart compile js` (JavaScript) or `dart compile wasm` (WebAssembly) — both are valid; the implementing agent may choose either. JS is the simpler default; WASM may offer better performance for binary file parsing. |

**Why Dart/HTML instead of vanilla JS:**
- `nfl2k5tool_dart` is imported directly as a pub dependency — no compilation bridge required
- All data-layer logic (CSV parser, schedule model, player model, attr groups, photo cache) is fully specified in this document as standalone Dart files with no framework dependencies
- `package:web` is well-documented and the implementing agent has strong knowledge of it
- `dart:html` is the older alternative; **use `package:web` throughout**

---

## 3. File and Folder Structure

The project root is assumed to be `nfl2k5_web` for the purposes of the following description, actual root folder name could change in implementation. This is a standalone Dart web project.

```
nfl2k5_web                      ← Dart web project root (also the repo subfolder)
  pubspec.yaml                      ← Dependencies: nfl2k5tool_dart, package:web, archive
  analysis_options.yaml
  web/
    index.html                      ← Entry point: shell skeleton, loads app.dart.js
    app.css                         ← All styles (see §19 for section map)
    assets/
      PlayerData.zip                ← Player face JPEG archive (provided separately; see §16)
      FaceFormCategories.json       ← Face category index (may be embedded inside
                                       PlayerData.zip as PlayerData/FaceFormCategories.json,
                                       or provided as a standalone file alongside the zip)
  lib/
    main.dart                       ← Entry: initialises AppState, wires shell to DOM
    app_state.dart                  ← Global mutable state + change notification
    shell/
      shell.dart                    ← Top bar, nav rail, status bar, section routing
    screens/
      player_editor_screen.dart     ← Player list panel + attribute panel
      schedule_editor_screen.dart   ← Weekly grid, team matrix, integrity
      text_editor_screen.dart       ← Syntax textarea, toolbar, advanced sidebar
      options_screen.dart           ← Toggle options, persistence
      coach_editor_screen.dart      ← Placeholder
    widgets/
      top_bar.dart
      nav_rail.dart
      status_bar.dart
      dialogs.dart                  ← Face picker, PBP picker, team picker, export picker
      numeric_field.dart            ← Numeric attr card (drag bar, ±1 click zones)
    data/
      text_parser.dart              ← parseTeamsFromText, teamsToText, ParseResult (§15.3)
      schedule_data.dart            ← ScheduleData, ScheduleWeek, ScheduleGame, kTeamAbbr (§10, §15.7)
      player.dart                   ← Player, Team models (§15.4)
      attr_groups.dart              ← kAttrGroups, AttrDef, AttrType, kHeightOptions (§9.4)
      player_mappings.dart          ← photoOptions, pbpOptions, photoIdToDisplayName (§15.5)
      player_data_cache.dart        ← ZIP-based photo cache; fetch from assets/ (§16)
      app_options.dart              ← Options model; persisted to localStorage (§13.5)
  build/                            ← Generated by webdev build (gitignored)
```

### 3.1 pubspec.yaml

```yaml
name: nfl2k5tool_web
description: NFL2K5Tool single-page web app
publish_to: none

environment:
  sdk: ^3.4.0

dependencies:
  web: ^1.1.0
  archive: ^3.6.1
  nfl2k5tool_dart:
    git:
      url: https://github.com/BAD-AL/nfl2k5tool_dart.git
      ref: main

dev_dependencies:
  webdev: ^3.0.0
  build_runner: ^2.4.0
```

### 3.2 Build and Serve

```bash
# Development (hot reload)
dart pub get
webdev serve

# Production build (outputs to build/web/)
webdev build
# Serve build/web/ as static files
```

The compiled output (`build/web/`) is a fully self-contained static directory.

---

## 4. Color Palette and Theme

All colors are expressed as CSS custom properties on `:root` (dark) and `[data-theme="light"]`.

### 4.1 Color Token Definitions

```css
/* Accent colors — same in both themes */
--color-gold:        #C9A227;   /* primary accent: active items, highlights */
--color-turf:        #1A6B3C;   /* status bar background */
--color-success:     #3FB950;   /* pass / ok indicator */
--color-danger:      #CF222E;   /* error indicator */

/* Dark theme (default) */
--color-bg:          #0D1117;   /* page background */
--color-surface:     #161B22;   /* cards, top bar, panels */
--color-border:      #30363D;   /* all borders and dividers */
--color-chip:        #21262D;   /* input fill, badge backgrounds */
--color-text:        #E6EDF3;   /* primary text */
--color-muted:       #8B949E;   /* secondary / label text */
--color-rail-bg:     #0D1117;   /* nav rail (same as bg in dark) */
--color-active-bg:   rgba(201,162,39,0.12); /* selected item background */

/* Light theme overrides */
[data-theme="light"] {
  --color-bg:        #F6F8FA;
  --color-surface:   #FFFFFF;
  --color-border:    #D0D7DE;
  --color-chip:      #E8EAED;
  --color-text:      #1F2328;
  --color-muted:     #656D76;
  --color-rail-bg:   #F0F2F5;
  --color-active-bg: rgba(201,162,39,0.12);
}
```

### 4.2 Text Editor Syntax Colors

```css
/* Dark syntax */
--syntax-team:       #C9A227;   /* "Team = …" lines — gold, bold */
--syntax-header:     #6E7681;   /* Column header row — italic */
--syntax-position:   #3FB950;   /* First CSV field (position code) — green */
--syntax-name:       #E6EDF3;   /* Fields 2–3 (fname, lname) — bright */
--syntax-number:     #79C0FF;   /* Numeric tokens — sky blue */
--syntax-string:     #FFB86C;   /* Other non-numeric tokens — peach */
--syntax-comma:      #484F58;   /* Commas — dim */
--syntax-base:       #E6EDF3;   /* Everything else */
--syntax-hit:        rgba(201,162,39,0.33);  /* Search match background */
--syntax-active:     rgba(201,162,39,0.80);  /* Active search match background */

/* Light syntax overrides */
[data-theme="light"] {
  --syntax-team:     #835C00;
  --syntax-header:   #656D76;
  --syntax-position: #1A7F37;
  --syntax-name:     #1F2328;
  --syntax-number:   #0969DA;
  --syntax-string:   #CF6426;
  --syntax-comma:    #AFB8C1;
  --syntax-base:     #1F2328;
}
```

### 4.3 Schedule Editor Colors

```css
--schedule-away:   #F59E0B;   /* Away team label — amber */
--schedule-home:   #10B981;   /* Home team label — emerald */
```

---

## 5. App Shell Layout

The app uses a CSS Grid layout that fills the full viewport. No scrolling at the document level — each panel scrolls internally.

```
┌──────────────────────────────────────────────────────────────────┐
│  TOP BAR (42px fixed height)                                     │
├──────────┬───────────────────────────────────────────────────────┤
│          │                                                       │
│   NAV    │            MAIN CONTENT AREA                         │
│   RAIL   │            (scrolls internally per section)          │
│ 220px /  │                                                       │
│  46px    │                                                       │
│ collapse │                                                       │
│          │                                                       │
├──────────┴───────────────────────────────────────────────────────┤
│  STATUS BAR (24px fixed height)                                  │
└──────────────────────────────────────────────────────────────────┘
```

CSS grid template:
```css
body {
  display: grid;
  grid-template-rows: 42px 1fr 24px;
  grid-template-columns: auto 1fr;
  grid-template-areas:
    "topbar  topbar"
    "rail    content"
    "status  status";
  height: 100vh;
  overflow: hidden;
}
```

The nav rail animates its width between 220px (expanded) and 46px (collapsed) using a CSS transition (`width 200ms ease-in-out`).

---

## 6. Top Bar

**Height:** 42px
**Background:** `--color-surface`
**Border-bottom:** 1px solid `--color-border`
**Padding:** 0 16px
**Layout:** flexbox row, align-items center

### 6.1 Logo

Left-most element. Text: `NFL` (in `--color-gold`, bold) + `2K5 Tool` (in `--color-text`, bold). Font-size 15px, letter-spacing 0.5px, font-weight 700.

### 6.2 Action Buttons

Three buttons in a row, separated by 6px gaps:

| Button | Style | Enabled condition |
|---|---|---|
| **Open File** | outlined (bordered, chip bg) | always |
| **Save** | filled (`--color-gold` bg, black text) | always disabled in browser (no filesystem overwrite) |
| **Export Save** | outlined | file loaded |

Button anatomy: icon (13px) + label (12px), padding 10px horizontal / 4px vertical, border-radius 6px, border 1px.

When disabled: 50% opacity, not clickable.

### 6.3 File Badge (center-right)

Appears only when a file is loaded. Chip with border, chip background color.
Contents: file type label (`FRANCHISE` or `ROSTER`) in `--color-gold` bold 11px, then filename in `--color-muted` 11px.
Gap between type and name: 6px.

### 6.4 Theme Toggle

Right-most element. Bordered button with a sun icon (light mode) or moon icon (dark mode), 16px icon, tooltip "Switch to Light/Dark mode". Clicking toggles `data-theme` on `<html>`.

---

## 7. Navigation Rail

**Expanded width:** 220px
**Collapsed width:** 46px
**Background:** `--color-rail-bg`
**Border-right:** 1px solid `--color-border`
**Width transition:** `200ms ease-in-out`

### 7.1 Nav Items

Five navigation items. Each item:
- Icon (18px) + label text (13px, shown only when expanded)
- Padding: 10px horizontal / 8px vertical when expanded; centered vertically when collapsed
- Horizontal margin 6px, vertical margin 1px
- Border-radius: 6px
- Active state: background `--color-active-bg`, left border 2px solid `--color-gold`, icon and text in `--color-gold`, font-weight 600
- Inactive state: icon and text in `--color-muted`
- Collapsed: show tooltip with item label on hover

**Items in order:**

1. **Options** (gear icon) — no section label above it
2. *(divider + "EDITORS" section label in 10px uppercase muted text)*
3. **Players** (person icon) — always enabled
4. **Schedule** (calendar icon) — disabled/greyed (35% opacity) unless a Franchise file is loaded
5. **Coaches** (graduation cap icon) — always enabled
6. **Text Editor** (edit-note icon) — always enabled

### 7.2 Collapse Toggle

At the bottom of the rail, a 36px tall row with a top border.
- Expanded: shows a left-chevron icon aligned to the right
- Collapsed: shows a right-chevron icon centered

Clicking toggles the rail width.

---

## 8. Status Bar

**Height:** 24px
**Background:** `#1A6B3C` (turf green, always — not theme-dependent)
**Padding:** 0 14px
**Layout:** flexbox row, align-items center

**Left side:**
- Filled circle (7×7px): green (`#3FB950`) when file loaded, semi-transparent white when not
- Text: `FRANCHISE File Loaded` / `ROSTER File Loaded` / `No File Loaded`
- When a transient status message is set: vertical separator (1px, 12px tall, semi-transparent white) + message text
- When no message but file loaded and teamCount > 0: separator + `{N} Teams · {M} Players`

**Right side:**
- Text: `NFL2K5Tool Web v1.0.0`

All status bar text: white at 70% opacity, 11px.

---

## 9. Player Editor Screen

This is the most complex screen. It occupies the full content area.

### 9.1 Section Header

Height: 44px, `--color-surface` background, border-bottom.
Left: person icon (18px, `--color-gold`) + title "Player Editor" (14px, bold) + subtitle showing current team name and player count (or "No file loaded") in 11px muted.

### 9.2 Two-Column Layout

Below the header: flexbox row stretching to fill remaining height.

**Left: Player List Panel**
**Right: Player Attribute Panel** (fills remaining width)

#### 9.2.1 Player List Panel

Default width: 260px. Collapsed width: 48px. Collapse animation: `width 200ms ease-in-out`.

When expanded, top-to-bottom:

1. **Team Dropdown** (8px padding all sides, border-bottom)
   Native `<select>` styled to match the theme. Lists all teams in roster order. Changing the team loads that team's players.

2. **Search Field** (8px padding, border-bottom)
   Text input with a search icon prefix. Placeholder: "Search players…". Filters the list by name or position substring.

3. **Position Filter Chips** (8px horizontal + 6px vertical padding, border-bottom)
   A wrapping row of 10 filter chips:
   `All`, `QB`, `RB`, `WR`, `TE`, `OL`, `DL`, `LB`, `DB`, `K/P`

   Position mapping to CSV values:
   - `OL` → G, T, C
   - `DL` → DE, DT, NT
   - `LB` → ILB, OLB, MLB
   - `DB` → CB, FS, SS
   - `RB` → RB, FB, HB
   - `K/P` → K, P
   - All others match the CSV Position field directly

   Active chip: `--color-active-bg` background, `--color-gold` border and text.
   Inactive chip: `--color-chip` background, `--color-border` border, `--color-muted` text.
   Font-size 10px.

4. **Player List** (scrollable, fills remaining height)
   Each row contains:
   - Position badge (32px wide): chip with border, 9px bold text. Border and text gold when selected, muted otherwise.
   - Player full name (12px, 500 weight)
   - Jersey number and years-pro on a second line: `#N · M yr` (10px, muted)
   - On the selected row: Up/Down arrow buttons (16px icons) for reordering the player's depth-chart position (swaps player with the one above/below in the filtered list). Buttons are hidden (not just disabled) when no file is loaded.

   Selected row background: `--color-active-bg`.
   Row border-bottom: `--color-border` at 40% opacity.
   Row padding: 7px vertical / 10px horizontal.

   Collapsed mode: show only the position badge, centered. Tooltip shows full name + position.

5. **Collapse Toggle** (28px tall, border-top, `--color-surface` background)
   Expanded: "Collapse" label + left-chevron, right-aligned.
   Collapsed: right-chevron, centered.

#### 9.2.2 Player Attribute Panel

When no player is selected: centered placeholder with a large person icon, "Select a player" heading, and "Choose a player from the list to edit their attributes." subtext, all in `--color-muted`.

When a player is selected, top-to-bottom:

**Player Header** (padding: 14px top, 16px sides, 12px bottom; `--color-surface` bg; border-bottom)

- **Photo Box** (56×56px, border-radius 8px, border 1.5px `--color-gold`):
  - Shows JPEG from `PlayerData.zip` if available, otherwise a person icon + photo ID
  - On hover: dark overlay (black at 38% opacity) with a camera icon (white, 70% opacity)
  - Clicking opens the Face Picker Dialog (§14.1)
  - Cursor: pointer

- Player full name (18px, bold)
- Meta chips (12px, `--color-muted` text, space-separated):
  - Position, Jersey #, Team name, Years Pro (e.g. "3 yrs pro"), Handedness (in `--color-gold`), Height · Weight lbs

**Attribute Tab Bar** (horizontal scrollable, `--color-surface` bg, border-bottom)

Five tab labels. Active tab: 2px bottom border in `--color-gold`, text in `--color-gold`, bold. Inactive: muted text.

Tab labels (in order):
1. Athletic
2. Skills
3. Mental
4. Appearance
5. Identity

**Attribute Grid** (scrollable, 16px padding all sides)

A `flex-wrap` grid of attribute cards. Card widths:
- Slider type: 240px
- All other types: 148px
- Gap between cards: 8px

Each card:
- Background: `--color-chip`
- Border: 1px `--color-border`
- Border-radius: 8px
- Padding: 8px vertical / 10px horizontal
- Label on top (10px, `--color-muted`)
- Control below (type-specific, see §9.3)

#### 9.3 Attribute Types

**numeric** — A text input showing the value (integer 0–99). Behaviors:
- Up/Down arrow keys increment/decrement by 1, clamped to 0–99
- Clicking the left half of the card (but not the input itself) decrements by 1
- Clicking the right half of the card increments by 1
- Below the input: a horizontal bar (full card width, 4px tall, border-radius 2px) that shows the value as a proportion of 0–99. Bar fill color: `--color-gold`. Dragging the bar sets the value proportionally.

**text** — Plain text input, no border decoration.

**dropdown** — A styled `<select>` element, themed to match surface colors.

**slider** — Displays:
- Current value in bold (14px)
- A row: minus button (`−`, 22×22px bordered chip) + HTML `<input type="range">` + plus button (`+`)
- Range styled: track 3px height, thumb 12px, active track `--color-gold`, inactive track `--color-border`
- Buttons clamp to slider min/max

**datePicker** — Displays the current date value (format: `M/D/YYYY`) and a small calendar icon. Clicking opens the browser's native `<input type="date">` picker. Displayed as "Tap to set" (muted) when empty.

**autocomplete** — Text input with a dropdown list of matching options shown below as the user types (max 8 suggestions visible at once). Options come from all colleges present in the currently loaded roster. Selecting a suggestion fills the field.

**mappedId** — Two variants, both show: display name (bold 12px) + id label (`id: N`, 9px muted) + search icon.
- `Photo` key: clicking opens Face Picker Dialog (§14.1)
- `PBP` key: clicking opens Mapped ID Picker Dialog (§14.2)

### 9.4 Attribute Group Definitions

These are defined in `lib/data/attr_groups.dart`. The file provides `AttrDef`, `AttrType`, `AttrGroup`, the `kAttrGroups` list, and `kHeightOptions` — implement as specified below and referenced throughout this section.

For reference, the five groups and their attribute types are:

#### Tab 1 — Athletic
Speed, Agility, Strength, Jumping, Stamina, Durability — all `numeric`

#### Tab 2 — Skills
PassAccuracy, PassArmStrength, PassReadCoverage, Scramble — `numeric`
PowerRunStyle — `dropdown` (Finesse, Balanced, Power)
Coverage, PassRush, RunCoverage, PassBlocking, RunBlocking, Catch, RunRoute, BreakTackle, HoldOntoBall, Tackle, KickPower, KickAccuracy — `numeric`

#### Tab 3 — Mental
Leadership, Composure, Consistency, Aggressiveness — `numeric`

#### Tab 4 — Appearance
BodyType — `dropdown` (Skinny, Normal, Large, ExtraLarge)
Skin — `dropdown` (Skin1–Skin22)
Face — `dropdown` (Face1–Face15)
Dreads — `dropdown` (No, Yes)
Helmet — `dropdown` (Standard, Revolution)
FaceMask — `dropdown` (FaceMask1–FaceMask27)
Visor — `dropdown` (None, Dark, Clear)
EyeBlack, MouthPiece — `dropdown` (No, Yes)
LeftGlove, RightGlove — `dropdown` (None, Type1–Type4, Team1–Team4, Taped)
LeftWrist, RightWrist — `dropdown` (None, SingleWhite, DoubleWhite, SingleBlack, DoubleBlack, NeopreneSmall, NeopreneLarge, ElasticSmall, ElasticLarge, SingleTeam, DoubleTeam, TapedSmall, TapedLarge, Quarterback)
LeftElbow, RightElbow — `dropdown` (None, White, Black, WhiteBlackStripe, BlackWhiteStripe, BlackTeamStripe, Team, WhiteTeamStripe, Elastic, Neoprene, WhiteTurf, BlackTurf, Taped, HighWhite, HighBlack, HighTeam)
Sleeves — `dropdown` (None, White, Black, Team)
LeftShoe, RightShoe — `dropdown` (Shoe1–Shoe6, Taped)
NeckRoll — `dropdown` (None, Collar, Roll, Washboard, Bulging)
Turtleneck — `dropdown` (None, White, Black, Team)

#### Tab 5 — Identity
fname, lname, JerseyNumber — `text`
Position — `dropdown` (QB, K, P, WR, CB, FS, SS, RB, FB, TE, OLB, ILB, C, G, T, DT, DE)
College — `autocomplete`
DOB — `datePicker` (M/D/YYYY format)
YearsPro — `text`
Hand — `dropdown` (Right, Left)
Weight — `slider` (min 100, max 400)
Height — `dropdown` (5'0" → 7'0" in 1-inch steps, 73 options — use `kHeightOptions`)
Photo — `mappedId` (opens Face Picker)
PBP — `mappedId` (opens PBP Picker)

---

## 10. Schedule Editor Screen

Only available when a **Franchise** file is loaded. When unavailable: show a centered placeholder icon + "Schedule Editor" title + "Not available — open a Franchise file to edit the schedule" subtitle.

The schedule data model, parser, and serializer are defined in `lib/data/schedule_data.dart`. It provides `ScheduleData`, `ScheduleWeek`, `ScheduleGame`, `kTeamAbbr`, `kTeamNamesSorted`, and `teamAbbr()` — implement as specified in §10.3 and §15.7.

### 10.1 Schedule Text Format

The schedule lives in the main text content after the player data, starting at a line beginning with `YEAR=`:

```
YEAR=2004

WEEK 1  [16 games]
colts at patriots
jaguars at bills
...
```

All team names are lowercase full names (e.g. `patriots`, `49ers`).

The schedule text is extracted from the full text content: find the first occurrence of `\nYEAR=`, take everything from that point onward. When saving, splice it back at that position.

### 10.2 Three Tabs

1. **Weekly Grid**
2. **Team Matrix**
3. **Integrity**

#### 10.2.1 Weekly Grid Tab

**Week picker** (top): A wrapping row of chip buttons labeled W1–W17. The selected week chip is highlighted. Clicking a chip switches to that week.

**Week heading row**: `Week N  ·  M games` (title style) + (right-aligned) an "Add Game" button (only shown when the week has fewer than 16 games).

**Game grid**: Responsive grid. Columns: `floor(panelWidth / 290)`, min 1, max 4. Child aspect ratio ~3:1. Gap: 8px.

Each **game card**:
- Background: themed card color, border-radius 8px
- Content: row with [Away team box] + [@] + [Home team box]
- Away box: team abbreviation (20px, 900 weight, amber `#F59E0B`) + "AWAY" label (9px, amber 70%)
- Home box: team abbreviation (emerald `#10B981`) + "HOME" label (9px, emerald 70%)
- Clicking either team box opens the Team Picker Dialog (§14.4)
- Top-right corner: × close button (14px icon, danger color 70%) removes the game from the week

**Adding a game**: Pre-fills with the first two unused teams for that week.

**Editing** is done in-memory; changes are serialized via `ScheduleData.toLines()` and spliced into the main text content immediately.

#### 10.2.2 Team Matrix Tab

A fixed-layout table: rows = 32 NFL teams (sorted by abbreviation via `kTeamNamesSorted`), columns = W1–W17 + team name.

Column widths distributed proportionally: team name column = 1.6 units, each week column = 1 unit. Use the container width to calculate unit size.

Row height: 22px. Header row height: 26px.

Each cell shows the opponent abbreviation:
- Away game: amber `#F59E0B`, bold, 9px
- Home game: emerald `#10B981`, bold, 9px
- Bye week (no game): `·` in dim color

Entire table scrolls vertically. Horizontally it fills the container.

#### 10.2.3 Integrity Tab

A scrollable list of check results. Each row is a colored status card.

Checks performed (in order):
1. **Week count**: 17 weeks required. Shows `N/17 weeks in schedule`.
2. **Games per week**: No week may exceed 16 games.
3. **Games per team**: Every team must appear exactly 16 times total. Lists offenders as `ABR=N`. Uses `ScheduleData.gameCountByTeam`.
4. **No team twice in same week**: Uses `ScheduleData.duplicatesByWeek`.

Pass card: green background (emerald at 10% opacity), green border, check-circle icon.
Fail card: red background (red at 10% opacity), red border, error-outline icon.

Header: "Schedule Integrity" title (left) + "N/M checks passed" (right, small text).

---

## 11. Coach Editor Screen

**Status:** Placeholder — not yet implemented.

Show a centered placeholder:
- Graduation cap icon (48px, `--color-muted`)
- Title: "Coach Editor" (16px, 500 weight, `--color-muted`)
- Subtitle: "Edit coach attributes and staff" (12px, `--color-muted`)

---

## 12. Text Editor Screen

Layout: two columns — Advanced Sidebar (left, collapsible) + Editor Column (right).

### 12.1 Advanced Sidebar

Collapsed: 24px wide strip with a right-chevron icon. Clicking expands it.

Expanded: 180px default width (resizable by dragging the right edge, range 120–400px).

**Header row** (36px, border-bottom): label "ADVANCED" (11px uppercase, bold, `--color-muted`) + left-chevron collapse button (right-aligned).

**Buttons** (below header, 8px horizontal padding, 2px vertical padding each):
Each button is a full-width bordered button (border-radius 4px, 6px vertical / 8px horizontal padding, 12px text):
- Reset Key — enabled only when file loaded
- Apply to Save — enabled only when file loaded
- List Contents — enabled only when file loaded
- Clear — always enabled
- Auto Fix Skin/Face — enabled only when file loaded

Disabled buttons: 40% opacity on both text and border.

**Button actions** (all call through `AppState` which delegates to `nfl2k5tool_dart`):
- **Apply to Save**: calls `InputParser(tool).ProcessText(currentText)`, shows feedback modal (§14.5)
- **List Contents**: calls `appState.buildTextContent()`, replaces editor text
- **Reset Key**: calls `InputParser(tool).ProcessText('Key=')`
- **Auto Fix Skin/Face**: calls `InputParser(tool).ProcessText('AutoFixSkinFromPhoto')`
- **Clear**: sets editor text to empty string

### 12.2 Editor Column

Top-to-bottom:

1. **Toolbar** (36px, `--color-chip` background, border-bottom):
   Three toolbar buttons: Find, Wrap (toggle), Syntax (toggle).

   - Find: shows "Find" when no matches, "Find  N/M" when matches exist. Keyboard shortcut: Ctrl+F.
   - Wrap: toggles word-wrap. Label "Wrap: On" / "Wrap: Off".
   - Syntax: toggles syntax highlighting. Label "Syntax: On" / "Syntax: Off".

   Active toggle button: `--color-active-bg` background, `--color-gold` icon and text.

2. **Editor area** (fills remaining height):
   - Line number gutter: 48px wide, slightly darker chip bg, right-aligned monospace line numbers in `--color-muted` 11px
   - Main textarea: monospace 13px, line height 20px, with syntax highlighting
   - If word-wrap off: horizontal scroll with a separate 12px-tall scrollbar at the bottom (synchronized)
   - If word-wrap on: no horizontal scroll

3. **Editor status bar** (24px, `--color-chip` background, border-top):
   `Ln N, Col M   X lines   Y chars` + optional `  •  N/M matches` when searching. Monospace 11px, `--color-muted`.

### 12.3 Syntax Highlighting

For each line, apply the following coloring rules (implemented in Dart, applied via DOM span injection or a canvas overlay):

- **Line 0** (column header row — starts with `#` before being stripped): italic, `--syntax-header`
- **Team separator** (line starts with `Team =` or `Team=`): bold, `--syntax-team`
- **Player data row** (all other non-empty lines after the header):
  - Field 0 (up to first comma): `--syntax-position`
  - Comma after field 0: `--syntax-comma`
  - Fields 1–2 (first name + last name, between first and third comma): `--syntax-name`
  - Remainder of line: `--syntax-base`
- **Empty/other lines**: `--syntax-base`

Search matches: matched ranges get a background fill (`--syntax-hit` for inactive, `--syntax-active` for the current match).

**Performance:** For large files (5000+ lines), only the visible viewport ± 60 lines should be fully syntax-colored. Lines outside that range can be rendered as plain text.

### 12.4 Search

- Ctrl+F: opens a search input dialog
- F3: next match
- Shift+F3: previous match
- All matches highlighted simultaneously; active match scrolled into view
- Match count shown in toolbar: "N/M"

### 12.5 Apply-to-Save Feedback Modal

A modal dialog (420×300px usable area):
- Title: "Apply to Save — Output" with a close button
- Body: scrollable `<pre>` showing the result string (or "(No output)" if empty)
- Buttons: "Copy to Clipboard" + "Close"

---

## 13. Options Screen

A scrollable column (20px padding) of section cards.

### 13.1 Section Card

- Background: `--color-surface`, border-radius 8px, border 1px `--color-border`
- Header: title in `--color-gold` (13px, 600 weight) + subtitle in `--color-muted` (11px)
- Divider after header, then toggle rows

### 13.2 Toggle Row

Each option is a row with a label (13px, `--color-text`) and a CSS toggle switch (right-aligned). Toggle on: thumb in `--color-gold`.

### 13.3 Section: "Text View"

Subtitle: "Controls which sections appear in the text editor. Changing these options will regenerate the text view from the loaded file."

Options and defaults (matching `AppOptions` defaults in `app_options.dart`):

| Option | Default | Field |
|---|---|---|
| Show Players | on | showPlayers |
| Show Schedule | on | showSchedule |
| Show Appearance | on | showAppearance |
| Show Attributes | on | showAttributes |
| Show Special Teams | off | showSpecialTeams |
| Show Free Agents | off | showFreeAgents |
| Show Draft Class | off | showDraftClass |
| Show Coaches | off | showCoaches |

When a "Show" option changes and a file is loaded, show a confirmation dialog:
Title: "Regenerate text view?"
Body: "Changing Show options will regenerate the text view from the loaded file. Any unsaved edits in the Text tab will be lost."
Buttons: Cancel, Regenerate

### 13.4 Section: "Auto Update"

Subtitle: "Applied on Save/Export. The tool will run the selected bulk operations after writing player data."

| Option | Default | Field |
|---|---|---|
| Auto Update Depth Charts | on | autoUpdateDepthCharts |
| Auto Update Photos | off | autoUpdatePhotos |
| Auto Update PBP | on | autoUpdatePBP |

Auto-update options append text tags to the main text content:
- `autoUpdateDepthCharts` → append `\nAutoUpdateDepthChart`
- `autoUpdatePhotos` → append `\nAutoUpdatePhoto`
- `autoUpdatePBP` → append `\nAutoUpdatePBP`

These tags are stripped and re-added whenever the options change.

### 13.5 Persistence

Use `AppOptions` from `lib/data/app_options.dart` — **adapted version** that replaces `SharedPreferences` with `window.localStorage` (from `package:web`):

```dart
// Instead of SharedPreferences:
import 'package:web/web.dart' show window;

static AppOptions load() {
  final s = window.localStorage;
  return AppOptions(
    showPlayers: s.getItem('showPlayers') != 'false',
    // ...etc
  );
}

void save() {
  final s = window.localStorage;
  s.setItem('showPlayers', showPlayers.toString());
  // ...etc
}
```

---

## 14. Dialogs and Modals

All dialogs use a dark backdrop (rgba(0,0,0,0.5)), centered modal box with `--color-surface` background, 10px border-radius. ESC key closes all dialogs.

### 14.1 Face Picker Dialog

Opens when clicking the Photo Box in the player header, or the Photo mappedId card.

**Size:** 80vw × 80vh, max 900px × 700px.

**Layout (top to bottom):**

1. **Header row** (border-bottom):
   - Search icon + "Select Face Photo" title (14px, 600 weight)
   - Close button (×)

2. **Controls row** (padding 10px):
   - Category dropdown: "All Categories", then the keys from `PlayerDataCache.faceCategories`
   - "Show IDs" toggle checkbox — when on, each thumbnail shows its numeric ID overlaid

3. **Thumbnail grid** (fills remaining height, scrollable):
   - 10 columns, auto rows
   - Each cell: JPEG thumbnail (square, object-fit cover) + optional ID overlay
   - Currently selected photo: highlighted border in `--color-gold`
   - Clicking a thumbnail returns its 4-digit zero-padded ID string (e.g. `"0004"`, `"2569"`)
   - On open: auto-scrolls to the currently selected photo

Photos are loaded via `PlayerDataCache.getPhoto(id)`. IDs are zero-padded to 4 digits internally: `id.toString().padLeft(4, '0') + '.jpg'`.

**Return value:** 4-digit padded ID string. The CSV `Photo` field stores the plain integer as a string (e.g. `"2569"`). The face picker returns `"2569"` (not `"02569"`).

### 14.2 PBP (Announcer) Picker Dialog

Opens when clicking the PBP mappedId card.

**Size:** 420×520px.

**Layout:**
1. Header: search icon + "Select PBP Name" + close button
2. Search field (autofocused): "Search by name or ID…"
3. Result count: "N entries" (10px, muted)
4. Scrollable list: each row 48px tall, shows name (left) + ID (right, 10px muted). Selected row: `--color-active-bg` background, `--color-gold` text.
5. On open: auto-scrolls to current selection.

Options are the `pbpOptions` list from `lib/data/player_mappings.dart` (see §15.4).

### 14.3 Export Format Picker Dialog

Opens when "Export Save" is clicked (no native save dialog in a browser).

A simple dialog listing format options as clickable rows:

- Xbox Zip (.zip)
- Raw DAT (.dat)
- PS2 Max (.max)
- PS2 PSU (.psu)
- PS2 Card (.ps2)
- Xbox MU (.bin)

Clicking a row calls the appropriate export function and triggers a browser download.

### 14.4 Team Picker Dialog (Schedule)

Opens when clicking a team box in a schedule game card.

**Size:** 320px wide, auto height.

Title: "Select Team"

Body: a 4-column grid of team buttons (from `kTeamNamesSorted`), each showing the abbreviation (12px, bold). Currently selected team: `--color-gold` background, black text. Others: `--color-chip` background.

Footer: Cancel button.

### 14.5 Apply-to-Save Feedback Modal

See §12.5.

---

## 15. Data Layer — Dart Files

### 15.1 Dart Data Files to Implement

Create these files in `lib/data/`. Each is described fully in this specification — no external source is required.

| File | Described in |
|---|---|
| `lib/data/text_parser.dart` | §15.3 — CSV parser, ParseResult, teamsToText |
| `lib/data/schedule_data.dart` | §10.3, §15.7 — schedule model, parser, serialiser, team table |
| `lib/data/player.dart` | §15.4 — Player and Team models |
| `lib/data/attr_groups.dart` | §9.4 — AttrDef, AttrType, AttrGroup, kAttrGroups, kHeightOptions |
| `lib/data/player_mappings.dart` | §15.5 — photo and PBP lookup tables |
| `lib/data/app_options.dart` | §13.3–13.5 — options model, localStorage persistence |
| `lib/data/player_data_cache.dart` | §16 — ZIP-based photo cache using package:archive |

### 15.2 Player and Team Models (player.dart)

```dart
/// A single player. [data] keys match the CSV column headers exactly.
class Player {
  final Map<String, String> data;
  const Player(this.data);

  String get position     => data['Position']    ?? '';
  String get firstName    => data['fname']        ?? '';
  String get lastName     => data['lname']        ?? '';
  String get jerseyNumber => data['JerseyNumber'] ?? '';
  String get fullName     => '$firstName $lastName'.trim();
  String get yearsPro     => data['YearsPro']     ?? '';
  String get hand         => data['Hand']         ?? '';
  String get weight       => data['Weight']       ?? '';
  String get height       => data['Height']       ?? '';
  int?   get photoId      => int.tryParse(data['Photo'] ?? '');

  String get(String key) => data[key] ?? '';
  int?   getInt(String key) => int.tryParse(data[key] ?? '');
}

/// A team with a named roster.
class Team {
  final String name;
  final List<Player> players;
  const Team({required this.name, required this.players});
}
```

### 15.3 CSV Parser (text_parser.dart)

The parser in `text_parser.dart` provides:
- `ParseResult` — holds `keySection` (string), `headers` (List\<String\>), `teams` (List\<Team\>)
- `parseTeamsFromText(String text)` → `ParseResult`
- `teamsToText(ParseResult result)` → `String`

**Critical parsing rules** (already implemented — do not change):
- `splitCsv`: a `"` is only treated as an opening quote at the very start of a field. A `"` mid-field (e.g. the inch mark in `6'0"`) is kept as a literal character. Inside a quoted field, `""` is an escaped double-quote.
- `quoteCsvField`: only re-quotes fields containing commas or newlines — NOT bare `"` — so height values like `6'0"` round-trip cleanly without added quotes.

### 15.4 Player Mappings (player_mappings.dart)

This file provides two lookup lists used by the Face Picker and PBP Picker dialogs:

```dart
class MappedEntry {
  final String id;    // numeric ID as string
  final String name;  // display name
  const MappedEntry(this.id, this.name);
}

// Full lists are sourced from the nfl2k5tool_dart package data.
// The implementing agent should check whether nfl2k5tool_dart exposes
// these lists directly (e.g. via a static getter or bundled JSON asset).
// If not, populate them from the PlayerData.zip FaceFormCategories.json
// for photos, and from whatever PBP index the package provides.
List<MappedEntry> photoOptions = [...];  // photo ID → player name
List<MappedEntry> pbpOptions   = [...];  // PBP ID  → announcer pronunciation label

String photoIdToDisplayName(String id) =>
    photoOptions.firstWhere((e) => e.id == id, orElse: () => MappedEntry(id, '')).name;

String pbpIdToDisplayName(String id) =>
    pbpOptions.firstWhere((e) => e.id == id, orElse: () => MappedEntry(id, '')).name;
```

### 15.6 nfl2k5tool_dart Integration

Because this is a Dart project, `nfl2k5tool_dart` is a **direct pub dependency** — no compilation bridge, no JS interop, no wrapper code needed.

```dart
import 'package:nfl2k5tool_dart/nfl2k5tool_dart.dart';

// Load a file
final session = SaveSession.fromXboxZip(bytes);    // or fromPs2Save, fromRawDat, etc.
final tool    = session.engine;                     // GamesaveTool

// Extract text content
final text = tool.GetLeaguePlayers(showAttributes, showAppearance, showSpecialTeams);

// Apply edits back
InputParser(tool).ProcessText(editedText);

// Export
final outBytes = session.exportToXboxZip();        // or exportToPs2Max, etc.
```

**File type routing** (by extension, case-insensitive):

| Extension | Loader |
|---|---|
| `.zip` | `SaveSession.fromXboxZip(bytes)` |
| `.dat` | `SaveSession.fromRawDat(bytes)` |
| `.max` | `SaveSession.fromPs2Save(bytes)` |
| `.psu` | `SaveSession.fromPs2Save(bytes)` |
| `.ps2` | `SaveSession.fromPs2Card(bytes)` |
| `.bin`, `.img` | `SaveSession.fromXboxMU(bytes)` |

**Export routing:**

| Extension | Method |
|---|---|
| `.zip` | `session.exportToXboxZip()` |
| `.dat` | `tool.GameSaveData!` |
| `.max` | `session.exportToPs2Max()` |
| `.psu` | `session.exportToPs2Psu()` |
| `.ps2` | `session.injectIntoPs2Card()` |
| `.bin`, `.img` | `session.injectIntoXboxMU()` |

### 15.7 Schedule Data Model (schedule_data.dart)

```dart
class ScheduleGame {
  final String away;  // lowercase team name, e.g. 'patriots'
  final String home;
  const ScheduleGame({required this.away, required this.home});
  ScheduleGame copyWith({String? away, String? home}) =>
      ScheduleGame(away: away ?? this.away, home: home ?? this.home);
}

class ScheduleWeek {
  final int number;
  final List<ScheduleGame> games;
  const ScheduleWeek({required this.number, required this.games});
}

class ScheduleData {
  final int year;
  final List<ScheduleWeek> weeks;
  const ScheduleData({required this.year, required this.weeks});

  static ScheduleData parse(String text) { /* see §10.1 format */ }
  List<String> toLines() { /* YEAR=N, WEEK N [N games], "away at home" lines */ }
  Map<String, int> get gameCountByTeam { /* team name → total games */ }
  List<Set<String>> get duplicatesByWeek { /* per week, teams appearing >1 time */ }

  // Immutable edit helpers
  ScheduleData withGame(int weekIdx, int gameIdx, ScheduleGame g);
  ScheduleData withGameRemoved(int weekIdx, int gameIdx);
  ScheduleData withGameAdded(int weekIdx, ScheduleGame g);
}

// Team abbreviation table (32 NFL teams, 2004 rosters)
const Map<String, String> kTeamAbbr = {
  'cardinals':'ARI', 'falcons':'ATL', 'ravens':'BAL', 'bills':'BUF',
  'panthers':'CAR', 'bears':'CHI', 'bengals':'CIN', 'browns':'CLE',
  'cowboys':'DAL', 'broncos':'DEN', 'lions':'DET', 'packers':'GB',
  'texans':'HOU', 'colts':'IND', 'jaguars':'JAX', 'chiefs':'KC',
  'dolphins':'MIA', 'vikings':'MIN', 'patriots':'NE', 'saints':'NO',
  'giants':'NYG', 'jets':'NYJ', 'raiders':'OAK', 'eagles':'PHI',
  'steelers':'PIT', 'chargers':'SD', 'seahawks':'SEA', '49ers':'SF',
  'rams':'STL', 'buccaneers':'TB', 'titans':'TEN', 'redskins':'WAS',
};

final List<String> kTeamNamesSorted = (kTeamAbbr.entries.toList()
  ..sort((a, b) => a.value.compareTo(b.value))).map((e) => e.key).toList();

String teamAbbr(String name) =>
    kTeamAbbr[name.toLowerCase()] ?? name.toUpperCase();
```

### 15.8 Text Content Construction

Implement in `AppState` as follows:

```dart
String buildTextContent(GamesaveTool tool, AppOptions opts) {
  final buf = StringBuffer();
  if (opts.showPlayers || opts.showFreeAgents || opts.showDraftClass) {
    buf.write(tool.GetKey(opts.showAttributes, opts.showAppearance));
    buf.write('\n');
  }
  buf.write('\n# Uncomment line below to Set Salary Cap -> 198.2M\n');
  buf.write('# SET(0x9ACCC, 0x38060300)\n\n');
  if (opts.showPlayers)    buf.write(tool.GetLeaguePlayers(opts.showAttributes, opts.showAppearance, opts.showSpecialTeams));
  if (opts.showFreeAgents) buf.write(tool.GetTeamPlayers('FreeAgents', opts.showAttributes, opts.showAppearance, false));
  if (opts.showDraftClass) buf.write(tool.GetTeamPlayers('DraftClass', opts.showAttributes, opts.showAppearance, false));
  if (opts.showCoaches)    buf.write(tool.GetCoachDataAll());
  if (opts.showSchedule && tool.saveType == SaveType.Franchise) {
    buf.write('\n\n#Schedule\n');
    buf.write(tool.GetSchedule());
  }
  if (opts.autoUpdateDepthCharts) buf.write('\nAutoUpdateDepthChart');
  if (opts.autoUpdatePhotos)      buf.write('\nAutoUpdatePhoto');
  if (opts.autoUpdatePBP)         buf.write('\nAutoUpdatePBP');
  return buf.toString();
}
```

### 15.9 Schedule Text Extraction

```dart
String? get scheduleText {
  const marker = '\nYEAR=';
  final pos = textContent.indexOf(marker);
  return pos >= 0 ? textContent.substring(pos + 1) : null;
}

void updateScheduleInText(String scheduleText) {
  const marker = '\nYEAR=';
  final pos = textContent.indexOf(marker);
  final playerSection = pos >= 0 ? textContent.substring(0, pos) : textContent;
  textContent = '$playerSection\n$scheduleText';
}
```

---

## 16. Photo System

### 16.1 PlayerData.zip

A ZIP archive served as a static asset at `web/assets/PlayerData.zip`. Contains:
- `PlayerData/0001.jpg` through `PlayerData/NNNN.jpg` — JPEG player face photos
- `PlayerData/FaceFormCategories.json` — category index

### 16.2 PlayerDataCache (adapted)

Implement `player_data_cache.dart` using `package:archive` for ZIP extraction and `package:web` for fetching the asset. The initialization fetches `assets/PlayerData.zip` at runtime:

```dart
import 'package:archive/archive.dart';
import 'package:web/web.dart' show window, Response;
import 'dart:js_interop';
import 'dart:typed_data';

static Future<void> _ensureIndex() async {
  if (_index != null) return;
  final response = await window.fetch('assets/PlayerData.zip'.toJS).toDart as Response;
  final buffer   = await response.arrayBuffer().toDart;
  final bytes    = Uint8List.view(buffer.toDart);
  final arc = ZipDecoder().decodeBytes(bytes);
  // ... rest follows the same pattern as described in §16
}
```

All other methods (`getPhoto`, `allPhotoIds`, `faceCategories`, `photoIdsForCategory`) remain identical.

Photo thumbnails in the Face Picker are displayed by creating `<img>` elements with `src = URL.createObjectURL(Blob([bytes]))`. Object URLs are cached and revoked when the dialog closes.

---

## 17. Global Application State

All mutable state is owned by a single `AppState` class in `lib/app_state.dart`. Screens hold a reference to this object and call `render()` / update DOM directly when state changes (or use a simple listener pattern).

```dart
class AppState {
  // File state
  SaveSession? session;
  GamesaveTool? tool;
  String textContent = '';
  String? fileName;
  String? fileType;      // 'FRANCHISE' | 'ROSTER' | null
  int teamCount  = 0;
  int playerCount = 0;
  String? statusMessage;

  // UI state
  NavSection activeSection = NavSection.players;
  bool railCollapsed = false;
  String themeMode = 'dark';   // 'dark' | 'light'

  // Options
  AppOptions options = AppOptions();

  bool get hasFile    => tool != null;
  bool get isFranchise => fileType == 'FRANCHISE';
  String? get scheduleText { /* see §15.6 */ }

  // Notifies all registered listeners to re-render
  final _listeners = <void Function()>[];
  void addListener(void Function() fn) => _listeners.add(fn);
  void notify() { for (final fn in _listeners) fn(); }
}
```

When the user navigates away from the Player Editor: serialize in-memory team/player data back to text via `teamsToText(parseResult)` and update `appState.textContent` before rendering the new section.

---

## 18. File I/O (package:web)

### 18.1 Opening a File

```dart
import 'package:web/web.dart';
import 'dart:js_interop';

void openFile() {
  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = '.ps2,.zip,.dat,.max,.psu,.bin,.img';
  input.onchange = (Event _) async {
    final file = input.files?.item(0);
    if (file == null) return;
    final buffer = await file.arrayBuffer().toDart;
    final bytes  = Uint8List.view(buffer.toDart);
    _loadBytes(bytes, file.name);
  }.toJS;
  input.click();
}
```

### 18.2 Downloading a File

```dart
void downloadBytes(Uint8List bytes, String filename) {
  final blob = Blob([bytes.toJS].toJS);
  final url  = URL.createObjectURL(blob);
  final a    = HTMLAnchorElement()
    ..href     = url
    ..download = filename;
  document.body!.append(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}
```

---

## 19. CSS Document Organization

`web/app.css` must have clearly labeled section comments:

```css
/* ═══════════════════════════════════════════════════════
   Section 1: CSS Custom Properties (Color Tokens)
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 2: Reset and Base Styles
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 3: Shell Layout (CSS Grid)
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 4: Top Bar
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 5: Navigation Rail
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 6: Status Bar
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 7: Player Editor (list panel + attr panel)
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 8: Schedule Editor (weekly grid, matrix, integrity)
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 9: Text Editor (sidebar, gutter, toolbar, status)
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 10: Options Screen
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 11: Dialogs and Modals
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 12: Shared Components
   (buttons, chips, badges, inputs, toggle switches,
    dividers, section labels, placeholder screens)
   ═══════════════════════════════════════════════════════ */

/* ═══════════════════════════════════════════════════════
   Section 13: Light Theme Overrides [data-theme="light"]
   ═══════════════════════════════════════════════════════ */
```
