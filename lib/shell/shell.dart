import 'package:web/web.dart';
import '../app_state.dart';

/// Routes between screens by showing/hiding the appropriate screen div.
class Shell {
  final AppState appState;

  final Map<NavSection, HTMLElement> _screens = {};

  Shell(this.appState) {
    for (final section in NavSection.values) {
      final id = 'screen-${section.name}';
      final el = document.getElementById(id) as HTMLElement?;
      if (el != null) _screens[section] = el;
    }
  }

  void render() {
    for (final entry in _screens.entries) {
      if (entry.key == appState.activeSection) {
        entry.value.removeAttribute('hidden');
      } else {
        entry.value.setAttribute('hidden', '');
      }
    }
  }
}
