import 'package:test/test.dart';
import 'package:nfl2k4tool_web/data/player_data_cache.dart';

void main() {
  setUpAll(() {
    PlayerDataCache.ensureLoaded();
  });

  // T-PHOTO-02: getPhoto(validId) returns bytes starting with FF D8 FF (JPEG magic)
  test('T-PHOTO-02: getPhoto for a known ID returns JPEG bytes', () {
    final bytes = PlayerDataCache.getPhoto(4);
    expect(bytes, isNotNull);
    expect(bytes![0], equals(0xFF));
    expect(bytes[1], equals(0xD8));
    expect(bytes[2], equals(0xFF));
  });

  // T-PHOTO-03: getPhoto for unknown ID returns null
  test('T-PHOTO-03: getPhoto(99999) returns null', () {
    expect(PlayerDataCache.getPhoto(99999), isNull);
  });

  // T-PHOTO-04: allPhotoIds is sorted ascending
  test('T-PHOTO-04: allPhotoIds is sorted ascending', () {
    final ids = PlayerDataCache.allPhotoIds;
    expect(ids, isNotEmpty);
    for (int i = 1; i < ids.length; i++) {
      expect(ids[i], greaterThan(ids[i - 1]));
    }
  });

  // T-PHOTO-05: faceCategories has expected keys
  test('T-PHOTO-05: faceCategories has expected category keys', () {
    final cats = PlayerDataCache.faceCategories;
    expect(cats.keys, containsAll(['darkPlayers', 'mediumPlayers', 'lightPlayers', 'Dreads', 'darkBald', 'lightBald']));
  });

  // T-PHOTO-06: photoIdsForCategory('darkPlayers') is non-empty
  test('T-PHOTO-06: photoIdsForCategory("darkPlayers") returns a non-empty list', () {
    final ids = PlayerDataCache.photoIdsForCategory('darkPlayers');
    expect(ids, isNotEmpty);
  });

  // T-PHOTO-07: ID 4 is present (file PlayerPhotos/0004.jpg in the ZIP)
  test('T-PHOTO-07: ID 4 resolves to a valid photo', () {
    expect(PlayerDataCache.getPhoto(4), isNotNull);
    expect(PlayerDataCache.allPhotoIds, contains(4));
  });

  // Missing category returns empty list
  test('photoIdsForCategory for unknown category returns empty list', () {
    expect(PlayerDataCache.photoIdsForCategory('nonExistentCategory'), isEmpty);
  });
}
