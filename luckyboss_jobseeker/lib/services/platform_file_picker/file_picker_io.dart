import 'package:file_picker/file_picker.dart';

import 'raw_picked_file.dart';

/// Opens the system file chooser on Android, iOS, Windows, macOS and Linux.
///
/// `file_picker` is the right tool here — it is the web implementation that was
/// unreliable, and that path now goes through the DOM directly.
Future<RawPickedFile?> pickPlatformFile({
  required List<String> extensions,
}) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    // Bytes rather than a path: the caller stores the file itself, and a path
    // recorded on one install is not guaranteed valid after the next update.
    withData: true,
  );

  if (picked == null || picked.files.isEmpty) return null;

  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;

  return RawPickedFile(bytes: bytes, fileName: file.name);
}
