import 'dart:js_interop';
import 'package:web/web.dart';
import '../app_state.dart';

class ScheduleEditorScreen {
  final AppState appState;
  final HTMLElement _container;

  ScheduleEditorScreen(this.appState)
      : _container =
            document.getElementById('screen-schedule') as HTMLElement;

  void render() {
    if (!appState.isFranchise) {
      _container.innerHTML = '''
        <div class="placeholder-screen">
          <span class="material-symbols-outlined">calendar_month</span>
          <h2>Schedule Editor</h2>
          <p>Not available — open a Franchise file to edit the schedule.</p>
        </div>
      '''.toJS;
      return;
    }
    // Full schedule editor rendered in Phase 5
    _container.innerHTML = '''
      <div class="section-header">
        <span class="material-symbols-outlined section-icon">calendar_month</span>
        <span class="section-title">Schedule Editor</span>
      </div>
      <div style="padding:24px;color:var(--color-muted);font-size:13px;">
        Schedule editor coming in Phase 5.
      </div>
    '''.toJS;
  }
}
