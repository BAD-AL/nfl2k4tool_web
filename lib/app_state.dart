import 'package:nfl2k4tool_dart/nfl2k4tool_dart.dart';
import 'data/app_options.dart';
import 'data/text_parser.dart';

enum NavSection { options, players, schedule, coaches, teamData, textEditor }

class AppState {
  // File state
  NFL2K4Gamesave? tool;
  String textContent = '';
  String? fileName;
  String? fileType; // 'FRANCHISE' | 'ROSTER' | null
  int teamCount = 0;
  int playerCount = 0;
  String? statusMessage;

  // UI state
  NavSection activeSection = NavSection.players;
  bool railCollapsed = false;
  String themeMode = 'dark'; // 'dark' | 'light'

  // Options
  AppOptions options = AppOptions();

  bool get hasFile => tool != null;
  bool get isFranchise => fileType == 'FRANCHISE';

  // §15.9 Schedule text extraction
  String? get scheduleText {
    const marker = '\nYEAR=';
    final pos = textContent.indexOf(marker);
    return pos >= 0 ? textContent.substring(pos + 1) : null;
  }

  void updateScheduleInText(String newScheduleText) {
    const marker = '\nYEAR=';
    final pos = textContent.indexOf(marker);
    final playerSection =
        pos >= 0 ? textContent.substring(0, pos) : textContent;
    textContent = '$playerSection\n$newScheduleText';
  }

  // §15.8 Text content construction
  String buildTextContent(NFL2K4Gamesave t, AppOptions opts) {
    final buf = StringBuffer();

    RosterKey key;
    if (opts.showAttributes && opts.showAppearance) {
      key = RosterKey.all;
    } else if (opts.showAttributes) {
      key = RosterKey.abilities;
    } else if (opts.showAppearance) {
      key = RosterKey.appearance;
    } else {
      key = const RosterKey(['Position', 'fname', 'lname', 'JerseyNumber']);
    }

    //if (opts.showPlayers || opts.showFreeAgents || opts.showDraftClass) {
    //  buf.write('#');
    //  buf.write(key.fields.join(','));
    //  buf.write('\n');
    //}

    //buf.write('\n# Uncomment line below to Set Salary Cap -> 198.2M\n');
    //buf.write('# SET(0x9ACCC, 0x38060300)\n\n');

    if (opts.showPlayers) {
      buf.write(t.toText(key));
    }
    if (opts.showFreeAgents) {
      buf.write(t.toText(key, teamIndex: -1));
    }
    // NFL 2K4 doesn't have a dedicated 'DraftClass' section like 2K5,
    // but the last team slots are often used for it.
    // For now we'll skip special DraftClass logic if not found.

    if (opts.showCoaches) {
      buf.write(t.toCoachDataText());
    }
    if (opts.showTeamData) {
      buf.write('\n\n');
      // In 2K4, player-controlled info is part of toTeamDataText() for franchise saves.
      buf.write(t.toTeamDataText());
    }
    if (opts.showSchedule && t.isFranchise) {
      buf.write('\n\n#Schedule\n');
      buf.write(scheduleToText(t.getSchedule()));
    }
    if (opts.autoUpdateDepthCharts) buf.write('\nAutoUpdateDepthChart');
    if (opts.autoUpdatePhotos) buf.write('\nAutoUpdatePhoto');
    if (opts.autoUpdatePBP) buf.write('\nAutoUpdatePBP');
    if (opts.autoFixSkinFromPhoto) buf.write('\nAutoFixSkinFromPhoto');
    if (opts.vrabelFix) buf.write('\nvrabelFix');
    return buf.toString();
  }

  // Recompute teamCount/playerCount from current textContent
  void refreshCounts() {
    final (t, p) = countTeamsAndPlayers(textContent);
    teamCount = t;
    playerCount = p;
  }

  // Listener pattern
  final _listeners = <void Function()>[];
  void addListener(void Function() fn) => _listeners.add(fn);
  void notify() {
    for (final fn in _listeners) {
      fn();
    }
  }
}
