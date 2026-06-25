import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false;
  }

  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? 'English';
  }

  static Future<void> saveLastSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSelectedIndex', index);
  }

  static Future<int> getLastSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastSelectedIndex') ?? 0;
  }

  static Future<void> saveLastExploreCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastExploreCategory', category);
  }

  static Future<String> getLastExploreCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastExploreCategory') ?? 'All';
  }

  static Future<void> saveLastLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastLocation', location);
  }

  static Future<String?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastLocation');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
