# NFL2K5Tool Web App — Test Plan

**Version:** 1.0
**Scope:** All functional and visual requirements in `Requirements.md`

---

## Testing Strategy

Tests are grouped by component. Each test has:
- **ID** — unique reference
- **Description** — what is being verified
- **Precondition** — state required before testing
- **Steps** — numbered actions
- **Expected result** — what must be true to pass

Tests marked **[AUTO]** are candidates for automated testing (Playwright/Puppeteer). All others are manual.

**Test files needed:**
- `test_franchise.zip` — a valid Xbox Zip franchise gamesave (provides schedule data)
- `test_roster.max` — a valid PS2 Max roster-only gamesave
- `test_invalid.txt` — a plain text file with wrong content

---

## 1. Shell Layout

### T-SHELL-01 — Full viewport coverage [AUTO]
**Precondition:** App loaded in browser.
**Steps:** Check that the body fills 100% of the viewport with no scrollbar visible.
**Expected:** `document.body.scrollHeight === window.innerHeight`. No horizontal scrollbar.

### T-SHELL-02 — Grid row heights
**Steps:** Measure top bar, content area, and status bar heights.
**Expected:** Top bar = 42px, status bar = 24px, content area = viewport height − 66px.

### T-SHELL-03 — No section scrolls the document
**Steps:** Load a large file. Scroll within the player list. Scroll within the text editor.
**Expected:** The page (document) does not scroll. Only the internal panels scroll.

---

## 2. Theme

### T-THEME-01 — Default theme is dark [AUTO]
**Steps:** Open app without any localStorage entry set.
**Expected:** `html` element has no `data-theme` attribute (or `data-theme="dark"`). Background matches `#0D1117`.

### T-THEME-02 — Theme toggle switches to light [AUTO]
**Steps:** Click the sun/moon icon button in the top bar.
**Expected:** `html[data-theme="light"]`. Background changes to `#F6F8FA`. Button tooltip reads "Switch to Dark mode".

### T-THEME-03 — Theme preference is persisted [AUTO]
**Steps:** Switch to light mode. Reload the page.
**Expected:** App opens in light mode.

### T-THEME-04 — All color tokens update on theme change
**Steps:** Switch themes. Inspect the nav rail, status bar, attribute cards, and text editor.
**Expected:** All surfaces, borders, and text colors match the correct palette for the current theme. The status bar always remains `#1A6B3C` regardless of theme.

---

## 3. Top Bar

### T-TOP-01 — Logo text colors
**Steps:** Inspect the logo text.
**Expected:** "NFL" is `#C9A227` (gold). "2K5 Tool" is `--color-text`.

### T-TOP-02 — Save button disabled by default [AUTO]
**Steps:** Open app without loading a file.
**Expected:** Save button appears at 50% opacity and is not clickable.

### T-TOP-03 — Export button disabled by default [AUTO]
**Steps:** Open app without loading a file.
**Expected:** Export button appears at 50% opacity and is not clickable.

### T-TOP-04 — File badge appears after load
**Steps:** Load `test_roster.max`.
**Expected:** A chip badge appears showing "ROSTER" (gold, bold) and the filename (muted).

### T-TOP-05 — File type badge for franchise
**Steps:** Load `test_franchise.zip`.
**Expected:** Badge shows "FRANCHISE" (gold) and the filename.

### T-TOP-06 — Export button enables after load
**Steps:** Load any valid file.
**Expected:** Export button is fully opaque and clickable.

---

## 4. Navigation Rail

### T-NAV-01 — Rail width in expanded state
**Steps:** Open app. Measure rail width.
**Expected:** 220px ± 1px.

### T-NAV-02 — Rail collapses to 46px [AUTO]
**Steps:** Click the collapse toggle at the bottom of the rail.
**Expected:** Rail animates to 46px width. Item labels disappear. Only icons remain.

### T-NAV-03 — Tooltip on hover when collapsed
**Steps:** Collapse the rail. Hover over the Players nav item.
**Expected:** Tooltip appears with text "Players".

### T-NAV-04 — Schedule item disabled for roster files
**Steps:** Load `test_roster.max`. Inspect the Schedule nav item.
**Expected:** Schedule item is 35% opacity. Clicking it does nothing (or tooltip shows "Schedule (Franchise only)").

