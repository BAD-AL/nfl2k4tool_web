import 'package:web/web.dart';
import '../app_state.dart';

class NavRail {
  final AppState appState;

  final HTMLElement _rail;
  final HTMLElement _collapseIcon;
  final HTMLButtonElement _btnCollapse;

  // Nav item elements keyed by section name
  final Map<String, HTMLElement> _navItems = {};

  NavRail(this.appState)
      : _rail = document.getElementById('nav-rail') as HTMLElement,
        _collapseIcon =
            document.getElementById('rail-collapse-icon') as HTMLElement,
        _btnCollapse =
            document.getElementById('btn-rail-collapse') as HTMLButtonElement {
    for (final section in NavSection.values) {
      final id = 'nav-${section.name}';
      final el = document.getElementById(id) as HTMLElement?;
      if (el != null) _navItems[section.name] = el;
    }
  }

  void wire({required void Function(NavSection) onNav}) {
    for (final entry in _navItems.entries) {
      entry.value.onClick.listen((_) {
        final section =
            NavSection.values.firstWhere((s) => s.name == entry.key);
        // Ignore clicks on disabled schedule item when no franchise loaded
        if (section == NavSection.schedule && !appState.isFranchise) return;
        onNav(section);
      });
    }

    _btnCollapse.onClick.listen((_) {
      appState.railCollapsed = !appState.railCollapsed;
      render();
    });
  }

  void render() {
    // Collapsed state
    if (appState.railCollapsed) {
      _rail.classList.add('collapsed');
      _collapseIcon.textContent = 'chevron_right';
      _btnCollapse.title = 'Expand sidebar';
    } else {
      _rail.classList.remove('collapsed');
      _collapseIcon.textContent = 'chevron_left';
      _btnCollapse.title = 'Collapse sidebar';
    }

    // Active item highlighting
    for (final entry in _navItems.entries) {
      final section =
          NavSection.values.firstWhere((s) => s.name == entry.key);
      if (section == appState.activeSection) {
        entry.value.classList.add('active');
      } else {
        entry.value.classList.remove('active');
      }
    }

    // Schedule item: disabled unless franchise loaded
    final scheduleEl = _navItems[NavSection.schedule.name];
    if (scheduleEl != null) {
      if (appState.isFranchise) {
        scheduleEl.classList.remove('nav-item--disabled');
      } else {
        scheduleEl.classList.add('nav-item--disabled');
      }
    }
  }
}
