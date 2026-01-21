import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ppb.png',
              width: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'BLANGKIS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'UMKM Desa Pakis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