### T-NAV-05 — Schedule item enabled for franchise files
**Steps:** Load `test_franchise.zip`. Click the Schedule nav item.
**Expected:** Schedule item is fully opaque. Clicking navigates to the Schedule screen.

### T-NAV-06 — Active item styling
**Steps:** Click "Text Editor" in the nav rail.
**Expected:** Text Editor item has `--color-active-bg` background, 2px left border in `--color-gold`, and gold icon/text. All other items are muted.

### T-NAV-07 — Section label hidden when collapsed
**Steps:** Collapse the rail.
**Expected:** "EDITORS" label is not visible (opacity 0 or display none).

---

## 5. Status Bar

### T-STATUS-01 — Color is always turf green
**Steps:** Check in both dark and light themes.
**Expected:** Background is `#1A6B3C` in both themes.

### T-STATUS-02 — "No File Loaded" state [AUTO]
**Steps:** Open app without loading a file.
**Expected:** White semi-transparent dot + "No File Loaded" text. No separator or counts.

### T-STATUS-03 — File loaded state
**Steps:** Load `test_roster.max`.
**Expected:** Green dot + "ROSTER File Loaded" + separator + "N Teams · M Players" (where N and M are actual counts from the file).

### T-STATUS-04 — Transient message replaces counts
**Steps:** Trigger an export. Check status bar.
**Expected:** Transient message (e.g. "Downloaded: filename.max") replaces the team/player count text temporarily.

---

## 6. File Operations

### T-FILE-01 — Open dialog accepts correct extensions
**Steps:** Click "Open File". Check the file picker.
**Expected:** Filter shows: `.ps2, .zip, .dat, .max, .psu, .bin, .img`.

### T-FILE-02 — Loading an Xbox Zip franchise file
**Steps:** Load `test_franchise.zip`.
**Expected:** No error. File badge shows "FRANCHISE". Player editor is populated. Schedule nav item is enabled.

### T-FILE-03 — Loading a PS2 Max roster file
**Steps:** Load `test_roster.max`.
**Expected:** No error. File badge shows "ROSTER". Player editor is populated. Schedule nav item is disabled.

### T-FILE-04 — Error handling for unsupported file
**Steps:** Rename a text file to `test.xyz`. Attempt to load it via the file picker (if filter allows it).
**Expected:** Status bar shows an error message. No crash. App remains usable.

### T-FILE-05 — Export triggers download
**Steps:** Load a valid file. Click "Export Save". Select a format.
**Expected:** Browser downloads a file with the correct extension. No error.

### T-FILE-06 — Export format picker shows all formats
**Steps:** Load a file. Click "Export Save".
**Expected:** Dialog appears with 6 format options: Xbox Zip (.zip), Raw DAT (.dat), PS2 Max (.max), PS2 PSU (.psu), PS2 Card (.ps2), Xbox MU (.bin).

---

## 7. Player Editor

### T-PLAY-01 — "No file loaded" state
**Steps:** Open Players section without loading a file.
**Expected:** List panel is empty (or shows placeholder). Attribute panel shows "Select a player" placeholder.

### T-PLAY-02 — Team dropdown is populated
**Steps:** Load `test_roster.max`. Navigate to Players.
**Expected:** Team dropdown lists all teams present in the file (typically 32 NFL teams + FreeAgents/DraftClass if present).

### T-PLAY-03 — Selecting a team loads its players
**Steps:** Select a different team from the dropdown.
**Expected:** Player list updates to show that team's roster. First filtered player is auto-selected. Section header updates to show new team name and player count.

### T-PLAY-04 — Selecting a player loads their attributes
**Steps:** Click a player in the list.
**Expected:** Player attribute panel updates. Header shows player's name, position, jersey number, team, years pro, handedness, height/weight.

### T-PLAY-05 — Position filter "QB" [AUTO]
**Steps:** Select filter chip "QB".
**Expected:** List shows only players whose CSV Position field is "QB". Other positions are hidden.

### T-PLAY-06 — Position filter "OL" [AUTO]
**Steps:** Select filter chip "OL".
**Expected:** List shows only players with Position in {G, T, C}.

