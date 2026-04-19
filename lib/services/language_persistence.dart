import 'package:shared_preferences/shared_preferences.dart';

class LanguagePersistence {
  static const String _languageKey = 'selected_language';

  // Save selected language
  static Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  // Get saved language (default to Kamayo)
  static Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'Kamayo';
    } catch (e) {
      print('Error getting language: $e');
      return 'Kamayo';
    }
  }

  // Clear saved language (if needed)
  static Future<void> clearLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
    } catch (e) {
      print('Error clearing language: $e');
    }
  }
}
