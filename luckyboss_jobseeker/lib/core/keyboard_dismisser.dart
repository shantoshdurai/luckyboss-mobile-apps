import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Puts the keyboard away whenever the app changes screen.
///
/// Shantosh, twice now: *"the keyboard typing layout is coming all the way in
/// next screens too, in job seeker and portal."*
///
/// I fixed this per screen the first time — unfocus in the wizard's `_next`,
/// unfocus in `_back` — and that was the wrong shape of fix. There are dozens
/// of navigation points across both apps and every new one starts out broken.
/// Flutter keeps the platform keyboard open across a route change because
/// nothing tells it otherwise: the focus node on the screen you left is still
/// the primary focus, so the keyboard has no reason to close.
///
/// A navigator observer catches every push, pop and replace in one place,
/// including the ones nobody remembers to think about — a dialog opening over a
/// half-filled form, a deep link, the system back gesture.
///
/// [SystemChannels.textInput] is asked to hide as well as dropping focus.
/// Unfocusing alone is usually enough, but on Android a route that is torn down
/// mid-frame can lose the focus node before the platform is told, and the
/// keyboard stays up over the new screen with nothing behind it.
class KeyboardDismisser extends NavigatorObserver {
  void _dismiss() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;
    focus.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismiss();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
    super.didRemove(route, previousRoute);
  }
}
