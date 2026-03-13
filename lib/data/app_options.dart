import 'package:web/web.dart' show window;

/// Persistent user options, stored in localStorage.
class AppOptions {
  // Text View section
  bool showPlayers;
  bool showSchedule;
  bool showAppearance;
  bool showAttributes;
  bool showSpecialTeams;
  bool showFreeAgents;
  bool showDraftClass;
  bool showCoaches;

  // Auto Update section
  bool autoUpdateDepthCharts;
  bool autoUpdatePhotos;
  bool autoUpdatePBP;

  AppOptions({
    this.showPlayers = true,
    this.showSchedule = true,
    this.showAppearance = true,
    this.showAttributes = true,
    this.showSpecialTeams = false,
    this.showFreeAgents = false,
    this.showDraftClass = false,
    this.showCoaches = false,
    this.autoUpdateDepthCharts = true,
    this.autoUpdatePhotos = false,
    this.autoUpdatePBP = true,
  });

  static AppOptions load() {
    final s = window.localStorage;
    bool get(String key, bool def) =>
        s.getItem(key) == null ? def : s.getItem(key) != 'false';
    return AppOptions(
      showPlayers:           get('showPlayers', true),
      showSchedule:          get('showSchedule', true),
      showAppearance:        get('showAppearance', true),
      showAttributes:        get('showAttributes', true),
      showSpecialTeams:      get('showSpecialTeams', false),
      showFreeAgents:        get('showFreeAgents', false),
      showDraftClass:        get('showDraftClass', false),
      showCoaches:           get('showCoaches', false),
      autoUpdateDepthCharts: get('autoUpdateDepthCharts', true),
      autoUpdatePhotos:      get('autoUpdatePhotos', false),
      autoUpdatePBP:         get('autoUpdatePBP', true),
    );
  }

  void save() {
    final s = window.localStorage;
    s.setItem('showPlayers',           showPlayers.toString());
    s.setItem('showSchedule',          showSchedule.toString());
    s.setItem('showAppearance',        showAppearance.toString());
    s.setItem('showAttributes',        showAttributes.toString());
    s.setItem('showSpecialTeams',      showSpecialTeams.toString());
    s.setItem('showFreeAgents',        showFreeAgents.toString());
    s.setItem('showDraftClass',        showDraftClass.toString());
    s.setItem('showCoaches',           showCoaches.toString());
    s.setItem('autoUpdateDepthCharts', autoUpdateDepthCharts.toString());
    s.setItem('autoUpdatePhotos',      autoUpdatePhotos.toString());
    s.setItem('autoUpdatePBP',         autoUpdatePBP.toString());
  }
}
