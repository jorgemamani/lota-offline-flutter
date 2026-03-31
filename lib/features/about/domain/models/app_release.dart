import 'release_note.dart';

class AppRelease {
  const AppRelease({
    required this.version,
    required this.notes,
  });

  final String version;
  final List<ReleaseNote> notes;
}
