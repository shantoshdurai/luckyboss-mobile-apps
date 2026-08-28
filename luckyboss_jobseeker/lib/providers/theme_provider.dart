import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light / dark / follow-system, persisted across launches.
///
/// Three states rather than a boolean, because "follow the system" is the
/// setting most people actually want and a toggle cannot express it. A phone on
/// a night schedule should darken the app without the candidate going to look
/// for a switch.
///
/// Stored locally rather than on the profile: it is a property of this device,
/// not of the person. Someone using the app on a tablet in daylight and a phone
/// at night wants different answers on each.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'luckyboss_theme_mode';

  /// Light by default. The dark palette is available and persists once chosen,
  /// but it is opt-in: following the system meant a candidate on a phone in
  /// night mode got a dark app they never asked for, on their first run, before
  /// they had seen the light one.
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  /// Label for the settings row.
  String get label => switch (_mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'Follow system',
      };

  /// Loads the stored preference.
  ///
  /// Failures fall back to system rather than throwing — a corrupt preference
  /// must not stop the app opening.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      _mode = switch (stored) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        // Anything else, including nothing stored, is light.
        _ => ThemeMode.light,
      };
      notifyListeners();
    } catch (_) {
      _mode = ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
      );
    } catch (_) {
      // The choice already applied in memory; failing to persist it is not
      // worth interrupting the user over.
    }
  }
}
