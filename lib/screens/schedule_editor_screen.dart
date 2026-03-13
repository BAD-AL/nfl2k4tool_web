import 'dart:js_interop';
import 'package:web/web.dart';
import '../app_state.dart';
import '../data/schedule_data.dart';

class ScheduleEditorScreen {
  final AppState appState;
  final HTMLElement _container;

  int _activeTab = 0; // 0=weekly, 1=matrix, 2=integrity
  int _activeWeek = 0; // 0-based index into schedule.weeks

  // Team picker state
  HTMLElement? _pickerOverlay;
  JSFunction? _pickerEscFn;

  ScheduleEditorScreen(this.appState)
      : _container =
            document.getElementById('screen-schedule') as HTMLElement;

  // ─── Entry point ──────────────────────────────────────────────────────────

  void render() {
    if (!appState.isFranchise) {
      _container.innerHTML = '''
<div class="placeholder-screen">
  <span class="material-symbols-outlined">calendar_month</span>
  <h2>Schedule Editor</h2>
  <p>Not available — open a Franchise file to edit the schedule.</p>
</div>'''.toJS;
      return;
    }

    // Already mounted — just refresh data in the active view.
    if (_container.querySelector('#sch-tabs') != null) {
      _refreshView();
      return;
    }

    // First render: build skeleton and wire persistent listeners.
    _container.innerHTML = _buildSkeletonHtml().toJS;
    _wireTabs();
    _refreshView();
  }

  // ─── Skeleton (section header + tab bar + content slot) ───────────────────

  String _buildSkeletonHtml() {
    final schedule = _getSchedule();
    final year = schedule?.year ?? 0;
    final subtitle = year > 0 ? 'Franchise · Season $year' : 'Franchise';
    return '''
<div class="section-header">
  <span class="material-symbols-outlined section-icon">calendar_month</span>
  <span class="section-title">Schedule Editor</span>
  <span class="section-subtitle">${_esc(subtitle)}</span>
</div>
<div class="sch-tab-bar" id="sch-tabs">
  <span class="sch-tab active" data-tab="0">Weekly Grid</span>
  <span class="sch-tab" data-tab="1">Team Matrix</span>
  <span class="sch-tab" data-tab="2">Integrity</span>
</div>
<div id="sch-content" class="sch-content"></div>
''';
  }

  void _wireTabs() {
    _container.querySelector('#sch-tabs')?.addEventListener('click', (Event e) {
      final tab =
          (e.target as HTMLElement?)?.closest('.sch-tab') as HTMLElement?;
      if (tab == null) return;
      final idx = int.tryParse(tab.dataset['tab']) ?? 0;
      if (idx == _activeTab) return;
      _activeTab = idx;
      final tabs = _container.querySelectorAll('.sch-tab');
      for (var i = 0; i < tabs.length; i++) {
        final t = tabs.item(i) as HTMLElement?;
        if (t == null) continue;
        final ti = int.tryParse(t.dataset['tab']) ?? -1;
        if (ti == _activeTab) { t.classList.add('active'); }
        else { t.classList.remove('active'); }
      }
      _refreshView();
    }.toJS);
  }

  // ─── View refresh (replaces only #sch-content) ────────────────────────────

  void _refreshView() {
    final content =
        _container.querySelector('#sch-content') as HTMLElement?;
    if (content == null) return;

    final schedule = _getSchedule();

    switch (_activeTab) {
      case 0:
        content.innerHTML = _buildWeeklyHtml(schedule).toJS;
        _wireWeekly(content);
      case 1:
        content.innerHTML = _buildMatrixHtml(schedule).toJS;
        _wireMatrix(content);
      case 2:
        content.innerHTML = _buildIntegrityHtml(schedule).toJS;
    }
  }

  ScheduleDisplay? _getSchedule() {
    final text = appState.scheduleText;
    if (text == null) return null;
    return parseScheduleForDisplay(text);
  }

  // ─── Weekly Grid ──────────────────────────────────────────────────────────

