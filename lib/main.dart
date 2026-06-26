import 'dart:html' as html;
import 'theme/app_colors.dart';

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
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
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
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          labelStyle: const TextStyle(color: AppColors.textLabel),
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
    // Auto-login for local web testing only (skip WeChat OAuth).
    // Credentials come from --dart-define flags, never hardcoded.
    if (!ApiService.isAuthenticated && kIsWeb) {
      final autoUser = String.fromEnvironment('AUTO_LOGIN_USER');
      final autoPass = String.fromEnvironment('AUTO_LOGIN_PASS');
      if (autoUser.isNotEmpty && autoPass.isNotEmpty) {
        try {
          final origin = html.window.location.origin ?? '';
          if (origin.isNotEmpty) {
            final result = await ApiService.login(autoUser, autoPass);
            if (result.success) {
              await ApiService.saveConfig(origin, result.token!);
            }
          }
        } catch (_) {}
      }
    }
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (ApiService.isAuthenticated) {
      return const PostcardListScreen();
    }
    return const LoginScreen();
  }
}
