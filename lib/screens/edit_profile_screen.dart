import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../main.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final noWaController = TextEditingController();
  final alamatController = TextEditingController();

  File? selectedImage;
  bool isLoading = false;

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
  Color get readOnlyFillColor =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE8EEF5);

  void initState() {
    super.initState();

    emailController.text = widget.userData?['email']?.toString() ?? '';
    noWaController.text = widget.userData?['no_wa']?.toString() ?? '';
    alamatController.text = widget.userData?['alamat']?.toString() ?? '';
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await AuthService.getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${AppConfig.baseUrl}/v1/profile/update"),
      );

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      request.fields['_method'] = 'PUT';
      request.fields['email'] = emailController.text.trim();
      request.fields['no_wa'] = noWaController.text.trim();
      request.fields['alamat'] = alamatController.text.trim();

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_profile',
            selectedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal update profil'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal update profil"),
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
    emailController.dispose();
    noWaController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  ImageProvider? _getProfileImage(String fotoUrl) {
    if (selectedImage != null) {
      return FileImage(selectedImage!);
    }

    if (fotoUrl.isNotEmpty && fotoUrl.startsWith('http')) {
      return NetworkImage(fotoUrl);
    }

    return null;
  }

  Widget build(BuildContext context) {
    final String name = widget.userData?['name']?.toString() ?? '-';
    final String idPegawai = widget.userData?['id_pegawai']?.toString() ?? '-';
    final String jabatan = widget.userData?['jabatan']?.toString() ?? 'Pegawai';
    final String fotoUrl = widget.userData?['foto_profile']?.toString() ?? '';

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: bgColor,
          resizeToAvoidBottomInset: true,
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 14),
                      _buildProfilePhoto(name, jabatan, fotoUrl),
                      const SizedBox(height: 14),
                      _buildLockedInfo(idPegawai, jabatan),
                      const SizedBox(height: 14),
                      _buildEditPanel(name),
                      const SizedBox(height: 14),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
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
          child: Text(
            "Edit Profil",
            style: TextStyle(
              color: textColor,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhoto(String name, String jabatan, String fotoUrl) {
    final imageProvider = _getProfileImage(fotoUrl);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 102,
              height: 102,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryNavy, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryNavy.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: cardColor,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 54,
                        color: isDarkMode ? accentBlue : primaryNavy,
                      )
                    : null,
              ),
            ),
            InkWell(
              onTap: pickImage,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNavy, secondaryBlue],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: bgColor, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Foto, email, WhatsApp, dan alamat bisa diperbarui",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedInfo(String idPegawai, String jabatan) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [darkCard, const Color(0xFF111827)]
              : [primaryNavy, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _lockedMiniItem(
              "ID Pegawai",
              idPegawai,
              Icons.badge_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withOpacity(0.18),
          ),
          Expanded(
            child: _lockedMiniItem(
              "Jabatan",
              jabatan,
              Icons.work_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedMiniItem(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditPanel(String name) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _readOnlyInfo(
            label: "Nama Lengkap",
            value: name,
            icon: Icons.person_rounded,
          ),
          _divider(),
          _buildInputField(
            controller: emailController,
            label: "Email",
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null &&
                  value.trim().isNotEmpty &&
                  !value.contains('@')) {
                return "Email tidak valid";
              }
              return null;
            },
          ),
          const SizedBox(height: 11),
          _buildInputField(
            controller: noWaController,
            label: "No WhatsApp",
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 11),
          _buildInputField(
            controller: alamatController,
            label: "Alamat",
            icon: Icons.location_on_rounded,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _readOnlyInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: subTextColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$label • tidak bisa diubah",
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.lock_rounded,
          color: subTextColor,
          size: 17,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: subTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? accentBlue : primaryNavy,
          size: 20,
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: isDarkMode ? accentBlue : primaryNavy,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : updateProfile,
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
                      "Simpan Perubahan",
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

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: borderColor,
      ),
    );
  }
}
