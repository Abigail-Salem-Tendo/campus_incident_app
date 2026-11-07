import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the Light/Dark choice and saves it on the device.
/// The saved value is read once, before the app starts (see main.dart),
/// so the right theme shows from the very first frame.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider._(this._prefs, this._mode);

  static const _storageKey = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _mode;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Reads the saved choice. Light is the default when nothing is saved.
  static Future<ThemeProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    final mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    return ThemeProvider._(prefs, mode);
  }

  /// Applies the new theme right away, then saves it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(
      _storageKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
