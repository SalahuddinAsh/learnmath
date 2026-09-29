import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin JSON wrapper over SharedPreferences, standing in for the web app's
/// localStorage.getItem/setItem(JSON.stringify(...)) calls.
class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Object? _get(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? getJson(String key) {
    final v = _get(key);
    return v is Map<String, dynamic> ? v : null;
  }

  static List<dynamic>? getJsonList(String key) {
    final v = _get(key);
    return v is List ? v : null;
  }

  static void setJson(String key, Object value) {
    _prefs?.setString(key, jsonEncode(value));
  }
}
