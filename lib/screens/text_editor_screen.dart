import 'dart:js_interop';
import 'package:web/web.dart';
import '../app_state.dart';

class TextEditorScreen {
  final AppState _appState;
  final HTMLElement _container;

  int _fontSize = 13;
  String _searchTerm = '';
  List<int> _matchOffsets = [];
  int _matchIndex = -1;

  // Search popup state
  HTMLElement? _searchOverlay;
  JSFunction? _searchDocKeyFn;

  TextEditorScreen(this._appState)
      : _container =
            document.getElementById('screen-textEditor') as HTMLElement;

  void render() {
    final area = _container.querySelector('#te-area') as HTMLTextAreaElement?;

    if (area != null) {
      // Already mounted — sync value if it changed externally.
      if (area.value != _appState.textContent) {
        area.value = _appState.textContent;
      }
      return;
    }

    _container.innerHTML = _buildHtml().toJS;
    _wire();
  }

  // ─── HTML ─────────────────────────────────────────────────────────────────

  String _buildHtml() => '''
<div class="section-header">
  <span class="material-symbols-outlined section-icon">edit_note</span>
  <span class="section-title">Text Editor</span>
  <span id="te-search-hint" class="section-subtitle"
    style="font-size:11px;color:var(--color-muted);cursor:pointer;">Ctrl+F to search</span>
  <div class="te-font-ctrl">
    <button id="te-font-dec" class="btn btn-outlined te-font-btn">−</button>
    <span id="te-font-size" class="te-font-label">${_fontSize}px</span>
    <button id="te-font-inc" class="btn btn-outlined te-font-btn">+</button>
  </div>
</div>
<div class="te-body">
  <textarea id="te-area" class="te-area"
    style="font-size:${_fontSize}px;"
    spellcheck="false" autocorrect="off" autocapitalize="off"
  ></textarea>
</div>
''';

  // ─── Wiring ───────────────────────────────────────────────────────────────

  void _wire() {
    final area = _container.querySelector('#te-area') as HTMLTextAreaElement?;
    if (area == null) return;

    area.value = _appState.textContent;

    // Text editing — update model; re-run search if active.
    area.addEventListener('input', (Event _) {
      _appState.textContent = area.value;
      _appState.refreshCounts();
      if (_searchTerm.isNotEmpty) _rerunSearch(area);
    }.toJS);

    // Ctrl+F → open search popup; F3/Shift+F3 → navigate matches.
    area.addEventListener('keydown', (Event e) {
      final ke = e as KeyboardEvent;
      if (ke.ctrlKey && ke.key == 'f') {
        e.preventDefault();
        _openSearchPopup(area);
        return;
      }
      if (ke.key == 'F3') {
        e.preventDefault();
        if (ke.shiftKey) { _prevMatch(area); } else { _nextMatch(area); }
      }
    }.toJS);

    // Search hint click.
    _container.querySelector('#te-search-hint')?.addEventListener('click', (Event _) {
      _openSearchPopup(area);
    }.toJS);

    // Font − / + buttons.
    _container.querySelector('#te-font-dec')?.addEventListener('click', (Event _) {
      if (_fontSize > 8) { _fontSize--; _applyFontSize(area); }
    }.toJS);
    _container.querySelector('#te-font-inc')?.addEventListener('click', (Event _) {
      if (_fontSize < 28) { _fontSize++; _applyFontSize(area); }
    }.toJS);
  }

  // ─── Font size ────────────────────────────────────────────────────────────

  void _applyFontSize(HTMLTextAreaElement area) {
    area.style.fontSize = '${_fontSize}px';
    final label = _container.querySelector('#te-font-size') as HTMLElement?;
    if (label != null) label.textContent = '${_fontSize}px';
  }

  // ─── Search popup ─────────────────────────────────────────────────────────

