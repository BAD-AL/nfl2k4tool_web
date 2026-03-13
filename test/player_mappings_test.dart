import 'package:test/test.dart';
import 'package:nfl2k5tool_web/data/player_mappings.dart';

void main() {
  group('photoOptions', () {
    test('non-empty list', () {
      expect(photoOptions, isNotEmpty);
    });

    test('first entry parses correctly (Abdullah, Khalid=5014)', () {
      final entry = photoOptions.first;
      expect(entry.id, equals('5014'));
      expect(entry.name, equals('Abdullah, Khalid'));
    });

    test('all entries have non-empty id and name', () {
      for (final e in photoOptions) {
        expect(e.id, isNotEmpty);
        expect(e.name, isNotEmpty);
      }
    });
  });

  group('pbpOptions', () {
    test('non-empty list', () {
      expect(pbpOptions, isNotEmpty);
    });

    test('first entry parses correctly (#00=9000)', () {
      final entry = pbpOptions.first;
      expect(entry.id, equals('9000'));
      expect(entry.name, equals('00'));
    });

    test('all entries have non-empty id and name', () {
      for (final e in pbpOptions) {
        expect(e.id, isNotEmpty);
        expect(e.name, isNotEmpty);
      }
    });
  });

  group('photoIdToDisplayName', () {
    test('known id returns correct name', () {
      expect(photoIdToDisplayName('5014'), equals('Abdullah, Khalid'));
    });

    test('unknown id returns empty string', () {
      expect(photoIdToDisplayName('99999'), equals(''));
    });
  });

  group('pbpIdToDisplayName', () {
    test('known id returns correct label', () {
      expect(pbpIdToDisplayName('9000'), equals('00'));
    });

    test('unknown id returns empty string', () {
      expect(pbpIdToDisplayName('99999'), equals(''));
    });
  });
}
