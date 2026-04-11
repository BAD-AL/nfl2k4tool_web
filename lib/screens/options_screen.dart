import 'dart:js_interop';
import 'package:web/web.dart';
import '../app_state.dart';

class OptionsScreen {
  final AppState appState;
  final HTMLElement _container;

  OptionsScreen(this.appState)
      : _container =
            document.getElementById('screen-options') as HTMLElement;

  // ─── Entry point ──────────────────────────────────────────────────────────

  void render() {
    _container.innerHTML = _buildHtml().toJS;
    _wireToggles();
  }

  // ─── HTML ─────────────────────────────────────────────────────────────────

  String _buildHtml() {
    final o = appState.options;
    return '''
<div class="section-header">
  <span class="material-symbols-outlined section-icon">settings</span>
  <span class="section-title">Options</span>
</div>
<div class="options-screen">

  <div class="options-card">
    <div class="options-card-title">Text View</div>
    ${_row('showPlayers',      'Show Players',       o.showPlayers)}
    ${_row('showSchedule',     'Show Schedule',      o.showSchedule)}
    ${_row('showAttributes',   'Show Attributes',    o.showAttributes)}
    ${_row('showAppearance',   'Show Appearance',    o.showAppearance)}
    ${_row('showFreeAgents',   'Show Free Agents',   o.showFreeAgents)}
    ${_row('showDraftClass',   'Show Draft Class',   o.showDraftClass)}
    ${_row('showCoaches',      'Show Coaches',       o.showCoaches)}
    ${_row('showTeamData',     'Show Team Data',     o.showTeamData)}
  </div>

  <div class="options-card">
    <div class="options-card-title">Auto Update</div>
    ${_row('autoUpdateDepthCharts', 'Auto Update Depth Charts', o.autoUpdateDepthCharts)}
    ${_row('autoUpdatePhotos',      'Auto Update Photos',       o.autoUpdatePhotos)}
    ${_row('autoUpdatePBP',         'Auto Update PBP',          o.autoUpdatePBP)}
    ${_row('autoFixSkinFromPhoto',  'Auto Fix Skin from Photo', o.autoFixSkinFromPhoto)}
    <div class="options-row">
      <span class="options-row-label">Compress Free Agent names</span>
      <div style="display:flex; align-items:center; gap:12px;">
        <input type="number" data-key="compressFAValue" value="${o.compressFAValue}" 
          style="width:50px; background:var(--color-chip); border:1px solid var(--color-border); 
                 border-radius:4px; color:var(--color-text); padding:2px 4px; font-size:12px; outline:none;">
        <label class="toggle-switch">
          <input type="checkbox" data-key="compressFANames"${o.compressFANames ? ' checked' : ''}>
          <span class="toggle-track"></span>
        </label>
      </div>
    </div>
  </div>

</div>
''';
  }

  String _row(String key, String label, bool checked) {
    final c = checked ? ' checked' : '';
    return '''
<div class="options-row">
  <span class="options-row-label">$label</span>
  <label class="toggle-switch">
    <input type="checkbox" data-key="$key"$c>
    <span class="toggle-track"></span>
  </label>
</div>''';
  }

  // ─── Wiring ───────────────────────────────────────────────────────────────

  static const _textViewKeys = {
    'showPlayers', 'showSchedule', 'showAttributes', 'showAppearance',
    'showFreeAgents', 'showDraftClass', 'showCoaches',
    'showTeamData',
  };

  static const _autoUpdateKeys = {
    'autoUpdateDepthCharts', 'autoUpdatePhotos', 'autoUpdatePBP', 'autoFixSkinFromPhoto',
    'compressFANames', 'compressFAValue',
  };

  void _wireToggles() {
    final inputs = _container.querySelectorAll('input[data-key]');
    for (var i = 0; i < inputs.length; i++) {
      final el = inputs.item(i) as HTMLInputElement;
      final key = el.dataset['key'];
      el.onchange = (Event _) {
        if (el.type == 'number') {
          final val = int.tryParse(el.value) ?? 50;
          _applyNumericOption(key, val);
          appState.options.save();
          if (appState.hasFile) {
            _syncAutoUpdateTags();
            appState.notify();
          }
          return;
        }
        final newValue = el.checked;
        if (_textViewKeys.contains(key)) {
          _handleTextViewToggle(el, key, newValue);
        } else if (_autoUpdateKeys.contains(key)) {
          _handleAutoUpdateToggle(key, newValue);
        }
      }.toJS;
    }
  }

  void _applyNumericOption(String key, int value) {
    if (key == 'compressFAValue') {
      appState.options.compressFAValue = value;
    }
  }

