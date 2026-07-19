import 'package:shared_preferences/shared_preferences.dart';

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
}