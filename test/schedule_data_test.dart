import 'package:test/test.dart';
import 'package:nfl2k5tool_web/data/schedule_data.dart';

const _sampleSchedule = '''YEAR=2004

WEEK 1  [3 games]
colts at patriots
jaguars at bills
bears at packers

WEEK 2  [2 games]
patriots at dolphins
rams at 49ers
''';

void main() {
  // ── parseScheduleForDisplay ───────────────────────────────────────────────

  group('parseScheduleForDisplay', () {
    test('T-SCHED-PARSE-01: extracts year correctly', () {
      final d = parseScheduleForDisplay(_sampleSchedule);
      expect(d.year, 2004);
    });

    test('T-SCHED-PARSE-02: parses week count', () {
      final d = parseScheduleForDisplay(_sampleSchedule);
      expect(d.weeks.length, 2);
    });

    test('T-SCHED-PARSE-02: first week number is 1', () {
      final d = parseScheduleForDisplay(_sampleSchedule);
      expect(d.weeks[0].number, 1);
    });

    test('T-SCHED-PARSE-02: first game of week 1 parsed correctly', () {
      final d = parseScheduleForDisplay(_sampleSchedule);
      expect(d.weeks[0].games[0].away, 'colts');
      expect(d.weeks[0].games[0].home, 'patriots');
    });

    test('game counts per week are correct', () {
      final d = parseScheduleForDisplay(_sampleSchedule);
      expect(d.weeks[0].games.length, 3);
      expect(d.weeks[1].games.length, 2);
    });
  });

  // ── setGameInText ─────────────────────────────────────────────────────────

  group('setGameInText', () {
    test('replaces the correct game line', () {
      final result = setGameInText(_sampleSchedule, 1, 0, 'ravens', 'patriots');
      expect(result, contains('ravens at patriots'));
    });

    test('other game lines in the same week are unchanged', () {
      final result = setGameInText(_sampleSchedule, 1, 0, 'ravens', 'patriots');
      expect(result, contains('jaguars at bills'));
      expect(result, contains('bears at packers'));
    });

    test('other weeks are unchanged', () {
      final result = setGameInText(_sampleSchedule, 1, 0, 'ravens', 'patriots');
      expect(result, contains('patriots at dolphins'));
    });

    test('original game line is gone after replacement', () {
      final result = setGameInText(_sampleSchedule, 1, 0, 'ravens', 'patriots');
      expect(result, isNot(contains('colts at patriots')));
    });

    test('returns text unchanged for non-existent week', () {
      final result = setGameInText(_sampleSchedule, 99, 0, 'ravens', 'bills');
      expect(result, _sampleSchedule);
    });
  });

  // ── removeGameFromText ────────────────────────────────────────────────────

  group('removeGameFromText', () {
    test('removes the correct game line', () {
      final result = removeGameFromText(_sampleSchedule, 1, 0);
      expect(result, isNot(contains('colts at patriots')));
    });

    test('other games in the week remain', () {
      final result = removeGameFromText(_sampleSchedule, 1, 0);
      expect(result, contains('jaguars at bills'));
    });

    test('updates the [N games] count on the header', () {
      final result = removeGameFromText(_sampleSchedule, 1, 0);
      expect(result, contains('[2 games]'));
    });

    test('other weeks are unchanged', () {
      final result = removeGameFromText(_sampleSchedule, 1, 0);
      expect(result, contains('[2 games]\npatriots at dolphins'));
    });
  });

  // ── addGameToText ─────────────────────────────────────────────────────────

  group('addGameToText', () {
    test('new game line appears in the correct week', () {
      final result = addGameToText(_sampleSchedule, 1, 'steelers', 'ravens');
      expect(result, contains('steelers at ravens'));
    });

    test('updates the [N games] count on the header', () {
      final result = addGameToText(_sampleSchedule, 1, 'steelers', 'ravens');
      expect(result, contains('[4 games]'));
    });

    test('other weeks are unchanged', () {
      final result = addGameToText(_sampleSchedule, 1, 'steelers', 'ravens');
      expect(result, contains('WEEK 2  [2 games]'));
    });
  });

  // ── gameCountByTeam ───────────────────────────────────────────────────────

  group('gameCountByTeam', () {
    test('patriots appear twice (home W1, away W2)', () {
      final counts = gameCountByTeam(_sampleSchedule);
      expect(counts['patriots'], 2);
    });

    test('colts appear once', () {
      final counts = gameCountByTeam(_sampleSchedule);
      expect(counts['colts'], 1);
    });
  });

  // ── duplicateTeamsByWeek ──────────────────────────────────────────────────

  group('duplicateTeamsByWeek', () {
    test('no duplicates in valid schedule', () {
      final dupes = duplicateTeamsByWeek(_sampleSchedule);
      for (final weekDupes in dupes) {
        expect(weekDupes, isEmpty);
      }
    });

    test('detects duplicate team in same week', () {
      const badSchedule = '''WEEK 1  [2 games]
patriots at colts
patriots at bills
''';
      final dupes = duplicateTeamsByWeek(badSchedule);
      expect(dupes[0], contains('patriots'));
    });
  });

  // ── teamAbbr ──────────────────────────────────────────────────────────────

  group('teamAbbr', () {
    test('known team returns correct abbreviation', () {
      expect(teamAbbr('patriots'), 'NE');
      expect(teamAbbr('49ers'), 'SF');
      expect(teamAbbr('redskins'), 'WAS');
    });

    test('case insensitive', () {
      expect(teamAbbr('Patriots'), 'NE');
      expect(teamAbbr('PATRIOTS'), 'NE');
    });

    test('unknown team returns uppercased name', () {
      expect(teamAbbr('unknownteam'), 'UNKNOWNTEAM');
    });
  });

  // ── kTeamNamesSorted ──────────────────────────────────────────────────────

  group('kTeamNamesSorted', () {
    test('contains 32 teams', () {
      expect(kTeamNamesSorted.length, 32);
    });

    test('first team is cardinals (ARI)', () {
      expect(kTeamNamesSorted.first, 'cardinals');
    });

    test('last team is redskins (WAS)', () {
      expect(kTeamNamesSorted.last, 'redskins');
    });

    test('sorted by abbreviation ascending', () {
      final abbrs = kTeamNamesSorted.map(teamAbbr).toList();
      final sorted = [...abbrs]..sort();
      expect(abbrs, sorted);
    });
  });
}
