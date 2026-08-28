/// @docImport 'file_picker_web.dart';
library;

/// One file chooser, two implementations.
///
/// Web goes straight to an `<input type="file">`; everything else uses
/// `file_picker`. See `file_picker_web.dart` for why the plugin is not trusted
/// on web.
///
/// **`dart.library.io` is tested first, and the order matters.** `dart:js_interop`
/// resolves on the Dart VM too, so putting the web condition first selected the
/// browser implementation when running tests — which then failed to compile
/// because `package:web` has no VM implementation.
export 'raw_picked_file.dart';
export 'file_picker_stub.dart'
    if (dart.library.io) 'file_picker_io.dart'
    if (dart.library.js_interop) 'file_picker_web.dart';
