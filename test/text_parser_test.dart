import 'dart:io';
import 'package:test/test.dart';
import 'package:nfl2k5tool_web/data/text_parser.dart';

void main() {
  // ── detectDelimiter ───────────────────────────────────────────────────────

  group('detectDelimiter', () {
    test('returns comma for comma-heavy text', () {
      expect(detectDelimiter('a,b,c;d'), ',');
    });

    test('returns semicolon for semicolon-heavy text', () {
      expect(detectDelimiter('a;b;c,d'), ';');
    });

    test('defaults to comma when equal', () {
      expect(detectDelimiter('a,b;c'), ',');
    });
  });

  // ── splitCsv ──────────────────────────────────────────────────────────────

  group('splitCsv', () {
    test('T-PARSE-01: basic player row splits correctly', () {
      const line = 'QB,Tom,Brady,12';
      final f = splitCsv(line);
      expect(f[0], 'QB');
      expect(f[1], 'Tom');
      expect(f[2], 'Brady');
      expect(f[3], '12');
    });

    test('T-PARSE-02: height with inch mark is a literal, not a quote opener', () {
      const line = "QB,Tom,Brady,12,6'0\",226";
      final f = splitCsv(line);
      expect(f[4], "6'0\"");
      expect(f[5], '226');
    });

    test('T-PARSE-03: quoted field with comma parses as single field', () {
      const line = '"Smith, Jr.",Tom,1,';
      final f = splitCsv(line);
      expect(f[0], 'Smith, Jr.');
      expect(f[1], 'Tom');
    });

    test('escaped double-quote inside quoted field', () {
      const line = '"He said ""hi""",next';
      final f = splitCsv(line);
      expect(f[0], 'He said "hi"');
      expect(f[1], 'next');
    });

    test('empty trailing field from trailing comma', () {
      const line = 'a,b,';
      final f = splitCsv(line);
      expect(f.length, 3);
      expect(f[2], '');
    });

    test('semicolon delimiter respected when passed explicitly', () {
      const line = 'a;b;c';
      final f = splitCsv(line, ';');
      expect(f, ['a', 'b', 'c']);
    });
  });

  // ── quoteCsvField ─────────────────────────────────────────────────────────

  group('quoteCsvField', () {
    test('T-PARSE-04: bare inch mark is NOT requoted', () {
      expect(quoteCsvField("6'0\""), "6'0\"");
    });

    test('T-PARSE-04: field with comma IS quoted', () {
      expect(quoteCsvField('Smith, Jr.'), '"Smith, Jr."');
    });

    test('plain field unchanged', () {
      expect(quoteCsvField('Brady'), 'Brady');
    });

    test('field with newline is quoted', () {
      expect(quoteCsvField('a\nb'), '"a\nb"');
    });
  });

  // ── splitCsv + quoteCsvField roundtrip ────────────────────────────────────

  group('CSV roundtrip', () {
    test('height value roundtrips cleanly', () {
      const original = "QB,Tom,Brady,6'0\",226,";
      final fields = splitCsv(original);
      final rejoined = fields.map(quoteCsvField).join(',');
      expect(splitCsv(rejoined), fields);
    });

    test('quoted comma field roundtrips cleanly', () {
      const original = '"Smith, Jr.",Tom,1,';
      final fields = splitCsv(original);
      final rejoined = fields.map(quoteCsvField).join(',');
      expect(splitCsv(rejoined)[0], 'Smith, Jr.');
    });
  });

  // ── setFieldInLine ────────────────────────────────────────────────────────

  group('setFieldInLine', () {
    const sampleText = '#fname,lname,Position,Speed\n'
        'Team = Bears    Players:2\n'
        'Tom,Brady,QB,85\n'
        'Peyton,Manning,QB,72\n';

    const headers = ['fname', 'lname', 'Position', 'Speed'];

    test('replaces a single field correctly', () {
      final result = setFieldInLine(sampleText, 2, 'Speed', '90', headers);
      final lines = result.split('\n');
      expect(lines[2], 'Tom,Brady,QB,90');
    });

    test('all other fields on the line are unchanged', () {
      final result = setFieldInLine(sampleText, 2, 'Speed', '90', headers);
      final f = splitCsv(result.split('\n')[2]);
      expect(f[0], 'Tom');
      expect(f[1], 'Brady');
      expect(f[2], 'QB');
      expect(f[3], '90');
    });

    test('all other lines in the text are unchanged', () {
      final result = setFieldInLine(sampleText, 2, 'Speed', '90', headers);
      final lines = result.split('\n');
      expect(lines[0], '#fname,lname,Position,Speed');
      expect(lines[1], 'Team = Bears    Players:2');
      expect(lines[3], 'Peyton,Manning,QB,72');
    });

    test('returns text unchanged for unknown column', () {
      final result = setFieldInLine(sampleText, 2, 'NonExistent', '99', headers);
      expect(result, sampleText);
    });

    test('returns text unchanged for out-of-range line index', () {
      final result = setFieldInLine(sampleText, 99, 'Speed', '99', headers);
      expect(result, sampleText);
    });
  });

  // ── swapLines ─────────────────────────────────────────────────────────────

  group('swapLines', () {
    test('swaps two lines correctly', () {
      const text = 'a\nb\nc';
      final result = swapLines(text, 0, 2);
      expect(result.split('\n'), ['c', 'b', 'a']);
    });

    test('returns text unchanged for invalid index', () {
      const text = 'a\nb';
      expect(swapLines(text, 0, 5), text);
    });
  });

  // ── parseActiveColumns ────────────────────────────────────────────────────

  group('parseActiveColumns', () {
    test('reads the # header line as the Key (actual file format)', () {
      // Line 1 of the real file: #Position,fname,lname,JerseyNumber,...
      const text = '#Position,fname,lname,JerseyNumber,Speed,\n'
          '\n'
          '# Uncomment line below\n'
          '# SET(0x9ACCC, 0x38060300)\n'
          '\n'
          'Team = Bears    Players:53\n'
          'QB,Tom,Brady,12,85,\n';
      final cols = parseActiveColumns(text);
      expect(cols, ['Position', 'fname', 'lname', 'JerseyNumber', 'Speed']);
    });

    test('ignores comment lines (# followed by space)', () {
      const text = '# This is a comment\n#Position,fname,lname,\n';
      final cols = parseActiveColumns(text);
      expect(cols, ['Position', 'fname', 'lname']);
    });

    test('handles optional #Key= prefix form', () {
      const text = '#Key=fname,lname,Position,Speed,\n';
      expect(parseActiveColumns(text), ['fname', 'lname', 'Position', 'Speed']);
    });

    test('trailing comma does not produce empty column', () {
      const text = '#Position,fname,lname,\n';
      final cols = parseActiveColumns(text);
      expect(cols, ['Position', 'fname', 'lname']);
      expect(cols, isNot(contains('')));
    });

    test('returns empty list when no key line found', () {
      const text = '# Only comments here\n# Another comment\n';
      expect(parseActiveColumns(text), isEmpty);
    });
  });

  // ── parseTeamBlocksForDisplay ─────────────────────────────────────────────

  group('parseTeamBlocksForDisplay', () {
    // Matches the actual file format: key on line 1, team names with Players:N
    const sampleText = '#Position,fname,lname,JerseyNumber,YearsPro\n'
        '\n'
        'Team = Bears    Players:53\n'
        'QB,Tom,Brady,12,7\n'
        'QB,Peyton,Manning,18,10\n'
        '\n'
        'Team = Packers    Players:53\n'
        'QB,Aaron,Rodgers,12,3\n';

    test('T-PARSE-05: extracts correct team count', () {
      final blocks = parseTeamBlocksForDisplay(sampleText);
      expect(blocks.length, 2);
    });

    test('team names strip the Players:N annotation', () {
      final blocks = parseTeamBlocksForDisplay(sampleText);
      expect(blocks[0].name, 'Bears');
      expect(blocks[1].name, 'Packers');
    });

    test('player counts per team are correct', () {
      final blocks = parseTeamBlocksForDisplay(sampleText);
      expect(blocks[0].players.length, 2);
      expect(blocks[1].players.length, 1);
    });

    test('player fields are correctly mapped', () {
      final blocks = parseTeamBlocksForDisplay(sampleText);
      final player = blocks[0].players[0];
      expect(player.firstName, 'Tom');
      expect(player.lastName, 'Brady');
      expect(player.position, 'QB');
      expect(player.jerseyNumber, '12');
    });

    test('lineIndex points to the correct line in textContent', () {
      final blocks = parseTeamBlocksForDisplay(sampleText);
      final player = blocks[0].players[0];
      // Line 0: #key, Line 1: blank, Line 2: Team = Bears, Line 3: Tom Brady
      expect(player.lineIndex, 3);
      // Line 4: Peyton Manning, Line 5: blank, Line 6: Team = Packers, Line 7: Aaron Rodgers
      expect(blocks[1].players[0].lineIndex, 7);
    });
  });

  // ── countTeamsAndPlayers ──────────────────────────────────────────────────

  group('countTeamsAndPlayers', () {
    test('returns correct team and player counts', () {
      const text = '#fname,lname\nTeam = Bears    Players:2\nTom,Brady\nPeyton,Manning\n'
          'Team = Packers    Players:1\nAaron,Rodgers\n';
      final (teams, players) = countTeamsAndPlayers(text);
      expect(teams, 2);
      expect(players, 3);
    });

    test('returns (0, 0) for empty text', () {
      final (teams, players) = countTeamsAndPlayers('');
      expect(teams, 0);
      expect(players, 0);
    });
  });

  // ── Real file integration ─────────────────────────────────────────────────

  group('Real file: Base2004Fran_Orig', () {
    late String fileText;

    setUpAll(() {
      fileText = File('test/test_files/Base2004Fran_Orig.output.ab.app.sch.txt')
          .readAsStringSync();
    });

    test('parseActiveColumns returns the full column list from line 1', () {
      final cols = parseActiveColumns(fileText);
      expect(cols, isNotEmpty);
      expect(cols.first, 'Position');
      expect(cols, contains('fname'));
      expect(cols, contains('lname'));
      expect(cols, contains('Speed'));
      expect(cols, contains('Photo'));
    });

    test('parseTeamBlocksForDisplay finds 32 teams', () {
      final blocks = parseTeamBlocksForDisplay(fileText);
      expect(blocks.length, 32);
    });

    test('first team is 49ers with 53 players', () {
      final blocks = parseTeamBlocksForDisplay(fileText);
      expect(blocks.first.name, '49ers');
      expect(blocks.first.players.length, 53);
    });

    test('first player of 49ers has correct fields', () {
      final blocks = parseTeamBlocksForDisplay(fileText);
      final p = blocks.first.players.first;
      expect(p.position, 'CB');
      expect(p.firstName, 'Ahmed');
      expect(p.lastName, 'Plummer');
      expect(p.jerseyNumber, '29');
    });

    test('player with quoted college (Miami, FL) parses correctly', () {
      final blocks = parseTeamBlocksForDisplay(fileText);
      final niners = blocks.first;
      final rumph = niners.players.firstWhere((p) => p.lastName == 'Rumph');
      expect(rumph.fields['College'], 'Miami, FL');
    });

    test('height with inch mark parses as single field', () {
      final blocks = parseTeamBlocksForDisplay(fileText);
      final niners = blocks.first;
      final plummer = niners.players.first;
      expect(plummer.fields['Height'], "6'0\"");
    });

    test('countTeamsAndPlayers returns 32 teams and 32*53 players', () {
      final (teams, players) = countTeamsAndPlayers(fileText);
      expect(teams, 32);
      expect(players, 32 * 53);
    });

    test('setFieldInLine on real player line: Speed edit roundtrips correctly', () {
      final blocks = parseTeamBlocksForDisplay(fileText);
      final cols = parseActiveColumns(fileText);
      final p = blocks.first.players.first; // Ahmed Plummer, Speed=90
      expect(p.fields['Speed'], '90');

      final updated = setFieldInLine(fileText, p.lineIndex, 'Speed', '99', cols);
      final reparse = parseTeamBlocksForDisplay(updated);
      final updatedPlayer = reparse.first.players.first;
      expect(updatedPlayer.fields['Speed'], '99');
      // All other fields unchanged
      expect(updatedPlayer.firstName, 'Ahmed');
      expect(updatedPlayer.fields['Height'], "6'0\"");
      expect(updatedPlayer.fields['College'], 'Ohio State');
    });
  });
}
