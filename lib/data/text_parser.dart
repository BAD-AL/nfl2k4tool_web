library;

/// Text parser utilities for NFL2K5Tool web app.
///
/// All functions treat [appState.textContent] as the source of truth.
/// They either read the text for display (transient results, never stored),
/// or return a *new* String with a targeted in-place edit applied.

// ─── Key parsing ──────────────────────────────────────────────────────────────

/// Parses the active column schema from [text].
///
/// The Key is the `#` header line — the first line that starts with `#`
/// immediately followed by a letter (no space).  Examples:
///   `#Position,fname,lname,JerseyNumber,...`   ← Key line
///   `# Uncomment line below...`                ← comment (space after #, ignored)
///   `#Key=Position,fname,...`                  ← alternate Key= prefix form
///
/// Returns the ordered list of column names, or an empty list if not found.
List<String> parseActiveColumns(String text) {
  for (final line in text.split('\n')) {
    final t = line.trim();
    // Key line: # immediately followed by a letter (no space)
    if (t.startsWith('#') && t.length > 1 && t[1] != ' ') {
      var keyLine = t.substring(1); // strip leading #
      // Strip optional Key= prefix (case-insensitive)
      if (keyLine.toLowerCase().startsWith('key=')) keyLine = keyLine.substring(4);
      // Trailing comma is normal — filter empty segments
      return splitCsv(keyLine).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
  }
  return [];
}

// ─── Delimiter detection ──────────────────────────────────────────────────────

/// Detects the field delimiter used in [text] — either `,` (comma) or `;` (semicolon).
/// Mirrors the logic in `InputParser.ProcessText`: whichever appears more wins.
/// Defaults to `,` if counts are equal or both are zero.
String detectDelimiter(String text) {
  int commas = 0, semis = 0;
  for (final ch in text.runes) {
    if (ch == 0x2C) commas++;
    if (ch == 0x3B) semis++;
  }
  return semis > commas ? ';' : ',';
}

// ─── CSV split / quote ────────────────────────────────────────────────────────

/// Splits a CSV [line] into fields using [delim] (default `,`).
///
/// Rules (critical for this file format):
/// - A `"` only opens a quoted field when it appears at the very start of a field.
/// - A `"` mid-field (e.g. the inch mark in `6'0"`) is treated as a literal character.
/// - Inside a quoted field, `""` is an escaped double-quote.
List<String> splitCsv(String line, [String delim = ',']) {
  final fields = <String>[];
  final buf = StringBuffer();
  bool inQuotes = false;
  bool fieldStart = true;

  for (int i = 0; i < line.length; i++) {
    final ch = line[i];

    if (inQuotes) {
      if (ch == '"') {
        // Peek ahead: "" inside quotes = escaped quote
        if (i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buf.write(ch);
      }
    } else {
      if (ch == delim) {
        fields.add(buf.toString());
        buf.clear();
        fieldStart = true;
      } else if (ch == '"' && fieldStart) {
        // Opening quote only valid at the start of a field
        inQuotes = true;
        fieldStart = false;
      } else {
        buf.write(ch);
        fieldStart = false;
      }
    }
  }
  fields.add(buf.toString()); // last field (may be empty trailing comma)
  return fields;
}

/// Re-quotes [field] for CSV output.
///
/// Only adds surrounding quotes when the field contains a comma or newline.
/// A bare `"` (inch mark in height values like `6'0"`) is NOT requoted.
String quoteCsvField(String field) {
  if (field.contains(',') || field.contains('\n')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}

// ─── Display-only parse (transient) ──────────────────────────────────────────

/// A transient display record for a single player row.
class PlayerRow {
  final int lineIndex;          // line number in textContent (0-based)
  final Map<String, String> fields; // column → value, keyed by header name
  const PlayerRow({required this.lineIndex, required this.fields});

  String get position    => fields['Position']    ?? '';
  String get firstName   => fields['fname']        ?? '';
  String get lastName    => fields['lname']        ?? '';
  String get fullName    => '$firstName $lastName'.trim();
  String get jerseyNumber=> fields['JerseyNumber'] ?? '';
  String get yearsPro    => fields['YearsPro']     ?? '';
}

/// A transient display record for a team block.
class TeamBlock {
  final String name;
  final List<PlayerRow> players;
  const TeamBlock({required this.name, required this.players});
}

/// Parses [text] into team blocks for display in the Player List.
/// Returns a transient list — never store this as the source of truth.
///
/// The format expected:
///   Team = Cardinals
///   # fname,lname,JerseyNumber,...
///   QB,Tom,Brady,...
///   ...
///   Team = Bears
///   ...
List<TeamBlock> parseTeamBlocksForDisplay(String text) {
  final delim = detectDelimiter(text);
  final lines = text.split('\n');
  final teams = <TeamBlock>[];

  String? currentTeam;
  List<String> headers = [];
  final players = <PlayerRow>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Team separator — format: "Team = 49ers    Players:53"
    final teamMatch = RegExp(r'^Team\s*=\s*(.+)$', caseSensitive: false).firstMatch(trimmed);
    if (teamMatch != null) {
      if (currentTeam != null && players.isNotEmpty) {
        teams.add(TeamBlock(name: currentTeam, players: List.unmodifiable(players)));
        players.clear();
      }
      // Strip trailing "Players:N" annotation if present
      var rawName = teamMatch.group(1)!.trim();
      rawName = rawName.replaceFirst(RegExp(r'\s+Players:\d+\s*$', caseSensitive: false), '').trim();
      currentTeam = rawName;
      // Do NOT reset headers — the global # key line applies to all team blocks.
      continue;
    }

    // Column header row: # immediately followed by a letter (not a space = not a comment).
    // This appears globally (before any Team block) and is reused for all teams.
    if (trimmed.startsWith('#') && trimmed.length > 1 && trimmed[1] != ' ') {
      var headerLine = trimmed.substring(1);
      if (headerLine.toLowerCase().startsWith('key=')) headerLine = headerLine.substring(4);
      headers = splitCsv(headerLine, delim).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      continue;
    }

    // Player data row — only inside a team block, with headers available
    if (currentTeam != null && headers.isNotEmpty && trimmed.isNotEmpty &&
        !trimmed.startsWith('//') && !trimmed.startsWith('SET(') &&
        !trimmed.startsWith('YEAR=') && !trimmed.startsWith('WEEK')) {
      final vals = splitCsv(trimmed, delim);
      final fieldMap = <String, String>{};
      for (int j = 0; j < headers.length && j < vals.length; j++) {
        fieldMap[headers[j]] = vals[j];
      }
      players.add(PlayerRow(lineIndex: i, fields: fieldMap));
    }
  }
  if (currentTeam != null && players.isNotEmpty) {
    teams.add(TeamBlock(name: currentTeam, players: List.unmodifiable(players)));
  }

  return teams;
}

/// Returns all unique college names found in the player data of [text].
/// Used to populate the College autocomplete dropdown.
List<String> parseCollegeNames(String text) {
  final seen = <String>{};
  for (final block in parseTeamBlocksForDisplay(text)) {
    for (final p in block.players) {
      final c = p.fields['College'] ?? '';
      if (c.isNotEmpty) seen.add(c);
    }
  }
  return seen.toList()..sort();
}

// ─── In-place field editing ───────────────────────────────────────────────────

/// Returns a new text string with the field [columnKey] on line [lineIndex]
/// replaced with [newValue].
///
/// [headers] is the ordered column list for that team block (from parseActiveColumns
/// or from the `#` header row above the player block).
/// [delim] should be the delimiter detected from the full text via [detectDelimiter].
///
/// Uses splitCsv + quoteCsvField for a safe roundtrip that preserves all other fields.
/// Returns [text] unchanged if [lineIndex] is out of range or [columnKey] not found.
String setFieldInLine(
    String text, int lineIndex, String columnKey, String newValue, List<String> headers,
    [String delim = ',']) {
  final lines = text.split('\n');
  if (lineIndex < 0 || lineIndex >= lines.length) return text;

  final colIdx = headers.indexOf(columnKey);
  if (colIdx < 0) return text;

  final fields = splitCsv(lines[lineIndex], delim);
  if (colIdx >= fields.length) return text;

  fields[colIdx] = newValue;
  lines[lineIndex] = fields.map(quoteCsvField).join(delim);
  return lines.join('\n');
}

/// Swaps two player lines in [text] (for depth-chart reordering).
/// Returns the updated text, or [text] unchanged if either index is invalid.
String swapLines(String text, int lineIndexA, int lineIndexB) {
  final lines = text.split('\n');
  if (lineIndexA < 0 || lineIndexA >= lines.length) return text;
  if (lineIndexB < 0 || lineIndexB >= lines.length) return text;
  final tmp = lines[lineIndexA];
  lines[lineIndexA] = lines[lineIndexB];
  lines[lineIndexB] = tmp;
  return lines.join('\n');
}

// ─── Status bar helpers ───────────────────────────────────────────────────────

/// Counts teams and total players in [text] for the status bar.
/// Returns `(teamCount, playerCount)`.
(int, int) countTeamsAndPlayers(String text) {
  int teams = 0;
  int players = 0;
  bool inTeam = false;
  bool hasSeenHeader = false; // global # header seen anywhere in text

  for (final line in text.split('\n')) {
    final t = line.trim();
    // Schedule section starts — no more player data
    if (t.startsWith('YEAR=')) break;
    // Global key/header line: # immediately followed by a letter
    if (t.startsWith('#') && t.length > 1 && t[1] != ' ') {
      hasSeenHeader = true;
      continue;
    }
    if (RegExp(r'^Team\s*=', caseSensitive: false).hasMatch(t)) {
      teams++;
      inTeam = true;
      continue;
    }
    if (inTeam && hasSeenHeader && t.isNotEmpty &&
        !t.startsWith('//') && !t.startsWith('SET(') &&
        !t.startsWith('WEEK')) {
      players++;
    }
  }
  return (teams, players);
}
