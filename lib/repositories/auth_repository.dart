
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../core/couchdb.dart';
import '../core/const.dart';

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