  String _buildWeeklyHtml(ScheduleDisplay? schedule) {
    if (schedule == null || schedule.weeks.isEmpty) {
      return '<p style="color:var(--color-muted);font-size:13px;">No schedule data found.</p>';
    }

    // Clamp active week to valid range
    if (_activeWeek >= schedule.weeks.length) _activeWeek = 0;

    final pills = StringBuffer();
    for (final w in schedule.weeks) {
      final active = (w.number - 1) == _activeWeek ? ' active' : '';
      pills.write(
          '<span class="sch-week-pill$active" data-week="${w.number - 1}">W${w.number}</span>');
    }

    final week = schedule.weeks[_activeWeek];
    final games = StringBuffer();
    for (int i = 0; i < week.games.length; i++) {
      final g = week.games[i];
      final awayAbbr = _esc(teamAbbr(g.away));
      final homeAbbr = _esc(teamAbbr(g.home));
      games.write('''
<div class="sch-game-card">
  <div class="sch-team-box" data-week="${week.number}" data-game="$i" data-side="away">
    <span class="sch-team-label">Away</span>
    <span class="sch-team-abbr away-color">$awayAbbr</span>
    <span class="sch-team-name">${_esc(g.away)}</span>
  </div>
  <div class="sch-vs">@</div>
  <div class="sch-team-box" data-week="${week.number}" data-game="$i" data-side="home">
    <span class="sch-team-label">Home</span>
    <span class="sch-team-abbr home-color">$homeAbbr</span>
    <span class="sch-team-name">${_esc(g.home)}</span>
  </div>
  <button class="sch-remove-btn" data-week="${week.number}" data-game="$i" title="Remove game">✕</button>
</div>''');
    }

    return '''
<div class="sch-week-pills">$pills</div>
<div class="sch-weekly-header">
  <span class="sch-week-label">Week ${week.number}</span>
  <button class="btn btn-outlined sch-add-btn" data-week="${week.number}">+ Add Game</button>
</div>
<div class="sch-game-grid">$games</div>
''';
  }

  void _wireWeekly(HTMLElement content) {
    // Week pill navigation
    content.querySelector('.sch-week-pills')
        ?.addEventListener('click', (Event e) {
      final pill =
          (e.target as HTMLElement?)?.closest('.sch-week-pill') as HTMLElement?;
      if (pill == null) return;
      _activeWeek = int.tryParse(pill.dataset['week']) ?? 0;
      _refreshView();
    }.toJS);

    // Game grid: team boxes + remove buttons
    content.querySelector('.sch-game-grid')
        ?.addEventListener('click', (Event e) {
      final target = e.target as HTMLElement?;

      // Remove button
      final rmBtn =
          target?.closest('.sch-remove-btn') as HTMLElement?;
      if (rmBtn != null) {
        final weekNum = int.tryParse(rmBtn.dataset['week']) ?? 0;
        final gameIdx = int.tryParse(rmBtn.dataset['game']) ?? 0;
        _applyScheduleEdit(
            removeGameFromText(appState.scheduleText ?? '', weekNum, gameIdx));
        return;
      }

      // Team box click — change that team
      final box =
          target?.closest('.sch-team-box') as HTMLElement?;
      if (box == null) return;
      final weekNum = int.tryParse(box.dataset['week']) ?? 0;
      final gameIdx = int.tryParse(box.dataset['game']) ?? 0;
      final side = box.dataset['side'];
      _openTeamPicker(
        title: side == 'away' ? 'Select Away Team' : 'Select Home Team',
        onPicked: (name) => _replaceTeam(weekNum, gameIdx, side, name),
      );
    }.toJS);

    // Add game button: 2-step picker (away → home)
    content.querySelector('.sch-add-btn')
        ?.addEventListener('click', (Event e) {
      final btn =
          (e.target as HTMLElement?)?.closest('.sch-add-btn') as HTMLElement?;
      final weekNum = int.tryParse(btn?.dataset['week'] ?? '') ?? 0;
      _openTeamPicker(
        title: 'Select Away Team',
        onPicked: (awayName) {
          _openTeamPicker(
            title: 'Select Home Team',
            onPicked: (homeName) {
              _applyScheduleEdit(addGameToText(
                  appState.scheduleText ?? '', weekNum, awayName, homeName));
            },
          );
        },
      );
    }.toJS);
  }