### T-PLAY-07 — Position filter "DB" [AUTO]
**Steps:** Select filter chip "DB".
**Expected:** List shows only players with Position in {CB, FS, SS}.

### T-PLAY-08 — Search filters by name
**Steps:** Type "Tom" in the search field.
**Expected:** List shows only players whose full name contains "Tom" (case-insensitive).

### T-PLAY-09 — Search filters by position
**Steps:** Type "QB" in the search field.
**Expected:** List shows players whose position string contains "QB".

### T-PLAY-10 — Player list collapse
**Steps:** Click the "Collapse" toggle at the bottom of the player list.
**Expected:** List panel shrinks to 48px. Only position badges are visible. Tooltips work on hover.

### T-PLAY-11 — Photo box shows image
**Steps:** Load a file. Select a player that has a non-zero Photo ID.
**Expected:** Photo box shows the JPEG thumbnail from PlayerData.zip.

### T-PLAY-12 — Photo box hover overlay
**Steps:** Hover over the photo box.
**Expected:** Dark overlay with a camera icon appears. Cursor changes to pointer.

### T-PLAY-13 — Clicking photo box opens Face Picker
**Steps:** Click the photo box.
**Expected:** Face Picker Dialog opens with the current photo pre-selected / scrolled into view.

### T-PLAY-14 — Attribute tabs navigation
**Steps:** Click each of the 5 tabs (Athletic, Skills, Mental, Appearance, Identity).
**Expected:** Each click shows the correct set of attribute cards. Active tab has gold underline.

### T-PLAY-15 — Numeric field: value updates on keyboard
**Steps:** Click into a Speed field. Press ArrowUp 3 times.
**Expected:** Value increases by 3 (clamped at 99).

### T-PLAY-16 — Numeric field: value clamped at 0
**Steps:** Set a numeric field to 0. Press ArrowDown.
**Expected:** Value stays at 0.

### T-PLAY-17 — Numeric field bar drag
**Steps:** Drag the bar below a numeric field from left to right.
**Expected:** Value changes proportionally. Bar fill width updates in real time.

### T-PLAY-18 — Numeric field left-half click decrements
**Steps:** Set a value to 50. Click the left half of the numeric attr card (not the input itself).
**Expected:** Value changes to 49.

### T-PLAY-19 — Numeric field right-half click increments
**Steps:** Set a value to 50. Click the right half of the card.
**Expected:** Value changes to 51.

### T-PLAY-20 — Dropdown field saves selection
**Steps:** Change the "Run Style" dropdown to "Power". Switch to another player and back.
**Expected:** "Power" is still selected.

### T-PLAY-21 — Slider: step buttons work
**Steps:** In Identity tab, click the − button on the Weight slider.
**Expected:** Weight decreases by 1, clamped at 100.

### T-PLAY-22 — Slider: dragging updates value
**Steps:** Drag the Weight slider thumb to the right.
**Expected:** Value increases toward 400.

### T-PLAY-23 — Date picker opens and sets value
**Steps:** Click the DOB field. Select a date in the date picker.
**Expected:** DOB field shows the selected date in M/D/YYYY format.

### T-PLAY-24 — College autocomplete shows suggestions
**Steps:** Click the College field. Type "al".
**Expected:** Dropdown shows colleges containing "al" (case-insensitive), max 8 entries.

### T-PLAY-25 — Selecting autocomplete suggestion fills field
**Steps:** Type "Alabama" in college. Click "Alabama" in the suggestions.
**Expected:** Field shows "Alabama". Suggestion list closes.

### T-PLAY-26 — Player reorder arrows visible on selected row
**Steps:** Select any player that is not first or last in the filtered list.
**Expected:** Up and Down arrow buttons are visible on that row.

### T-PLAY-27 — Reorder moves player in list
**Steps:** Note the player above the selected player. Click the Up arrow.
**Expected:** Selected player swaps position with the one above. The selection stays on the same player.

### T-PLAY-28 — Edits persist when switching players
**Steps:** Select Player A. Change Speed to 99. Select Player B. Select Player A again.
**Expected:** Speed is still 99.

### T-PLAY-29 — Edits persist when switching teams
**Steps:** Select a player on Team A. Change Speed to 99. Switch to Team B. Switch back to Team A and select the same player.
**Expected:** Speed is still 99.

