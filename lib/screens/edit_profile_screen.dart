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
  final Color darkBg = const Color(0xFF0F172A);
  final Color darkCard = const Color(0xFF1E293B);

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF1F5F9);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade700;
  Color get borderColor => isDarkMode ? Colors.white10 : Colors.grey.shade300;
  Color get inputFillColor =>
      isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get readOnlyFillColor =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
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
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal update profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: Colors.red,
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
          appBar: AppBar(
            title: const Text(
              "Edit Profil",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isDarkMode ? darkCard : primaryNavy,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 58,
                            backgroundColor: isDarkMode
                                ? const Color(0xFF334155)
                                : primaryNavy.withOpacity(0.12),
                            child: CircleAvatar(
                              radius: 53,
                              backgroundColor: cardColor,
                              backgroundImage: _getProfileImage(fotoUrl),
                              child: _getProfileImage(fotoUrl) == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 60,
                                      color: isDarkMode
                                          ? Colors.white
                                          : primaryNavy,
                                    )
                                  : null,
                            ),
                          ),
                          InkWell(
                            onTap: pickImage,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: primaryNavy,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cardColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      _buildReadOnlyField(
                        label: "Nama Lengkap",
                        value: name,
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 14),

                      _buildReadOnlyField(
                        label: "ID Pegawai",
                        value: idPegawai,
                        icon: Icons.badge_rounded,
                      ),
                      const SizedBox(height: 14),

                      _buildReadOnlyField(
                        label: "Jabatan",
                        value: jabatan,
                        icon: Icons.work_rounded,
                      ),
                      const SizedBox(height: 18),

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
                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: noWaController,
                        label: "No WhatsApp",
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: alamatController,
                        label: "Alamat",
                        icon: Icons.location_on_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primaryNavy.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Simpan Perubahan",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.white : primaryNavy,
        ),
        filled: true,
        fillColor: readOnlyFillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryNavy),
        ),
      ),
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
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.white : primaryNavy,
        ),
        filled: true,
        fillColor: inputFillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}