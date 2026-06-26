import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/wechat_auth_service.dart';
import 'postcard_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WechatAuthService.prefetchConfig();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _wechatLogin() async {
    setState(() { _loading = true; _error = null; });

    final result = await WechatAuthService.login();

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PostcardListScreen()));
    } else {
      setState(() { _error = result.error ?? '登录失败'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.background, AppColors.panelDark, AppColors.surface]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: FadeTransition(
                opacity: _fade,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.wechatGreen, AppColors.wechatGreenLight]), boxShadow: [BoxShadow(color: AppColors.wechatGreen.withOpacity(0.25), blurRadius: 24)]),
                    child: const Icon(Icons.mail_rounded, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text('明信片设计器', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  const Text('设计属于你的明信片，寄出一份心意', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 48),
                  if (_error != null) ...[
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withOpacity(0.2))), child: Row(children: [const Icon(Icons.info_outline, size: 16, color: Colors.redAccent), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)))])),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _wechatLogin,
                      icon: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.wechat, color: Colors.white, size: 24),
                      label: const Text('微信登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wechatGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.wechatGreenDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('首次登录需要通过微信认证', style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