### T-PLAY-30 — Photo picker returns correct ID
**Steps:** Open Face Picker. Select a photo thumbnail. Confirm.
**Expected:** Photo box in the player header updates. The CSV `Photo` field shows the plain integer ID (not zero-padded). E.g., selecting photo `0123.jpg` stores `"123"` in the data.

---

## 8. Face Picker Dialog

### T-FACE-01 — Dialog opens with correct current photo highlighted
**Steps:** Open a player with Photo ID 2569. Open the Face Picker.
**Expected:** The thumbnail for photo 2569 has a gold border. The viewport is scrolled so it's visible.

### T-FACE-02 — 10-column grid layout
**Steps:** Count the columns in the thumbnail grid.
**Expected:** Exactly 10 columns.

### T-FACE-03 — Category filter
**Steps:** Open Face Picker. Select category "darkPlayers" from the dropdown.
**Expected:** Only thumbnails from that category are shown.

### T-FACE-04 — Show IDs toggle
**Steps:** Check the "Show IDs" checkbox.
**Expected:** Each thumbnail now shows its numeric ID overlaid.

### T-FACE-05 — Selecting a thumbnail closes dialog and returns ID
**Steps:** Click any thumbnail.
**Expected:** Dialog closes. The selected player's Photo attribute is updated. The photo box shows the new image.

### T-FACE-06 — ESC closes dialog without changes
**Steps:** Open Face Picker. Press Escape.
**Expected:** Dialog closes. Photo attribute is unchanged.

---

## 9. Schedule Editor

### T-SCHED-01 — Disabled state for roster files
**Steps:** Load `test_roster.max`. Navigate to Schedule.
**Expected:** Placeholder message: "Not available — open a Franchise file to edit the schedule". No schedule content visible.

### T-SCHED-02 — Weekly Grid tab loads for franchise
**Steps:** Load `test_franchise.zip`. Navigate to Schedule.
**Expected:** Weekly Grid tab is active. Week picker shows W1–W17 (or however many weeks are in the file). Games are displayed in the grid.

### T-SCHED-03 — Week navigation
**Steps:** Click "W5" in the week picker.
**Expected:** Grid updates to show Week 5 games. W5 chip is highlighted.

### T-SCHED-04 — Game card displays correct teams
**Steps:** Inspect a game card.
**Expected:** Away team shows its 2–3 letter abbreviation in amber `#F59E0B`. Home team in emerald `#10B981`. "@" separator between them.

### T-SCHED-05 — Clicking team box opens Team Picker
**Steps:** Click the away team box in a game card.
**Expected:** Team Picker Dialog opens with the current away team highlighted.

### T-SCHED-06 — Team picker dialog — selecting a team updates the game
**Steps:** In the Team Picker, click a different team.
**Expected:** Dialog closes. The game card now shows the new team abbreviation.

### T-SCHED-07 — Remove game button
**Steps:** Click the × button on a game card.
**Expected:** That game is removed from the week. The heading count decreases by 1.

### T-SCHED-08 — Add Game button available when week < 16 games
**Steps:** Remove games from a week until it has fewer than 16. Check for the "Add Game" button.
**Expected:** "Add Game" button is visible in the week heading row.

### T-SCHED-09 — Add Game creates a valid game
**Steps:** Click "Add Game".
**Expected:** A new game card appears with two valid team names (no duplicates for that week).

### T-SCHED-10 — Add Game button absent when week has 16 games
**Steps:** Find or create a week with exactly 16 games.
**Expected:** "Add Game" button is not visible.

### T-SCHED-11 — Team Matrix tab shows 32 teams
**Steps:** Click "Team Matrix" tab.
**Expected:** Exactly 32 team rows are visible, sorted by abbreviation (ARI, ATL, BAL, ...).

### T-SCHED-12 — Team Matrix away vs home colors
**Steps:** Inspect cells in the matrix.
**Expected:** Away games (team is away) show opponent in amber. Home games show opponent in emerald.

### T-SCHED-13 — Integrity tab — all checks pass for valid schedule
**Steps:** Load a valid franchise file with a complete schedule. Click "Integrity" tab.
**Expected:** All check items show green (check icon). "N/N checks passed" header.