  void _openSearchPopup(HTMLTextAreaElement area) {
    if (_searchOverlay != null) return;

    final overlay = document.createElement('div') as HTMLElement;
    overlay.className = 'dialog-overlay';
    overlay.innerHTML = '''
<div class="dialog te-search-dialog">
  <div class="dialog-header">
    <span>Find</span>
    <span class="material-symbols-outlined dialog-close">close</span>
  </div>
  <div class="dialog-body" style="padding:12px 16px;">
    <input id="te-search-input" type="text" placeholder="Search\u2026"
      style="width:100%;background:var(--color-chip);border:1px solid var(--color-border);
             border-radius:4px;color:var(--color-text);padding:6px 10px;font-size:13px;
             outline:none;box-sizing:border-box;"
      autocomplete="off" spellcheck="false">
  </div>
  <div class="dialog-footer">
    <button class="btn btn-outlined" id="te-search-cancel">Cancel</button>
    <button class="btn btn-filled" id="te-search-ok">OK</button>
  </div>
</div>'''.toJS;

    document.body!.append(overlay);
    _searchOverlay = overlay;

    final input = overlay.querySelector('#te-search-input') as HTMLInputElement?;
    if (input != null) {
      input.value = _searchTerm; // pre-fill with last search term
      Future.delayed(Duration.zero, () { input.focus(); input.select(); });
    }

    void close(bool confirm) {
      final fn = _searchDocKeyFn;
      if (fn != null) document.removeEventListener('keydown', fn);
      _searchDocKeyFn = null;
      _searchOverlay?.remove();
      _searchOverlay = null;

      if (confirm) {
        _searchTerm = input?.value ?? '';
        _runSearch();
        if (_matchOffsets.isNotEmpty) {
          _jumpTo(area, 0);
        } else {
          area.focus();
        }
      } else {
        _searchTerm = '';
        _matchOffsets = [];
        _matchIndex = -1;
        area.focus();
      }
    }

    // ESC → cancel
    late final JSFunction docKeyFn;
    docKeyFn = (Event e) {
      if ((e as KeyboardEvent).key == 'Escape') close(false);
    }.toJS;
    document.addEventListener('keydown', docKeyFn);
    _searchDocKeyFn = docKeyFn;

    // Backdrop click → cancel
    overlay.addEventListener('click', (Event e) {
      if ((e.target as HTMLElement?) == overlay) close(false);
    }.toJS);
    (overlay.firstElementChild as HTMLElement?)
        ?.addEventListener('click', (Event e) { e.stopPropagation(); }.toJS);

    // Cancel / X buttons
    final cancelBtn = overlay.querySelector('#te-search-cancel') as HTMLElement?;
    cancelBtn?.addEventListener('click', (Event e) {
      e.stopPropagation();
      close(false);
    }.toJS);
    overlay.querySelector('.dialog-close')
        ?.addEventListener('click', (Event _) { cancelBtn?.click(); }.toJS);

    // OK button
    overlay.querySelector('#te-search-ok')?.addEventListener('click', (Event e) {
      e.stopPropagation();
      close(true);
    }.toJS);

    // Enter in input → OK
    input?.addEventListener('keydown', (Event e) {
      if ((e as KeyboardEvent).key == 'Enter') {
        e.preventDefault();
        close(true);
      }
    }.toJS);
  }

  // ─── Search logic ─────────────────────────────────────────────────────────

  void _runSearch() {
    _matchOffsets = [];
    _matchIndex = -1;
    if (_searchTerm.isEmpty) return;
    final text = _appState.textContent.toLowerCase();
    final term = _searchTerm.toLowerCase();
    int start = 0;
    while (true) {
      final idx = text.indexOf(term, start);
      if (idx < 0) break;
      _matchOffsets.add(idx);
      start = idx + 1;
    }
  }

  /// Re-runs search after a text edit, keeping the current match index stable.
  void _rerunSearch(HTMLTextAreaElement area) {
    final prev = _matchIndex;
    _runSearch();
    if (_matchOffsets.isNotEmpty) {
      _matchIndex = prev.clamp(0, _matchOffsets.length - 1);
    }
  }

  void _jumpTo(HTMLTextAreaElement area, int index) {
    if (_matchOffsets.isEmpty) return;
    _matchIndex = index.clamp(0, _matchOffsets.length - 1);
    final start = _matchOffsets[_matchIndex];
    final end = start + _searchTerm.length;
    area.focus();
    area.setSelectionRange(start, end);
    _scrollToOffset(area, start);
  }

  void _nextMatch(HTMLTextAreaElement area) {
    if (_matchOffsets.isEmpty) return;
    _jumpTo(area, (_matchIndex + 1) % _matchOffsets.length);
  }

  void _prevMatch(HTMLTextAreaElement area) {
    if (_matchOffsets.isEmpty) return;
    _jumpTo(area, (_matchIndex - 1 + _matchOffsets.length) % _matchOffsets.length);
  }

  /// Scrolls the textarea so the match at [offset] is vertically centred.
  void _scrollToOffset(HTMLTextAreaElement area, int offset) {
    final linesBefore = '\n'.allMatches(area.value.substring(0, offset)).length;
    final lineHeightPx = _fontSize * 1.5;
    final target = linesBefore * lineHeightPx - area.clientHeight / 2 + lineHeightPx;
    area.scrollTop = target.clamp(0, double.infinity);
  }
}
