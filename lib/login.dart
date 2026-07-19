import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'couchdb.dart';
import 'const.dart';

typedef JsonMap = Map<String, dynamic>;

class Session {
  static const _key = 'currentUser';

  Session._();

  static Future<String?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key);
  }

  static Future<void> setCurrentUser(String username) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, username);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }

  static Future<String?> ensureLoggedIn(BuildContext context) async {
    final cur = await currentUser();
    if (cur != null && cur.isNotEmpty) return cur;
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (username != null && username.isNotEmpty) {
      await setCurrentUser(username);
      return username;
    }
    return null;
  }
}

class AuthRepository {
  AuthRepository._();

  static Future<void> ensureDatabase() async {
    await CouchDb.ensureDatabaseExists(userDB);
  }

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static Future<bool> signUp(String username, String password) async {
    await ensureDatabase();
    try {
      await CouchDb.createDocument(
        userDB,
        {
          'username': username,
          'passwordHash': hashPassword(password),
        },
        documentId: username,
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return false;
      }
      rethrow;
    }
  }

  static Future<bool> logIn(String username, String password) async {
    await ensureDatabase();
    try {
      final document = await CouchDb.getDocument(userDB, username);
      final savedHash = document['passwordHash']?.toString();
      return savedHash == hashPassword(password);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      rethrow;
    }
  }
}

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
    final success = await AuthRepository.logIn(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await Session.setCurrentUser(username);
      Navigator.of(context).pop(username);
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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final success = await AuthRepository.signUp(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await Session.setCurrentUser(username);
      Navigator.of(context).pop(username);
      return;
    }

    setState(() {
      _errorMessage = '이미 사용 중인 아이디입니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
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
                validator: (value) => value == null || value.length < 6 ? '6자 이상의 비밀번호를 입력하세요.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호 확인을 입력하세요.';
                  }
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
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
                onPressed: _isLoading ? null : _submitSignup,
                child: _isLoading ? const CircularProgressIndicator() : const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