### T-SCHED-14 — Integrity tab — flags wrong week count
**Steps:** Remove an entire week's games from the schedule. Check Integrity.
**Expected:** The week count check shows red with the actual count.

### T-SCHED-15 — Schedule changes propagate to text content
**Steps:** Edit a game. Navigate to Text Editor. Search for the original team name.
**Expected:** The original team name is no longer in that game's line. The new team name is present.

---

## 10. Text Editor

### T-TEXT-01 — Editor loads file content
**Steps:** Load any valid file. Navigate to Text Editor.
**Expected:** Editor textarea is populated with the CSV text content. Line numbers are visible in the gutter.

### T-TEXT-02 — Line numbers are correct [AUTO]
**Steps:** Count visible line numbers.
**Expected:** Line numbers start at 1 and increment correctly.

### T-TEXT-03 — Word wrap toggle
**Steps:** Click "Wrap: Off". Then click "Wrap: On".
**Expected:** Off: long lines extend horizontally with a scrollbar. On: lines wrap within the viewport.

### T-TEXT-04 — Syntax highlighting toggle
**Steps:** Click "Syntax: Off".
**Expected:** All text appears in the base color. No colored fields.

### T-TEXT-05 — Syntax highlighting: team lines are gold and bold
**Steps:** Enable syntax. Find a "Team = X" line in the editor.
**Expected:** That line is rendered in `--syntax-team` color (`#C9A227` in dark mode) and bold.

### T-TEXT-06 — Syntax highlighting: position field is green
**Steps:** Enable syntax. Find a player data row.
**Expected:** The first comma-delimited field (position code like QB, CB, etc.) is rendered in `--syntax-position` color (`#3FB950` in dark mode).

### T-TEXT-07 — Ctrl+F opens search [AUTO]
**Steps:** Press Ctrl+F in the text editor.
**Expected:** A search dialog or inline search bar appears.

### T-TEXT-08 — Search finds matches [AUTO]
**Steps:** Search for a player's last name.
**Expected:** Toolbar shows "1/N" or similar match count. The first match is scrolled into view and highlighted.

### T-TEXT-09 — F3 navigates to next match
**Steps:** After searching, press F3.
**Expected:** The next match becomes active. Match counter increments.

### T-TEXT-10 — Shift+F3 navigates to previous match
**Steps:** With multiple matches active, press Shift+F3.
**Expected:** The previous match becomes active.

### T-TEXT-11 — Active match highlighted distinctly
**Steps:** Search for a common word with multiple matches.
**Expected:** The active match has a brighter highlight than inactive matches.

### T-TEXT-12 — Editor status bar shows cursor position
**Steps:** Click on line 5 of the editor text.
**Expected:** Status bar shows "Ln 5, Col N" for the cursor position.

### T-TEXT-13 — Editor status bar shows line and char count [AUTO]
**Steps:** Open the text editor with content loaded.
**Expected:** Status bar shows "X lines   Y chars".

### T-TEXT-14 — Advanced sidebar is collapsed by default
**Steps:** Navigate to Text Editor.
**Expected:** Advanced sidebar is a 24px strip on the left with a right-chevron.

### T-TEXT-15 — Advanced sidebar expands on click
**Steps:** Click the collapsed sidebar strip.
**Expected:** Sidebar expands to 180px. "Advanced" label and buttons are visible.

### T-TEXT-16 — Advanced sidebar buttons disabled without file [AUTO]
**Steps:** Open Text Editor without loading a file.
**Expected:** Reset Key, Apply to Save, List Contents, Auto Fix Skin/Face buttons are at 40% opacity and not clickable. Clear is fully opaque.

### T-TEXT-17 — Clear button empties the editor
**Steps:** Load a file. Navigate to Text Editor. Click "Clear".
**Expected:** Editor textarea is empty.

### T-TEXT-18 — Advanced sidebar resize drag
**Steps:** Drag the resize handle of the expanded sidebar to the right.
**Expected:** Sidebar width increases. Range is clamped between 120px and 400px.

---

## 11. Options Screen

