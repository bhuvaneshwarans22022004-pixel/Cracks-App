import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'cms_content_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text("Push Notifications"),
            trailing: Switch(
              value: true, 
              onChanged: (val) {
                // Future implementation for notifications
              },
              activeColor: const Color(0xFFFF8C00),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text("Language"),
            subtitle: Text(langProvider.currentLanguage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, langProvider),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(),
              activeColor: const Color(0xFFFF8C00),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About Us"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CmsContentScreen(
                  title: "About Us",
                  contentType: "about_us",
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Privacy Policy"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CmsContentScreen(
                  title: "Privacy Policy",
                  contentType: "privacy_policy",
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Support"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CmsContentScreen(
                  title: "Help & Support",
                  contentType: "help_support",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(context, provider, "English"),
            _languageOption(context, provider, "Hindi"),
            _languageOption(context, provider, "Tamil"),
            _languageOption(context, provider, "Telugu"),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext context, LanguageProvider provider, String lang) {
    return ListTile(
      title: Text(lang),
      trailing: provider.currentLanguage == lang 
          ? const Icon(Icons.check, color: Color(0xFFFF8C00)) 
          : null,
      onTap: () {
        provider.setLanguage(lang);
        Navigator.pop(context);
      },
    );
  }
}
