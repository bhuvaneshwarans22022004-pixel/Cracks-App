import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

/// Shown after login when the user's name is missing or is the generic placeholder.
/// Non-dismissible — user MUST enter a real name to continue.
class NameCaptureSheet extends StatefulWidget {
  final VoidCallback onCompleted;

  const NameCaptureSheet({super.key, required this.onCompleted});

  /// Show the sheet. Call this right after a successful login when the name
  /// is still 'FestiveKart User' or empty.
  static void showIfNeeded(BuildContext context, {required String? currentName, required VoidCallback onCompleted}) {
    final isGeneric = currentName == null ||
        currentName.isEmpty ||
        currentName.trim() == 'FestiveKart User';

    if (!isGeneric) return; // name is already real — nothing to do

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: false,
        child: NameCaptureSheet(onCompleted: onCompleted),
      ),
    );
  }

  @override
  State<NameCaptureSheet> createState() => _NameCaptureSheetState();
}

class _NameCaptureSheetState extends State<NameCaptureSheet> {
  final _nameController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.updateProfile(
        name,
        auth.user?.phone ?? '',
        email: auth.user?.email,
      );

      if (success && mounted) {
        Navigator.pop(context);
        widget.onCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, $name! 🎉'),
            backgroundColor: const Color(0xFFFF9F1C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save name: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF0F041C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFFF9F1C), width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handlebar
            Center(
              child: Container(
                width: 48,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            const Center(
              child: Text('👋', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'What should we call you?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Enter your name so we can personalise your orders and delivery updates.',
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Name input
            TextField(
              controller: _nameController,
              autofocus: true,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFFF9F1C)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF9F1C), width: 1.8),
                ),
              ),
              onSubmitted: (_) => _saveName(),
            ),
            const SizedBox(height: 20),

            // Continue button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9F1C),
                  foregroundColor: const Color(0xFF1E0A35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _loading ? null : _saveName,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E0A35)),
                      )
                    : Text(
                        'Continue',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
