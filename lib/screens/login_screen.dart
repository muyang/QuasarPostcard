import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'postcard_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _serverController = TextEditingController(text: 'http://127.0.0.1:8100');
  final _userController = TextEditingController(text: 'admin');
  final _passController = TextEditingController(text: 'postcard2024');
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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _serverController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() { _loading = true; _error = null; });

    final serverUrl = _serverController.text.trim();
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (serverUrl.isEmpty) {
      setState(() { _error = '请输入服务器地址'; _loading = false; });
      return;
    }

    await ApiService.saveConfig(serverUrl, '');
    final result = await ApiService.login(username, password);

    if (!mounted) return;

    if (result.success) {
      await ApiService.saveConfig(serverUrl, result.token!);
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
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D0D1A), Color(0xFF13132B), Color(0xFF1A1A2E)]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: FadeTransition(
                opacity: _fade,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF9B7BFF)]), boxShadow: [BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.3), blurRadius: 20)]),
                    child: const Icon(Icons.mail_rounded, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('明信片设计器', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  const Text('设计属于你的明信片，寄出一份心意', style: TextStyle(fontSize: 13, color: Color(0xFF666688))),
                  const SizedBox(height: 44),
                  _buildField(controller: _serverController, label: '服务器地址', hint: 'http://192.168.1.161:8100', icon: Icons.dns_outlined),
                  const SizedBox(height: 14),
                  _buildField(controller: _userController, label: '用户名', hint: 'admin', icon: Icons.person_outline),
                  const SizedBox(height: 14),
                  _buildField(controller: _passController, label: '密码', hint: '••••••••', icon: Icons.lock_outline, obscure: true),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withOpacity(0.2))), child: Row(children: [const Icon(Icons.info_outline, size: 16, color: Colors.redAccent), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)))])),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _connect,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF2A2A4A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('连接服务器', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: obscure ? null : TextInputType.url,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C4DFF))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
