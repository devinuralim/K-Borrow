import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../main.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;

  final Color primaryNavy = const Color(0xFF1d3557);
  final Color secondaryBlue = const Color(0xFF457b9d);
  final Color accentBlue = const Color(0xFFa8dadc);
  final Color darkBg = const Color(0xFF0F172A);
  final Color darkCard = const Color(0xFF1E293B);

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF6F8FC);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : primaryNavy;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade600;
  Color get borderColor => isDarkMode ? Colors.white10 : Colors.grey.shade200;
  Color get inputFillColor =>
      isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/v1/change-password"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "old_password": oldPasswordController.text,
          "new_password": newPasswordController.text,
          "new_password_confirmation": confirmPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Password berhasil diganti'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal mengganti password'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengganti password"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildSecurityCard(),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              controller: oldPasswordController,
                              label: "Password Lama",
                              icon: Icons.lock_outline_rounded,
                              obscureText: hideOld,
                              onToggle: () {
                                setState(() {
                                  hideOld = !hideOld;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password lama wajib diisi";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 13),
                            _buildPasswordField(
                              controller: newPasswordController,
                              label: "Password Baru",
                              icon: Icons.lock_reset_rounded,
                              obscureText: hideNew,
                              onToggle: () {
                                setState(() {
                                  hideNew = !hideNew;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password baru wajib diisi";
                                }
                                if (value.length < 6) {
                                  return "Password minimal 6 karakter";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 13),
                            _buildPasswordField(
                              controller: confirmPasswordController,
                              label: "Konfirmasi Password",
                              icon: Icons.verified_user_rounded,
                              obscureText: hideConfirm,
                              onToggle: () {
                                setState(() {
                                  hideConfirm = !hideConfirm;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Konfirmasi password wajib diisi";
                                }
                                if (value != newPasswordController.text) {
                                  return "Konfirmasi password tidak sama";
                                }
                                return null;
                              },
                            ),
                            const Spacer(),
                            _buildSaveButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(100),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: textColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Keamanan Akun",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : primaryNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Perbarui password akun kamu",
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      height: 116,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [darkCard, const Color(0xFF111827)]
              : [primaryNavy, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(isDarkMode ? 0.12 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -22,
            child: Icon(
              Icons.lock_reset_rounded,
              size: 105,
              color: Colors.white.withOpacity(0.09),
            ),
          ),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Gunakan password yang kuat dan jangan bagikan ke siapa pun.",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryNavy.withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey("loading"),
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  key: ValueKey("save"),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Simpan Password",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: subTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? accentBlue : primaryNavy,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: subTextColor,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDarkMode ? accentBlue : primaryNavy,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
