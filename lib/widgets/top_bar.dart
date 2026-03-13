import 'package:web/web.dart';
import '../app_state.dart';

class TopBar {
  final AppState appState;

  final HTMLButtonElement _btnOpen;
  final HTMLButtonElement _btnExport;
  final HTMLElement _fileBadge;
  final HTMLElement _fileBadgeType;
  final HTMLElement _fileBadgeName;
  final HTMLButtonElement _btnTheme;
  final HTMLElement _themeIcon;

  TopBar(this.appState)
      : _btnOpen = document.getElementById('btn-open') as HTMLButtonElement,
        _btnExport =
            document.getElementById('btn-export') as HTMLButtonElement,
        _fileBadge = document.getElementById('file-badge') as HTMLElement,
        _fileBadgeType =
            document.getElementById('file-badge-type') as HTMLElement,
        _fileBadgeName =
            document.getElementById('file-badge-name') as HTMLElement,
        _btnTheme = document.getElementById('btn-theme') as HTMLButtonElement,
        _themeIcon = document.getElementById('theme-icon') as HTMLElement;

  void wire({
    required void Function() onOpen,
    required void Function() onExport,
    required void Function() onThemeToggle,
  }) {
    _btnOpen.onClick.listen((_) => onOpen());
    _btnExport.onClick.listen((_) => onExport());
    _btnTheme.onClick.listen((_) => onThemeToggle());
  }

  void render() {
    _btnExport.disabled = !appState.hasFile;

    if (appState.hasFile && appState.fileName != null) {
      _fileBadgeType.textContent = appState.fileType ?? '';
      _fileBadgeName.textContent = appState.fileName ?? '';
      _fileBadge.removeAttribute('hidden');
    } else {
      _fileBadge.setAttribute('hidden', '');
    }

    if (appState.themeMode == 'light') {
      _themeIcon.textContent = 'light_mode';
      _btnTheme.title = 'Switch to Dark mode';
    } else {
      _themeIcon.textContent = 'dark_mode';
      _btnTheme.title = 'Switch to Light mode';
    }
  }
}
