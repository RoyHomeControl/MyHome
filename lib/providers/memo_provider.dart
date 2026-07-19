import '../models/memo.dart';
import '../repositories/memo_repository.dart';

class MemoProvider {
  MemoProvider._();

  static Future<List<Memo>> loadForUser(String ownerId) async {
    await MemoRepository.ensureDatabase();
    return MemoRepository.fetchByOwner(ownerId);
  }

  static Future<Memo> saveMemo(Memo memo){
    return MemoRepository.save(memo);
  }

  static Future<void> deleteMemo(Memo memo) async {
    await MemoRepository.delete(memo);
  }
}