### T-OPT-01 — Default option values on first load [AUTO]
**Steps:** Clear localStorage. Open Options screen.
**Expected:**
- Show Players: ON
- Show Schedule: ON
- Show Appearance: ON
- Show Attributes: ON
- Show Special Teams: OFF
- Show Free Agents: OFF
- Show Draft Class: OFF
- Show Coaches: OFF
- Auto Update Depth Charts: ON
- Auto Update Photos: OFF
- Auto Update PBP: ON

### T-OPT-02 — Toggle persists across reload [AUTO]
**Steps:** Toggle "Show Special Teams" to ON. Reload page.
**Expected:** "Show Special Teams" is still ON.

### T-OPT-03 — Changing Show option with file loaded shows confirmation
**Steps:** Load a file. Toggle "Show Players" off.
**Expected:** A confirmation dialog appears: "Regenerate text view? ... Any unsaved edits in the Text tab will be lost." with Cancel and Regenerate buttons.

### T-OPT-04 — Canceling regeneration keeps original text
**Steps:** Load a file. Toggle a Show option. Click Cancel.
**Expected:** Text content is unchanged. Option toggle reverts (the option is not changed).

### T-OPT-05 — Confirming regeneration updates text content
**Steps:** Load a file. Toggle "Show Coaches" ON. Confirm regeneration.
**Expected:** Text Editor now contains coach data that wasn't there before.

### T-OPT-06 — Auto Update option appends tag to text content
**Steps:** Load a file with "Auto Update Depth Charts" ON. Check the end of the text content.
**Expected:** Text contains `\nAutoUpdateDepthChart`.

### T-OPT-07 — Disabling Auto Update tag removes it
**Steps:** Load a file. Toggle "Auto Update Depth Charts" OFF.
**Expected:** `AutoUpdateDepthChart` is removed from the text content.

### T-OPT-08 — Section card gold title
**Steps:** Open Options screen. Inspect the "Text View" section card title.
**Expected:** Title text is rendered in `#C9A227` (gold).

---

## 12. CSV Parser (Unit Tests — parser.js)

These tests run the parser functions in isolation.

### T-PARSE-01 — Basic player row roundtrip [AUTO]
```javascript
const line = 'QB,Tom,Brady,12,65,77,80,75,60,60,98,87,82,75,55,45,72,72,72,72,60,Balanced,75,80,70,80,72,72,72,72,72,4,Normal,Skin5,Face3,No,Standard,FaceMask1,None,No,No,None,None,None,None,None,None,None,None,Shoe1,Shoe1,None,None,Right,6\'2",226,7/1/1977,3,Right,45,2569,1023,';
const fields = splitCsv(line);
// Expected: fields[0] === 'QB', fields[1] === 'Tom', fields[2] === 'Brady', fields[3] === '12'
```

### T-PARSE-02 — Height with inch mark is literal (not quote) [AUTO]
```javascript
const line = "QB,Tom,Brady,12,65,6'0\",226,";
const fields = splitCsv(line);
// Expected: fields[6] === "6'0\"" (not a parsing error)
```

### T-PARSE-03 — Quoted field with comma [AUTO]
```javascript
const line = '"Smith, Jr.",Tom,1,';
const fields = splitCsv(line);
// Expected: fields[0] === 'Smith, Jr.'
```

### T-PARSE-04 — quoteCsvField only quotes when comma present [AUTO]
```javascript
// Expected: quoteCsvField("6'0\"") === "6'0\""  (no quotes added)
// Expected: quoteCsvField("Smith, Jr.") === '"Smith, Jr."'
```

### T-PARSE-05 — parseTeamsFromText extracts correct team count [AUTO]
**Steps:** Parse the sample data file.
**Expected:** Result has the correct number of teams (matches the number of "Team =" lines).

### T-PARSE-06 — parseTeamsFromText preserves keySection [AUTO]
**Steps:** Parse text with a key section before the header.
**Expected:** `result.keySection` matches the exact lines before the `#` header.

### T-PARSE-07 — teamsToText roundtrip [AUTO]
**Steps:** Parse a known text. Serialize with teamsToText. Parse again.
**Expected:** Both parse results have identical team names, player counts, and all player field values.

---

## 13. Schedule Parser (Unit Tests — schedule-data.js)

