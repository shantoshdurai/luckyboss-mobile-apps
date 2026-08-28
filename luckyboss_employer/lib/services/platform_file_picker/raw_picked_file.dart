import 'package:flutter/foundation.dart';

/// A file chosen by the platform picker.
///
/// Lives in its own file so the barrel can export it unconditionally. When it
/// sat in the stub, only the stub exported it — and the stub is exactly the
/// file that is never chosen, so the type vanished from every real build.
class RawPickedFile {
  final Uint8List bytes;
  final String fileName;

  const RawPickedFile({required this.bytes, required this.fileName});
}
