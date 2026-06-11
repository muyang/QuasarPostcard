import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/postcard_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const CardDesignerApp());
}

class CardDesignerApp extends StatelessWidget {
  const CardDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '明信片设计器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFFB794FF),
          surface: Color(0xFF1A1A2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E2E),
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A4A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF444444)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF444444)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF888888)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    if (ApiService.isAuthenticated) {
      final me = await ApiService.getMe();
      if (me == null || me['authenticated'] != true) {
        await ApiService.logout();
      }
    }
    // Auto-login for local web testing (skip WeChat OAuth)
    if (!ApiService.isAuthenticated && kIsWeb) {
      try {
        final origin = html.window.location.origin ?? '';
        if (origin.isNotEmpty) {
          final result = await ApiService.login('admin', 'postcard2024');
          if (result.success) {
            await ApiService.saveConfig(origin, result.token!);
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
      );
    }
    if (ApiService.isAuthenticated) {
      return const PostcardListScreen();
    }
    return const LoginScreen();
  }
}