  // ─── Team Matrix ──────────────────────────────────────────────────────────

  String _buildMatrixHtml(ScheduleDisplay? schedule) {
    if (schedule == null || schedule.weeks.isEmpty) {
      return '<p style="color:var(--color-muted);font-size:13px;">No schedule data found.</p>';
    }

    final buf = StringBuffer();
    buf.write('<div class="sch-matrix-scroll"><table class="sch-matrix">');

    // Header row
    buf.write('<tr><th class="sch-matrix-team-col">Team</th>');
    for (final w in schedule.weeks) {
      buf.write('<th>W${w.number}</th>');
    }
    buf.write('</tr>');

    // One row per team (sorted by abbreviation)
    for (final teamName in kTeamNamesSorted) {
      final abbr = _esc(teamAbbr(teamName));
      buf.write('<tr><td class="sch-matrix-team-col">$abbr</td>');

      for (final week in schedule.weeks) {
        int gameIdx = -1;
        ScheduleGame? game;
        for (int i = 0; i < week.games.length; i++) {
          final g = week.games[i];
          if (g.away == teamName || g.home == teamName) {
            gameIdx = i;
            game = g;
            break;
          }
        }

        if (game == null) {
          buf.write(
              '<td class="sch-matrix-bye" data-week-idx="${week.number - 1}">BYE</td>');
        } else if (game.home == teamName) {
          final opp = _esc(teamAbbr(game.away));
          buf.write(
              '<td class="sch-matrix-home" data-week="${week.number}" data-game="$gameIdx" data-side="away">$opp</td>');
        } else {
          final opp = _esc(teamAbbr(game.home));
          buf.write(
              '<td class="sch-matrix-away" data-week="${week.number}" data-game="$gameIdx" data-side="home">@$opp</td>');
        }
      }
      buf.write('</tr>');
    }

    buf.write('</table></div>');
    return buf.toString();
  }

  void _wireMatrix(HTMLElement content) {
    content.querySelector('.sch-matrix-scroll')
        ?.addEventListener('click', (Event e) {
      final td =
          (e.target as HTMLElement?)?.closest('td') as HTMLElement?;
      if (td == null) return;

      // BYE → navigate to that week in Weekly Grid
      if (td.classList.contains('sch-matrix-bye')) {
        _activeWeek = int.tryParse(td.dataset['week-idx']) ?? 0;
        _activeTab = 0;
        final tabs = _container.querySelectorAll('.sch-tab');
        for (var i = 0; i < tabs.length; i++) {
          final t = tabs.item(i) as HTMLElement?;
          if (t == null) continue;
          final ti = int.tryParse(t.dataset['tab']) ?? -1;
          if (ti == 0) { t.classList.add('active'); }
          else { t.classList.remove('active'); }
        }
        _refreshView();
        return;
      }

      // Game cell → change that team
      if (td.classList.contains('sch-matrix-home') ||
          td.classList.contains('sch-matrix-away')) {
        final weekNum = int.tryParse(td.dataset['week']) ?? 0;
        final gameIdx = int.tryParse(td.dataset['game']) ?? 0;
        final side = td.dataset['side'];
        _openTeamPicker(
          title: side == 'away' ? 'Select Away Team' : 'Select Home Team',
          onPicked: (name) => _replaceTeam(weekNum, gameIdx, side, name),
        );
      }
    }.toJS);
  }

  // ─── Integrity ────────────────────────────────────────────────────────────

