import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  State<NotificationScreen> createState() {
    return _NotificationScreenState();
  }
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF8FAFC);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : primaryBlue;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade600;
  Color get borderColor => isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

  void initState() {
    super.initState();
    _loadFcmNotifications();
  }

  Future<void> _loadFcmNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getStringList('fcm_notifications') ?? [];

      final List<Map<String, dynamic>> data = [];

      for (final item in savedData) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            data.add(Map<String, dynamic>.from(decoded));
          }
        } catch (e) {
          debugPrint("Notif decode error: $e");
        }
      }

      if (!mounted) return;

      setState(() {
        notifications = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Load notification error: $e");

      if (!mounted) return;

      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  }

  Future<void> _clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_notifications');

      if (!mounted) return;

      setState(() {
        notifications.clear();
      });
    } catch (e) {
      debugPrint("Clear notification error: $e");
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '';

    try {
      final date = DateTime.parse(value).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    } catch (e) {
      return '';
    }
  }

  String _safeText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text("Notifikasi"),
            backgroundColor: isDarkMode ? darkCard : primaryBlue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadFcmNotifications,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _clearNotifications,
              ),
            ],
          ),
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? accentBlue : primaryBlue,
                  ),
                )
              : notifications.isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada notifikasi.",
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFcmNotifications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];

                          final title = _safeText(
                            item['title'],
                            'Notifikasi',
                          );

                          final body = _safeText(
                            item['body'],
                            'Tidak ada isi notifikasi.',
                          );

                          final createdAt =
                              _formatDate(item['created_at']?.toString());

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDarkMode ? 0.25 : 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: cardColor,
                                      title: Text(
                                        title,
                                        style: TextStyle(color: textColor),
                                      ),
                                      content: Text(
                                        createdAt.isEmpty
                                            ? body
                                            : "$body\n\n$createdAt",
                                        style: TextStyle(color: subTextColor),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Tutup"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    isDarkMode ? accentBlue : primaryBlue,
                                child: Icon(
                                  Icons.notifications_active,
                                  color:
                                      isDarkMode ? primaryBlue : Colors.white,
                                ),
                              ),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  createdAt.isEmpty
                                      ? body
                                      : "$body\n$createdAt",
                                  style: TextStyle(
                                    color: subTextColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}