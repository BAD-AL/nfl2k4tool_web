import 'dart:js_interop';
import 'package:web/web.dart';
import '../app_state.dart';

class OptionsScreen {
  final AppState appState;
  final HTMLElement _container;

  OptionsScreen(this.appState)
      : _container =
            document.getElementById('screen-options') as HTMLElement;

  void render() {
    // Full options screen rendered in Phase 6.
    _container.innerHTML = '''
      <div class="section-header">
        <span class="material-symbols-outlined section-icon">settings</span>
        <span class="section-title">Options</span>
      </div>
      <div style="padding:24px;color:var(--color-muted);font-size:13px;">
        Options screen coming in Phase 6.
      </div>
    '''.toJS;
  }
}