  String _buildIntegrityHtml(ScheduleDisplay? schedule) {
    if (schedule == null || schedule.weeks.isEmpty) {
      return '<p style="color:var(--color-muted);font-size:13px;">No schedule data found.</p>';
    }

    final schedText = appState.scheduleText ?? '';
    final issues = <String>[];

    // Check 1: teams appearing more than once in a week
    final dupsByWeek = duplicateTeamsByWeek(schedText);
    for (int i = 0; i < dupsByWeek.length; i++) {
      for (final team in dupsByWeek[i]) {
        final a = _esc(teamAbbr(team));
        final n = _esc(team);
        issues.add('Week ${i + 1}: <strong>$a</strong> ($n) is scheduled more than once.');
      }
    }

    // Check 2: each team should have exactly 16 games
    final counts = gameCountByTeam(schedText);
    for (final teamName in kTeamNamesSorted) {
      final count = counts[teamName] ?? 0;
      if (count != 16) {
        final a = _esc(teamAbbr(teamName));
        final n = _esc(teamName);
        final s = count == 1 ? 'game' : 'games';
        issues.add('$a ($n) has <strong>$count</strong> $s — expected 16.');
      }
    }

    if (issues.isEmpty) {
      return '''
<div class="sch-integrity-item ok">
  <span class="material-symbols-outlined">check_circle</span>
  <span>All 32 teams have exactly 16 games and no team is double-booked in any week.</span>
</div>''';
    }

    final buf = StringBuffer();
    for (final msg in issues) {
      buf.write('''
<div class="sch-integrity-item">
  <span class="material-symbols-outlined">warning</span>
  <span>$msg</span>
</div>
''');
    }
    return buf.toString();
  }

  // ─── Team Picker Dialog ───────────────────────────────────────────────────

  void _openTeamPicker({
    required String title,
    required void Function(String teamName) onPicked,
  }) {
    if (_pickerOverlay != null) return;

    final btns = kTeamNamesSorted.map((name) {
      final abbr = _esc(teamAbbr(name));
      return '<button class="sch-team-btn" data-name="${_esc(name)}">$abbr</button>';
    }).join();

    final overlay = document.createElement('div') as HTMLElement;
    overlay.className = 'dialog-overlay';
    overlay.innerHTML = '''
<div class="dialog sch-picker-dialog">
  <div class="dialog-header">
    <span>${_esc(title)}</span>
    <span class="material-symbols-outlined dialog-close">close</span>
  </div>
  <div class="sch-picker-body">$btns</div>
</div>'''.toJS;
    document.body!.append(overlay);
    _pickerOverlay = overlay;

    void close() {
      final fn = _pickerEscFn;
      if (fn != null) document.removeEventListener('keydown', fn);
      _pickerEscFn = null;
      _pickerOverlay?.remove();
      _pickerOverlay = null;
    }

    late final JSFunction escFn;
    escFn = (Event e) {
      if ((e as KeyboardEvent).key == 'Escape') close();
    }.toJS;
    document.addEventListener('keydown', escFn);
    _pickerEscFn = escFn;

    overlay.addEventListener('click', (Event e) {
      if ((e.target as HTMLElement?) == overlay) close();
    }.toJS);
    (overlay.firstElementChild as HTMLElement?)
        ?.addEventListener('click', (Event e) { e.stopPropagation(); }.toJS);

    overlay.querySelector('.dialog-close')
        ?.addEventListener('click', (Event _) { close(); }.toJS);

    overlay.querySelector('.sch-picker-body')
        ?.addEventListener('click', (Event e) {
      final btn =
          (e.target as HTMLElement?)?.closest('.sch-team-btn') as HTMLElement?;
      if (btn == null) return;
      final name = btn.dataset['name'];
      if (name.isEmpty) return;
      close();
      onPicked(name);
    }.toJS);
  }

  // ─── Shared edit helpers ──────────────────────────────────────────────────

  void _replaceTeam(int weekNum, int gameIdx, String side, String newTeamName) {
    final schedText = appState.scheduleText ?? '';
    final schedule = _getSchedule();
    if (schedule == null) return;
    final week = schedule.weeks.firstWhere(
      (w) => w.number == weekNum,
      orElse: () => ScheduleWeek(number: weekNum, games: const []),
    );
    if (gameIdx >= week.games.length) return;
    final game = week.games[gameIdx];
    final newAway = side == 'away' ? newTeamName : game.away;
    final newHome = side == 'home' ? newTeamName : game.home;
    _applyScheduleEdit(setGameInText(schedText, weekNum, gameIdx, newAway, newHome));
  }

  void _applyScheduleEdit(String newScheduleText) {
    appState.updateScheduleInText(newScheduleText);
    _refreshView();
  }

  // ─── Utility ─────────────────────────────────────────────────────────────

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
