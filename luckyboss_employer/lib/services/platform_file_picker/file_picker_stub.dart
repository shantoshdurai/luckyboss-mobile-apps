import 'raw_picked_file.dart';

/// Opens the platform's file chooser.
///
/// Returns null when the user backed out. Throws when the picker itself could
/// not be opened, so the caller can tell "changed my mind" from "this is
/// broken" — the two need very different messages.
///
/// Implemented per platform via conditional import. This stub exists only to
/// satisfy analysis on platforms neither implementation covers.
Future<RawPickedFile?> pickPlatformFile({
  required List<String> extensions,
}) async {
  throw UnsupportedError('No file picker on this platform.');
}
