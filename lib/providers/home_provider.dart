import 'package:flutter/foundation.dart';

import '../models/memo.dart';
import 'memo_provider.dart';
import '../core/session.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await Session.currentUser();
    await initialize(user);
  }

  String? _username;

  List<Memo> _memos = [];

  bool _isLoading = true;


  String? get username => _username;

  List<Memo> get memos => List.unmodifiable(_memos);

  bool get isLoading => _isLoading;


  Future<void> initialize(String? username) async {

    _username = username;

    if (username == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    await loadMemos();
  }


  Future<void> loadMemos() async {
    if (_username == null) return;

    _isLoading = true;
    notifyListeners();


    try {
      final list = await MemoProvider.loadForUser(_username!);
      _memos = list;
    }
    catch(e) {
      debugPrint(
        'load memos failed: $e'
      );

      _memos = [];
    }
    
    _isLoading = false;

    notifyListeners();
  }



  Future<void> addOrUpdateMemo(Memo memo) async {

    final saved =
        await MemoProvider.saveMemo(memo);


    final index =
        _memos.indexWhere((m) => m.id == saved.id);


    if(index >= 0){
      _memos[index] = saved;
    }
    else {
      _memos.insert(0, saved);
    }


    notifyListeners();
  }



  Future<void> deleteMemo(Memo memo) async {
    await MemoProvider.deleteMemo(memo);
    removeMemo(memo);
  }

  void removeMemo(Memo memo) {
    _memos.removeWhere((m) => m.id == memo.id);
    notifyListeners();
  }



  void logout(){

    _username = null;
    _memos.clear();

    notifyListeners();
  }
}