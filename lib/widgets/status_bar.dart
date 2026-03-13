import 'package:web/web.dart';
import '../app_state.dart';

class StatusBar {
  final AppState appState;

  final HTMLElement _dot;
  final HTMLElement _text;
  final HTMLElement _sep;
  final HTMLElement _extra;

  StatusBar(this.appState)
      : _dot = document.getElementById('status-dot') as HTMLElement,
        _text = document.getElementById('status-text') as HTMLElement,
        _sep = document.getElementById('status-sep') as HTMLElement,
        _extra = document.getElementById('status-extra') as HTMLElement;

  void render() {
    if (appState.hasFile) {
      _dot.classList.add('loaded');
      _text.textContent =
          '${appState.fileType ?? 'FILE'} File Loaded';

      if (appState.statusMessage != null) {
        // Transient message
        _sep.removeAttribute('hidden');
        _extra.textContent = appState.statusMessage;
        _extra.removeAttribute('hidden');
      } else if (appState.teamCount > 0) {
        // Team/player counts
        _sep.removeAttribute('hidden');
        _extra.textContent =
            '${appState.teamCount} Teams · ${appState.playerCount} Players';
        _extra.removeAttribute('hidden');
      } else {
        _sep.setAttribute('hidden', '');
        _extra.setAttribute('hidden', '');
      }
    } else {
      _dot.classList.remove('loaded');
      _text.textContent = 'No File Loaded';

      if (appState.statusMessage != null) {
        _sep.removeAttribute('hidden');
        _extra.textContent = appState.statusMessage;
        _extra.removeAttribute('hidden');
      } else {
        _sep.setAttribute('hidden', '');
        _extra.setAttribute('hidden', '');
      }
    }
  }

  /// Show a transient message, then clear it after [durationMs] milliseconds.
  void showMessage(String message, {int durationMs = 3000}) {
    appState.statusMessage = message;
    render();
    Future.delayed(Duration(milliseconds: durationMs), () {
      appState.statusMessage = null;
      render();
    });
  }
}
