import 'package:nfl2k4tool_dart/nfl2k4tool_dart.dart' show DataMap;

/// A display entry for a mapped ID field (Photo or PBP).
class MappedEntry {
  final String id;   // numeric ID as string
  final String name; // display name
  const MappedEntry(this.id, this.name);
}

/// Photo ID → player name, parsed from ReversePhotoMap.
final List<MappedEntry> photoOptions = _getPhotoOptions();

String photoIdToDisplayName(String id) =>
    DataMap.ReversePhotoMap[id] ?? DataMap.ReversePhotoMap[id.padLeft(4, '0')] ?? '';

/// Returns the display name for a PBP ID using DataMap.ReversePBPMap.
String pbpIdToDisplayName(String id) =>
    DataMap.ReversePBPMap[id] ?? DataMap.ReversePBPMap[id.padLeft(4, '0')] ?? '';

// ─── Parsers ──────────────────────────────────────────────────────────────────

List<MappedEntry> _getPhotoOptions() {
  final map = DataMap.ReversePhotoMap;
  return map.entries.map((e) => MappedEntry(e.key, e.value)).toList();
}

