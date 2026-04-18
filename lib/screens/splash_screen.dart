import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    // Jeda 2 detik supaya transisi ke aplikasi terasa halus
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    final token = await AuthService.getToken();

    // 1. Jika tidak ada token (Belum login)
    if (token == null || token.isEmpty) {
      _goToLogin();
      return;
    }

    // 2. Cek validitas token ke server
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/barang'), 
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5)); // Timeout 5 detik agar tidak terlalu lama

      if (response.statusCode == 200) {
        _goToHome();
      } else {
        await AuthService.logout();
        _goToLogin();
      }
    } catch (e) {
      // Jika koneksi error, asumsikan masuk saja dulu ke Home
      // (Nanti di Home akan handle error saat fetch data dashboard)
      debugPrint("Koneksi Error di Splash: $e");
      _goToHome(); 
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Efek pudar (Fade) agar perpindahan ke login terasa smooth
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Efek pudar (Fade) agar perpindahan ke beranda terasa smooth
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1d3557);
    const accentBlue = Color(0xFFa8dadc); // Accent blue dari tema Beranda

    return Scaffold(
      backgroundColor: primaryNavy,
      body: Stack(
        children: [
          // LOADING DI BAWAH (MINIMALIS)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0), // Jarak dari bawah layar
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: accentBlue, // Spinner pakai warna accent agar senada
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "K-BORROW v1.0",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}