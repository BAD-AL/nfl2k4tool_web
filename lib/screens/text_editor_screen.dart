import 'dart:js_interop';
import 'package:web/web.dart';
import '../app_state.dart';

class TextEditorScreen {
  final AppState appState;
  final HTMLElement _container;

  TextEditorScreen(this.appState)
      : _container =
            document.getElementById('screen-textEditor') as HTMLElement;

  void render() {
    // Full text editor rendered in Phase 4.
    // For now, render a minimal live textarea bound to appState.textContent.
    _container.innerHTML = '''
      <div class="section-header">
        <span class="material-symbols-outlined section-icon">edit_note</span>
        <span class="section-title">Text Editor</span>
      </div>
      <div style="flex:1;display:flex;flex-direction:column;overflow:hidden;height:calc(100% - 44px);">
        <textarea id="text-editor-area" class="text-area"
          style="width:100%;height:100%;padding:8px;background:var(--color-bg);color:var(--color-text);font-family:monospace;font-size:13px;border:none;outline:none;resize:none;"></textarea>
      </div>
    '''.toJS;

    final area =
        document.getElementById('text-editor-area') as HTMLTextAreaElement?;
    if (area != null) {
      area.value = appState.textContent;
      area.onInput.listen((_) {
        appState.textContent = area.value;
        appState.refreshCounts();
      });
    }
  }
}
