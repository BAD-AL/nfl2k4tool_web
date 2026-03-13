import 'dart:js_interop';
import 'package:web/web.dart';
import '../app_state.dart';

class CoachEditorScreen {
  final AppState appState;
  final HTMLElement _container;

  CoachEditorScreen(this.appState)
      : _container =
            document.getElementById('screen-coaches') as HTMLElement;

  void render() {
    // Full coach editor rendered in Phase 6.
    _container.innerHTML = '''
      <div class="placeholder-screen">
        <span class="material-symbols-outlined">school</span>
        <h2>Coach Editor</h2>
        <p>Coach editor coming in a future phase.</p>
      </div>
    '''.toJS;
  }
}
