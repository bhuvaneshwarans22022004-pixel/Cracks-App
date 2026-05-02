import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'English';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  void setLanguage(String lang) async {
    _currentLanguage = lang;
    await StorageService.saveLanguage(lang);
    notifyListeners();
  }

  Future<void> _loadLanguage() async {
    _currentLanguage = await StorageService.getLanguage();
    notifyListeners();
  }
}
