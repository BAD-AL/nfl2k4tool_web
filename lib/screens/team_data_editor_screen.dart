import 'dart:js_interop';
import 'package:web/web.dart';
import 'package:nfl2k4tool_dart/nfl2k4tool_dart.dart' show kTeamNames, kPlaybookNames;

import '../app_state.dart';
import '../data/text_parser.dart';

// ─── Team abbreviation map (full name → 2-3 letter abbrev) ───────────────────

const _kTeamAbbrevs = {
  '49ers':      'SF',  'Bears':     'CHI', 'Bengals':   'CIN', 'Bills':     'BUF',
  'Broncos':    'DEN', 'Browns':    'CLE', 'Buccaneers':'TB',  'Cardinals': 'ARI',
  'Chargers':   'SD',  'Chiefs':    'KC',  'Colts':     'IND', 'Cowboys':   'DAL',
  'Dolphins':   'MIA', 'Eagles':    'PHI', 'Falcons':   'ATL', 'Giants':    'NYG',
  'Jaguars':    'JAX', 'Jets':      'NYJ', 'Lions':     'DET', 'Packers':   'GB',
  'Panthers':   'CAR', 'Patriots':  'NE',  'Raiders':   'OAK', 'Rams':      'STL',
  'Ravens':     'BAL', 'Redskins':  'WAS', 'Saints':    'NO',  'Seahawks':  'SEA',
  'Steelers':   'PIT', 'Texans':    'HOU', 'Titans':    'TEN', 'Vikings':   'MIN',
};

// ─── XSS escape ───────────────────────────────────────────────────────────────

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ─── TeamDataEditorScreen ─────────────────────────────────────────────────────


class TeamDataEditorScreen {
  final AppState _appState;
  final HTMLElement _container;

  List<String>      _headers = [];
  List<TeamDataRow> _teams   = [];
  int _lastTextHash  = 0;
  int _selectedIdx   = -1;

  TeamDataEditorScreen(AppState appState)
      : _appState = appState,
        _container = document.getElementById('screen-teamData') as HTMLElement;

  // ─── Public entry point ───────────────────────────────────────────────────

  void render() {
    if (!_appState.hasFile) {
      _container.innerHTML = '''
<div class="placeholder-screen">
  <span class="material-symbols-outlined">shield</span>
  <h2>Team Data Editor</h2>
  <p>Open a gamesave file to edit team data.</p>
</div>'''.toJS;
      _resetState();
      return;
    }

    final hash = _appState.textContent.hashCode;
    if (hash != _lastTextHash) {
      _lastTextHash = hash;
      final parsed = parseTeamDataLines(_appState.textContent);
      _headers = parsed.headers;
      _teams   = parsed.teams;
      _selectedIdx = -1;
    }

    if (_teams.isEmpty) {
      _container.innerHTML = '''
<div class="placeholder-screen">
  <span class="material-symbols-outlined">shield</span>
  <h2>Team Data Editor</h2>
  <p>No team data found in the current text.</p>
  <p style="font-size:13px;color:var(--color-text-secondary);">
    Enable <b>Show Team Data</b> in <b>Options</b> to include team data.
  </p>
</div>'''.toJS;
      return;
    }

    _renderFull();
  }

  // ─── Full DOM build ───────────────────────────────────────────────────────

  void _renderFull() {
    final isFranchise = _appState.isFranchise;
    _container.innerHTML = '''
<div class="player-editor">
  <div class="section-header${isFranchise ? ' section-header--pct' : ''}">
    <div class="section-header-row">
      <span class="material-symbols-outlined section-icon">shield</span>
      <span class="section-title">Team Data Editor</span>
      <span class="section-subtitle">${_teams.length} teams</span>
    </div>
    ${isFranchise ? _buildPctHtml() : ''}
  </div>
  <div class="player-editor-body">
    <div class="player-list-panel" id="tde-list-panel">
      ${_buildListHtml()}
    </div>
    <div class="player-attr-panel" id="tde-detail-panel">
      ${_buildDetailHtml()}
    </div>
  </div>
</div>'''.toJS;

    _attachListeners();
  }

