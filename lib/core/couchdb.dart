import 'dart:convert';

import 'package:dio/dio.dart';

import 'secrets.dart';

import 'const.dart';

typedef JsonMap = Map<String, dynamic>;


class CouchDb {
  CouchDb._();

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: couchdbUrl,
    headers: {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$couchdbUser:$couchdbPassword'))}',
      'Content-Type': 'application/json',
    },
  ));

  static String _dbPath(String dbName) => '/$dbName';

  static Future<void> ensureDatabaseExists(String dbName) async {
    try {
      final response = await _dio.head(_dbPath(dbName));
      if (response.statusCode == 404) {
        await _dio.put(_dbPath(dbName));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _dio.put(_dbPath(dbName));
        return;
      }
      rethrow;
    }
  }

  static Future<JsonMap> getDocument(String dbName, String id) async {
    final response = await _dio.get('${_dbPath(dbName)}/$id');
    return _toJson(response.data);
  }

  static Future<JsonMap> createDocument(String dbName, JsonMap document,
      {String? documentId}) async {
    final response = documentId != null && documentId.isNotEmpty
        ? await _dio.put('${_dbPath(dbName)}/$documentId', data: document)
        : await _dio.post(_dbPath(dbName), data: document);
    return _toJson(response.data);
  }

  static Future<JsonMap> updateDocument(String dbName, String id, JsonMap document) async {
    if (!document.containsKey('_rev')) {
      throw ArgumentError('updateDocument requires document["_rev"] to be set');
    }
    final response = await _dio.put('${_dbPath(dbName)}/$id', data: document);
    return _toJson(response.data);
  }

  static Future<JsonMap> deleteDocument(String dbName, String id, String rev) async {
    final response = await _dio.delete('${_dbPath(dbName)}/$id', queryParameters: {'rev': rev});
    return _toJson(response.data);
  }

  static Future<List<JsonMap>> listDocuments(String dbName,
      {bool includeDocs = true, int limit = 100}) async {
    final response = await _dio.get('${_dbPath(dbName)}/_all_docs', queryParameters: {
      'include_docs': includeDocs ? 'true' : 'false',
      'limit': limit,
    });
    final data = _toJson(response.data);
    final rows = (data['rows'] as List<dynamic>?) ?? [];
    return rows.map((row) {
      final mapped = row as Map<String, dynamic>;
      if (includeDocs && mapped['doc'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(mapped['doc'] as Map<String, dynamic>);
      }
      return Map<String, dynamic>.from(mapped);
    }).toList();
  }

  static Future<List<JsonMap>> findDocuments(String dbName, JsonMap selector,
      {int limit = 25, int skip = 0}) async {
    final response = await _dio.post('${_dbPath(dbName)}/_find', data: {
      'selector': selector,
      'limit': limit,
      'skip': skip,
    });
    final data = _toJson(response.data);
    final docs = (data['docs'] as List<dynamic>?) ?? [];
    return docs.map((doc) => Map<String, dynamic>.from(doc as Map<String, dynamic>)).toList();
  }

  static Future<JsonMap> getDatabaseInfo(String dbName) async {
    final response = await _dio.get(_dbPath(dbName));
    return _toJson(response.data);
  }

  static JsonMap _toJson(dynamic data) {
    if (data is JsonMap) return data;
    if (data is String) return jsonDecode(data) as JsonMap;
    if (data is Map<String, dynamic>) return data;
    throw FormatException('Unexpected CouchDB response format');
  }
}
