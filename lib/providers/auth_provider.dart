import 'package:flutter/material.dart';
import '../core/session.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {

  Future<bool> login(
    String id,
    String password,
  ) async {

    final ok =
        await AuthRepository.logIn(
          id,
          password,
        );

    if (ok) {
      await Session.setCurrentUser(id);
    }

    return ok;
  }

  Future<bool> signUp(
    String id,
    String password,
  ) async {

    final ok =
        await AuthRepository.signUp(
          id,
          password,
        );

    if (ok) {
      await Session.setCurrentUser(id);
    }

    return ok;
  }
}