  // ─── Text View toggles ────────────────────────────────────────────────────

  void _handleTextViewToggle(HTMLInputElement el, String key, bool newValue) {
    if (appState.hasFile) {
      _showConfirmDialog(
        onConfirm: () {
          _applyOption(key, newValue);
          _rebuildText();
        },
        onCancel: () {
          // Revert the toggle visually
          el.checked = !newValue;
        },
      );
    } else {
      _applyOption(key, newValue);
      appState.options.save();
    }
  }

  void _rebuildText() {
    final tool = appState.tool;
    if (tool == null) return;
    appState.options.save();
    appState.textContent = appState.buildTextContent(tool, appState.options);
    appState.refreshCounts();
    appState.notify();
  }

  // ─── Auto Update toggles ──────────────────────────────────────────────────

  void _handleAutoUpdateToggle(String key, bool newValue) {
    _applyOption(key, newValue);
    appState.options.save();
    if (appState.hasFile) {
      _syncAutoUpdateTags();
      appState.notify();
    }
  }

  /// Strips and re-appends all three auto-update tags based on current options.
  void _syncAutoUpdateTags() {
    var text = appState.textContent;
    text = text
        .replaceAll('\nAutoUpdateDepthChart', '')
        .replaceAll('\nAutoUpdatePhoto', '')
        .replaceAll('\nAutoUpdatePBP', '')
        .replaceAll('\nAutoFixSkinFromPhoto', '')
        .replaceAll(RegExp(r'\nCompressFA=\d+'), '');
    final o = appState.options;
    if (o.autoUpdateDepthCharts) text += '\nAutoUpdateDepthChart';
    if (o.autoUpdatePhotos) text += '\nAutoUpdatePhoto';
    if (o.autoUpdatePBP) text += '\nAutoUpdatePBP';
    if (o.autoFixSkinFromPhoto) text += '\nAutoFixSkinFromPhoto';
    if (o.compressFANames) text += '\nCompressFA=${o.compressFAValue}';
    appState.textContent = text;
  }

  // ─── Apply option by key ──────────────────────────────────────────────────

  void _applyOption(String key, bool value) {
    final o = appState.options;
    switch (key) {
      case 'showPlayers':           o.showPlayers = value;
      case 'showSchedule':          o.showSchedule = value;
      case 'showAttributes':        o.showAttributes = value;
      case 'showAppearance':        o.showAppearance = value;
      case 'showFreeAgents':        o.showFreeAgents = value;
      case 'showDraftClass':        o.showDraftClass = value;
      case 'showCoaches':           o.showCoaches = value;
      case 'showTeamData':          o.showTeamData = value;
      case 'autoUpdateDepthCharts': o.autoUpdateDepthCharts = value;
      case 'autoUpdatePhotos':      o.autoUpdatePhotos = value;
      case 'autoUpdatePBP':         o.autoUpdatePBP = value;
      case 'autoFixSkinFromPhoto':  o.autoFixSkinFromPhoto = value;
      case 'compressFANames':       o.compressFANames = value;
    }
  }

  // ─── Confirmation dialog ──────────────────────────────────────────────────

  void _showConfirmDialog({
    required void Function() onConfirm,
    required void Function() onCancel,
  }) {
    final overlay = document.createElement('div') as HTMLElement
      ..className = 'dialog-overlay';

    overlay.innerHTML = '''
<div class="dialog" style="max-width:400px;width:90%;">
  <div class="dialog-header">Regenerate Text?</div>
  <div class="dialog-body" style="font-size:13px;color:var(--color-text-secondary);line-height:1.5;">
    Changing this option will regenerate the text content from the save file.
    Any manual edits in the Text Editor will be lost.
  </div>
  <div class="dialog-footer">
    <button class="btn btn-outlined" id="opt-confirm-cancel">Cancel</button>
    <button class="btn btn-filled" id="opt-confirm-ok">Regenerate</button>
  </div>
</div>
'''.toJS;

    document.body!.append(overlay);

    (overlay.querySelector('#opt-confirm-ok') as HTMLButtonElement).onclick =
        (Event _) {
      overlay.remove();
      onConfirm();
    }.toJS;

    (overlay.querySelector('#opt-confirm-cancel') as HTMLButtonElement).onclick =
        (Event _) {
      overlay.remove();
      onCancel();
    }.toJS;

    // ESC closes and cancels
    JSFunction? escFn;
    escFn = (KeyboardEvent e) {
      if (e.key == 'Escape') {
        document.removeEventListener('keydown', escFn!);
        overlay.remove();
        onCancel();
      }
    }.toJS;
    document.addEventListener('keydown', escFn);
  }
}