  String _buildPctHtml() {
    final tool = _appState.tool;
    if (tool == null) return '';
    
    bool allChecked = true;
    for (int i = 0; i < 32; i++) {
      if (!tool.isTeamPlayerControlled(i)) {
        allChecked = false;
        break;
      }
    }
    
    final btnLabel   = allChecked ? 'Uncheck All' : 'Check All';
    final buf = StringBuffer();
    buf.write('<div class="pct-row">'
        '<span class="pct-label">Player Controlled:</span>'
        '<button id="tde-pct-toggle" class="pct-btn">$btnLabel</button>'
        '<div class="pct-checkboxes">');
    for (int i = 0; i < 32; i++) {
      final team = kTeamNames[i];
      final abbrev = _kTeamAbbrevs[team] ?? team.substring(0, 3).toUpperCase();
      final checked = tool.isTeamPlayerControlled(i) ? ' checked' : '';
      buf.write('<label class="pct-cb" title="${_esc(team)}">'
          '<input type="checkbox" class="pct-check" data-idx="$i"$checked>'
          '<span>${_esc(abbrev)}</span></label>');
    }
    buf.write('</div></div>');
    return buf.toString();
  }

  // ─── List panel ───────────────────────────────────────────────────────────

  String _buildListHtml() {
    final buf = StringBuffer();
    buf.write('<div class="player-list">');
    for (int i = 0; i < _teams.length; i++) {
      final t = _teams[i];
      final sel = i == _selectedIdx ? ' selected' : '';
      buf.write('''
<div class="player-row$sel" data-idx="$i">
  <div class="player-row-info">
    <div class="player-row-name">${_esc(t.nickname.isEmpty ? t.team : t.nickname)}</div>
    <div class="player-row-meta">${_esc(t.abbrev)} · ${_esc(t.city)}</div>
  </div>
</div>''');
    }
    buf.write('</div>');
    return buf.toString();
  }

  // ─── Detail panel ─────────────────────────────────────────────────────────

  String _buildDetailHtml() {
    if (_selectedIdx < 0) {
      return '''
<div class="player-attr-placeholder">
  <span class="material-symbols-outlined">shield</span>
  <h3>Select a team</h3>
  <p>Choose a team from the list to edit its data.</p>
</div>''';
    }

    final t       = _teams[_selectedIdx];

    // Playbook dropdown
    final pbOpts = kPlaybookNames.map((p) {
      final sel = p == t.playbook ? ' selected' : '';
      return '<option value="${_esc(p)}"$sel>${_esc(p)}</option>';
    }).join();

    return '''
<div style="padding:12px;overflow-y:auto;height:100%;box-sizing:border-box;">
  <div style="font-size:16px;font-weight:600;margin-bottom:12px;color:var(--color-text);">
    ${_esc(t.nickname.isEmpty ? t.team : t.nickname)}
    <span style="font-size:12px;font-weight:400;color:var(--color-muted);margin-left:8px;">${_esc(t.team)}</span>
  </div>

  <div class="attr-grid" id="tde-fields">

    <!-- ── Fixed-length text fields ── -->
    <div style="width:100%;flex-basis:100%;">
      <div style="font-size:11px;color:var(--color-muted);font-style:italic;margin-bottom:8px;">
        &#x24D8;&nbsp;Nickname, Abbreviation, City, and Alt&nbsp;Abbrev are fixed-length fields
        &mdash; each cannot exceed the character count of the original value.
      </div>
      <div style="display:flex;flex-wrap:wrap;gap:8px;">
        ${_textField('Nickname',  'Nickname',      t.nickname)}
        ${_textField('Abbrev',    'Abbreviation',  t.abbrev)}
        ${_textField('City',      'City',          t.city)}
        ${_textField('AbbrAlt',   'Alt Abbrev',    t.abbrAlt)}
      </div>
    </div>

    <!-- ── Dropdown fields — natural-width cards on one row ── -->
    <div class="attr-card dropdown-field" data-key="Playbook">
      <div class="attr-card-label">Playbook</div>
      <select class="pes-dropdown tde-dropdown" data-key="Playbook">$pbOpts</select>
    </div>

  </div>
</div>''';
  }

  String _textField(String key, String label, String value) => '''
<div class="attr-card text-field" data-key="${_esc(key)}">
  <div class="attr-card-label">${_esc(label)}</div>
  <input type="text" class="pes-text-input tde-text-input" data-key="${_esc(key)}"
    value="${_esc(value)}">
</div>''';

  // ─── Event wiring ─────────────────────────────────────────────────────────

