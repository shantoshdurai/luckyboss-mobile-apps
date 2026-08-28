import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'raw_picked_file.dart';

/// Opens a file chooser in the browser, without a plugin.
///
/// The `file_picker` plugin is what this replaces on web, and it replaced it
/// because it did not work: Shantosh's browser answered *"Could not open the
/// file picker on this device"* every time, which is this app's message for the
/// plugin throwing. Before that, `image_picker`'s gallery path opened nothing
/// at all. Two plugins, two silent failures, on the one platform where the
/// underlying primitive is four lines of DOM.
///
/// So the primitive is used directly. An `<input type="file">` clicked from
/// inside the user's tap is the oldest, most reliable file affordance the web
/// has; the browser's own dialog also accepts a file dragged into it, which
/// covers picking a photo off a desktop.
///
/// Two details that matter and are easy to get wrong:
///
/// * **The element must be in the document.** Safari and some Chromium builds
///   ignore `.click()` on a detached input. It is appended, hidden, and removed
///   in a `finally`.
/// * **There is no cancel event.** `change` fires on selection and never fires
///   if the dialog is dismissed. `cancel` is supported in recent browsers but
///   not everywhere, so both are listened for and the future is completed by
///   whichever arrives — otherwise a cancelled pick would hang forever behind a
///   spinner.
Future<RawPickedFile?> pickPlatformFile({
  required List<String> extensions,
}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = false
    ..accept = extensions.map((e) => '.$e').join(',')
    ..style.display = 'none';

  web.document.body?.appendChild(input);

  final completer = Completer<RawPickedFile?>();

  // Set the moment a file is chosen, before it has finished reading. The
  // focus-based cancel fallback below must not fire while a large file is still
  // being read off disk — that would report a cancel for a pick that is about
  // to succeed.
  var choosing = false;

  void finish(RawPickedFile? result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  input.onchange = (web.Event _) {
    choosing = true;
    final files = input.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      finish(null);
      return;
    }

    final reader = web.FileReader();
    reader.onload = (web.Event _) {
      final result = reader.result;
      if (result == null) {
        finish(null);
        return;
      }
      final buffer = (result as JSArrayBuffer).toDart;
      finish(RawPickedFile(
        bytes: buffer.asUint8List(),
        fileName: file.name,
      ));
    }.toJS;
    reader.onerror = ((web.Event _) => finish(null)).toJS;
    reader.readAsArrayBuffer(file);
  }.toJS;

  // Fires when the dialog is dismissed, where the browser supports it.
  input.oncancel = ((web.Event _) => finish(null)).toJS;

  try {
    input.click();
    // A dismissed dialog in a browser without `cancel` support leaves nothing
    // to wait on. The window regaining focus is the signal that the dialog has
    // closed one way or the other; give the change event a moment to land
    // first, then treat silence as a cancel.
    late final JSFunction onFocus;
    onFocus = ((web.Event _) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!choosing) finish(null);
      });
      web.window.removeEventListener('focus', onFocus);
    }).toJS;
    web.window.addEventListener('focus', onFocus);

    return await completer.future;
  } finally {
    // Detach only once the bytes are in hand. Removing the element while its
    // FileReader is still running is what would truncate a large pick.
    input.remove();
  }
}

