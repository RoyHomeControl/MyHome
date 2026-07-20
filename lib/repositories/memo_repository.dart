import 'package:dio/dio.dart';

import '../core/couchdb.dart';
import '../core/const.dart';
import '../models/memo.dart';

class MemoRepository {
  MemoRepository._();

  static Future<void> ensureDatabase() async {
    await CouchDb.ensureDatabaseExists(memoDB);
  }

  static Future<List<Memo>> fetchAll() async {
    final documents = await CouchDb.listDocuments(memoDB, includeDocs: true, limit: 500);
    final memos = documents.map(Memo.fromJson).toList();
    memos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return memos;
  }

  static Future<List<Memo>> fetchByOwner(String ownerId) async {
    final documents = await CouchDb.findDocuments(
      memoDB,
      {'ownerId': ownerId},
      limit: 500,
    );
    final memos = documents.map(Memo.fromJson).toList();
    memos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return memos;
  }

  static Future<Memo> save(Memo memo) async {
    if (memo.id != null && memo.rev != null) {
      try {
        final response = await CouchDb.updateDocument(memoDB, memo.id!, memo.toDocument(includeCouchFields: true));
        return memo.copyWith(rev: response['_rev'] as String?);
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) {
          final latestDoc = await CouchDb.getDocument(memoDB, memo.id!);
          final latestRev = latestDoc['_rev']?.toString();
          if (latestRev != null && latestRev != memo.rev) {
            return save(memo.copyWith(rev: latestRev));
          }
        }
        rethrow;
      }
    }

    final response = await CouchDb.createDocument(memoDB, memo.toDocument(), documentId: memo.id);
    return memo.copyWith(
      id: response['id'] as String?,
      rev: response['rev'] as String?,
    );
  }

  static Future<void> delete(Memo memo) async {
    if (memo.id == null || memo.rev == null) {
      throw ArgumentError('Memo delete requires id and rev');
    }

    try {
      await CouchDb.deleteDocument(memoDB, memo.id!, memo.rev!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return;
      }

      if (e.response?.statusCode == 409) {
        final latestDoc = await CouchDb.getDocument(memoDB, memo.id!);
        final latestRev = latestDoc['_rev']?.toString();
        if (latestRev != null) {
          await CouchDb.deleteDocument(memoDB, memo.id!, latestRev);
          return;
        }
      }
      rethrow;
    }
  }
}