  void _attachListeners() {
    // Player controlled checkboxes + toggle button (franchise only)
    if (_appState.isFranchise) {
      final header = _container.querySelector('.section-header') as HTMLElement?;
      header?.addEventListener('change', (Event e) {
        final target = e.target as HTMLElement?;
        if (target == null || !target.classList.contains('pct-check')) return;
        final idx = int.tryParse(target.dataset['idx']) ?? -1;
        if (idx < 0) return;
        _togglePlayerControlled(idx, (target as HTMLInputElement).checked);
      }.toJS);

      (_container.querySelector('#tde-pct-toggle') as HTMLButtonElement?)
          ?.addEventListener('click', (Event _) {
        final tool = _appState.tool;
        if (tool == null) return;
        
        bool allChecked = true;
        for (int i = 0; i < 32; i++) {
          if (!tool.isTeamPlayerControlled(i)) {
            allChecked = false;
            break;
          }
        }
        
        for (int i = 0; i < 32; i++) {
          tool.setTeamPlayerControlled(i, !allChecked);
        }
        _updatePlayerControlledInText();
      }.toJS);
    }

    // List selection
    final listPanel = _container.querySelector('#tde-list-panel') as HTMLElement?;
    listPanel?.addEventListener('click', (Event e) {
      final row = (e.target as HTMLElement?)?.closest('.player-row') as HTMLElement?;
      if (row == null) return;
      final idx = int.tryParse(row.dataset['idx']) ?? -1;
      if (idx >= 0 && idx < _teams.length) _selectTeam(idx);
    }.toJS);

    _attachDetailListeners();
  }

  void _togglePlayerControlled(int teamIdx, bool value) {
    final tool = _appState.tool;
    if (tool == null) return;
    tool.setTeamPlayerControlled(teamIdx, value);
    _updatePlayerControlledInText();
  }

  void _updatePlayerControlledInText() {
    final tool = _appState.tool;
    if (tool == null) return;
    
    // For 2K4, we'll just re-generate the TeamData section in textContent
    // because playercontrolled is now a column there.
    _appState.textContent = _appState.buildTextContent(tool, _appState.options);
    
    // Keep hash in sync so the re-render doesn't reset team selection
    _lastTextHash = _appState.textContent.hashCode;
    _appState.notify();
  }

  void _attachDetailListeners() {
    final detail = _container.querySelector('#tde-detail-panel') as HTMLElement?;
    if (detail == null) return;

    // Text input blur
    detail.addEventListener('blur', (Event e) {
      final target = e.target as HTMLElement?;
      if (target == null || !target.classList.contains('tde-text-input')) return;
      final key = (target as HTMLInputElement).dataset['key'];
      _writeField(key, target.value);
    }.toJS);

    // Team data dropdowns
    detail.addEventListener('change', (Event e) {
      final target = e.target as HTMLElement?;
      if (target == null || !target.classList.contains('tde-dropdown')) return;
      _writeField(target.dataset['key'], (target as HTMLSelectElement).value);
    }.toJS);
  }

  // ─── Selection ────────────────────────────────────────────────────────────

  void _selectTeam(int idx) {
    final rows = _container.querySelectorAll('.player-row');
    for (var i = 0; i < rows.length; i++) {
      (rows.item(i) as HTMLElement?)?.classList.remove('selected');
    }
    _container.querySelector('.player-row[data-idx="$idx"]')?.classList.add('selected');
    _selectedIdx = idx;
    _rebuildDetail();
  }

  void _rebuildDetail() {
    final detail = _container.querySelector('#tde-detail-panel') as HTMLElement?;
    if (detail == null) return;
    detail.innerHTML = _buildDetailHtml().toJS;
    _attachDetailListeners();
  }

  // ─── Field write ──────────────────────────────────────────────────────────

  void _writeField(String key, String value) {
    if (_selectedIdx < 0 || _selectedIdx >= _teams.length) return;
    final team = _teams[_selectedIdx];
    _appState.textContent = setFieldInLine(
        _appState.textContent,
        team.lineIndex,
        key,
        value,
        _headers,
        detectDelimiter(_appState.textContent));
    _lastTextHash = _appState.textContent.hashCode;
    // Re-parse to keep row data in sync
    final parsed = parseTeamDataLines(_appState.textContent);
    _headers = parsed.headers;
    _teams   = parsed.teams;
    // Update list item label if nickname/abbrev/city changed
    if (key == 'Nickname' || key == 'Abbrev' || key == 'City') {
      _updateListItem(_selectedIdx);
    }
  }

  void _updateListItem(int idx) {
    if (idx < 0 || idx >= _teams.length) return;
    final t = _teams[idx];
    final row = _container.querySelector('.player-row[data-idx="$idx"]') as HTMLElement?;
    if (row == null) return;
    final nameEl = row.querySelector('.player-row-name') as HTMLElement?;
    if (nameEl != null) nameEl.textContent = t.nickname.isEmpty ? t.team : t.nickname;
    final metaEl = row.querySelector('.player-row-meta') as HTMLElement?;
    if (metaEl != null) metaEl.textContent = '${t.abbrev} · ${t.city}';
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _resetState() {
    _headers     = [];
    _teams       = [];
    _lastTextHash = 0;
    _selectedIdx = -1;
  }
}
