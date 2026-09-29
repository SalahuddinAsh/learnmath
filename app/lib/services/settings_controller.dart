import 'package:flutter/foundation.dart';

import '../models/settings.dart';
import 'storage.dart';

/// App-wide settings, saved on every change — mirrors the web app's
/// `settings` global with loadSettings()/saveSettings().
class SettingsController extends ChangeNotifier {
  static const _key = "mathstars-settings";

  Settings _settings = Settings();
  Settings get settings => _settings;

  void load() {
    final json = Storage.getJson(_key);
    _settings = json != null ? Settings.fromJson(json) : Settings();
    notifyListeners();
  }

  /// Mutate, persist, notify — the "change settings.x, then refreshSetup()" pattern.
  void update(void Function(Settings s) mutator) {
    mutator(_settings);
    Storage.setJson(_key, _settings.toJson());
    notifyListeners();
  }
}