### T-SCHED-PARSE-01 — Year extraction [AUTO]
```javascript
const text = 'YEAR=2004\n\nWEEK 1  [2 games]\ncolts at patriots\njaguars at bills\n';
const data = parseSchedule(text);
// Expected: data.year === 2004
```

### T-SCHED-PARSE-02 — Week and game parsing [AUTO]
```javascript
// Expected: data.weeks[0].number === 1
// Expected: data.weeks[0].games[0] === { away: 'colts', home: 'patriots' }
```

### T-SCHED-PARSE-03 — Serialization roundtrip [AUTO]
```javascript
const serialized = scheduleToText(data);
const reparsed = parseSchedule(serialized);
// Expected: reparsed.weeks.length === data.weeks.length
// Expected: all games match
```

---

## 14. Photo Cache (photo-cache.js)

### T-PHOTO-01 — Lazy init loads zip
**Steps:** Open Face Picker for the first time.
**Expected:** PlayerData.zip is fetched. No repeated network requests after the first load.

### T-PHOTO-02 — getPhoto returns bytes for known ID
**Steps:** Call `PhotoCache.getPhoto(2569)`.
**Expected:** Returns a non-null Uint8Array. The bytes are a valid JPEG (starts with `FF D8 FF`).

### T-PHOTO-03 — getPhoto returns null for unknown ID
**Steps:** Call `PhotoCache.getPhoto(99999)`.
**Expected:** Returns `null`.

### T-PHOTO-04 — allPhotoIds is sorted ascending [AUTO]
**Steps:** Access `PhotoCache.allPhotoIds`.
**Expected:** Array is sorted in ascending numeric order. First element is the lowest ID.

### T-PHOTO-05 — faceCategories has expected keys [AUTO]
**Steps:** Access `PhotoCache.faceCategories`.
**Expected:** Object has keys including "darkPlayers", "mediumPlayers", "lightPlayers", "Dreads", "darkBald", "lightBald".

### T-PHOTO-06 — photoIdsForCategory returns correct subset [AUTO]
**Steps:** Call `PhotoCache.photoIdsForCategory('darkPlayers')`.
**Expected:** Returns a non-empty array of IDs that is a proper subset of `allPhotoIds`.

### T-PHOTO-07 — ID zero-padding [AUTO]
**Steps:** Verify that photo ID `4` maps to file `0004.jpg` in the zip.
**Expected:** `PhotoCache.getPhoto(4)` returns bytes from `PlayerData/0004.jpg`.

---

## 15. Accessibility and UX

### T-UX-01 — All interactive elements have visible focus styles
**Steps:** Tab through the application using the keyboard.
**Expected:** Every focusable element shows a visible focus ring.

### T-UX-02 — Buttons have correct cursor
**Steps:** Hover over all buttons, nav items, and clickable cards.
**Expected:** Pointer cursor (`cursor: pointer`) on clickable elements. Default cursor on non-interactive areas.

### T-UX-03 — Keyboard navigation in dialogs
**Steps:** Open any dialog. Press Tab to cycle through its elements. Press Escape to close.
**Expected:** Tab stays within the dialog (focus trap). Escape closes without side effects.

### T-UX-04 — Responsive rail collapse
**Steps:** Set browser width to 1024px. Check the nav rail.
**Expected:** App is usable. Rail is still present and toggleable.

### T-UX-05 — Large file performance — player list scrolling
**Steps:** Load a roster with 1647 players. Scroll the player list quickly.
**Expected:** No visible jank. Scrolling is smooth.

### T-UX-06 — Large file performance — text editor scrolling
**Steps:** Load a large file (500+ lines in the text editor). Scroll rapidly.
**Expected:** No visible jank. Line numbers stay synchronized with the text.

---

## 16. Regression Checklist

After any significant change, verify:

- [ ] Loading both franchise and roster file types works
- [ ] Player edits survive team switch, position filter change, and page section switch
- [ ] Schedule edits appear in the Text Editor
- [ ] Options changes persist after page reload
- [ ] Dark and light themes both render correctly with no missing color tokens
- [ ] Face Picker dialog opens, shows photos, and returns the correct ID
- [ ] Export download works for at least one format
- [ ] CSS custom properties are applied (no `#XXXXXX` hardcoded values leaking into the UI outside of the palette definition)
