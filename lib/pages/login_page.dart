import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:myhome/providers/auth_provider.dart';
import '../core/session.dart';
import 'signup_page.dart';
import '../providers/home_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final success = await context.read<AuthProvider>().login(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await Session.setCurrentUser(username);
      context.read<HomeProvider>().initialize(username);
      return;
    }

    setState(() {
      _errorMessage = '아이디 또는 비밀번호가 옳지 않습니다.';
    });
  }

  Future<void> _navigateToSignUp() async {
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
    if (username != null && mounted) {
      await Session.setCurrentUser(username);
      Navigator.of(context).pop(username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '아이디'),
                validator: (value) => value == null || value.trim().isEmpty ? '아이디를 입력하세요.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? '비밀번호를 입력하세요.' : null,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitLogin,
                child: _isLoading ? const CircularProgressIndicator() : const Text('로그인'),
              ),
              TextButton(
                onPressed: _isLoading ? null : _navigateToSignUp,
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}