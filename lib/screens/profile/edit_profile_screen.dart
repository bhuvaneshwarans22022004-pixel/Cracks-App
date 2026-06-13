import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';

enum ChangePasswordState {
  sendOtp,
  verifyOtp,
  resetPassword,
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final filename = image.name;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploading profile picture..."), duration: Duration(seconds: 2)),
        );
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.uploadAndSaveProfileImage(bytes, filename);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated successfully!"), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image. Please try again."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Image picking/upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking/uploading image: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    ChangePasswordState state = ChangePasswordState.sendOtp;
    final emailController = TextEditingController(text: user?.email);
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final sendOtpFormKey = GlobalKey<FormState>();
    final verifyOtpFormKey = GlobalKey<FormState>();
    final resetPasswordFormKey = GlobalKey<FormState>();
    Timer? countdownTimer;
    int secondsRemaining = 30;
    bool canResend = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final authProvider = Provider.of<AuthProvider>(context);
            final isDialogLoading = authProvider.isLoading;

            void startTimer() {
              setDialogState(() {
                secondsRemaining = 30;
                canResend = false;
              });
              countdownTimer?.cancel();
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (secondsRemaining == 0) {
                  setDialogState(() {
                    canResend = true;
                    countdownTimer?.cancel();
                  });
                } else {
                  setDialogState(() {
                    secondsRemaining--;
                  });
                }
              });
            }

            Widget content;
            List<Widget> actions;
            String titleText;

            if (state == ChangePasswordState.sendOtp) {
              titleText = "Change Password";
              content = Form(
                key: sendOtpFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "To change your password, enter your desired email address. We will send a 6-digit OTP verification code to verify your identity.",
                      style: TextStyle(color: Colors.black87, fontSize: 14, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Email Address",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "example@gmail.com",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your email";
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return "Please enter a valid email address";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              );
              actions = [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (sendOtpFormKey.currentState!.validate()) {
                            final email = emailController.text.trim();
                            final success = await authProvider.forgotPassword(email);
                            if (success) {
                              startTimer();
                              setDialogState(() {
                                state = ChangePasswordState.verifyOtp;
                              });
                            } else {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to send OTP. Please check the email and try again."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isDialogLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Send OTP"),
                ),
              ];
            } else if (state == ChangePasswordState.verifyOtp) {
              titleText = "Verify OTP";
              content = Form(
                key: verifyOtpFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter the 6-digit verification code sent to ${emailController.text.trim()}:",
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "000000",
                        counterText: "",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) async {
                        if (val.trim().length == 6) {
                          final email = emailController.text.trim();
                          if (email.isNotEmpty) {
                            final success = await authProvider.verifyOTP(email, val.trim());
                            if (success) {
                              setDialogState(() {
                                state = ChangePasswordState.resetPassword;
                              });
                            } else {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text("Invalid or expired OTP. Please try again."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter OTP";
                        if (value.trim().length != 6) return "OTP must be 6 digits";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          canResend ? "Didn't receive code?" : "Resend in ${secondsRemaining}s",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        TextButton(
                          onPressed: canResend && !isDialogLoading
                              ? () async {
                                  final email = emailController.text.trim();
                                  if (email.isNotEmpty) {
                                    final success = await authProvider.forgotPassword(email);
                                    if (success) {
                                      startTimer();
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text("OTP resent successfully!"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          child: Text(
                            "Resend",
                            style: TextStyle(
                              color: canResend ? const Color(0xFFFF8C00) : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              actions = [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (verifyOtpFormKey.currentState!.validate()) {
                            final email = emailController.text.trim();
                            if (email.isNotEmpty) {
                              final success = await authProvider.verifyOTP(email, otpController.text.trim());
                              if (success) {
                                setDialogState(() {
                                  state = ChangePasswordState.resetPassword;
                                });
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text("Invalid or expired OTP. Please try again."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        },
                  child: isDialogLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Verify"),
                ),
              ];
            } else {
              titleText = "Create New Password";
              content = Form(
                key: resetPasswordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("New Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Enter new password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter new password";
                        if (value.length < 6) return "Password must be at least 6 characters";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Confirm New Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Confirm new password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please confirm new password";
                        if (value != newPasswordController.text) return "Passwords do not match";
                        return null;
                      },
                    ),
                  ],
                ),
              );
              actions = [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (resetPasswordFormKey.currentState!.validate()) {
                            final email = emailController.text.trim();
                            if (email.isNotEmpty) {
                              final success = await authProvider.resetPassword(
                                email,
                                otpController.text.trim(),
                                newPasswordController.text.trim(),
                              );
                              if (success) {
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text("Password changed successfully!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text("Reset failed. Please try requesting a new OTP."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        },
                  child: isDialogLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Update Password"),
                ),
              ];
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(child: content),
              actions: actions,
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfile(
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to update profile. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isLoading = authProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : _pickAndUploadImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFFFF8C00).withOpacity(0.08),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: const Color(0xFFFF8C00),
                              backgroundImage: (user?.profileImage != null && user!.profileImage!.isNotEmpty)
                                  ? NetworkImage(user.profileImage!)
                                  : null,
                              child: (user?.profileImage == null || user!.profileImage!.isEmpty)
                                  ? const Icon(Icons.person, size: 56, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFFFD700),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Full Name",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Enter your full name",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your name";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Phone Number",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Enter your phone number",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your phone number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.vpn_key_outlined, color: Color(0xFFFF8C00)),
                    label: const Text("Change Password", style: TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFFFF8C00)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save Changes",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
