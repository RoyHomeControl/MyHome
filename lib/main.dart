import 'package:flutter/material.dart';

import 'login.dart';
import 'memo.dart';
import 'update_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyHome',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _currentUsername;

  final _updateService = UpdateService();
  final List<Memo> _memos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _updateService.runUpdateFlow(context);
      await _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final cur = await Session.currentUser();
    if (cur != null && cur.isNotEmpty) {
      setState(() => _currentUsername = cur);
      await _loadMemos();
      return;
    }

    final username = await Session.ensureLoggedIn(context);
    if (username != null && username.isNotEmpty) {
      setState(() => _currentUsername = username);
      await _loadMemos();
      return;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMemos() async {
    try {
      await MemoRepository.ensureDatabase();
      final memos = await MemoRepository.fetchByOwner(_currentUsername!);
      if (mounted) {
        setState(() {
          _memos
            ..clear()
            ..addAll(memos);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openMemoEditor([Memo? memo]) async {
    if (_currentUsername == null) {
      final username = await Session.ensureLoggedIn(context);
      if (username == null || username.isEmpty) return;
      setState(() => _currentUsername = username);
      await _loadMemos();
    }

    final result = await Navigator.of(context).push<Memo>(
      MaterialPageRoute(builder: (_) => AddEditMemoPage(
        memo: memo,
        ownerId: _currentUsername!,
      )),
    );
    if (result == null) return;

    setState(() {
      final index = _memos.indexWhere((item) => item.id == result.id);
      if (index >= 0) {
        _memos[index] = result;
      } else {
        _memos.insert(0, result);
      }
    });
  }

  Future<void> _deleteMemo(int index) async {
    final memo = _memos[index];
    try {
      await MemoRepository.delete(memo);
      setState(() {
        _memos.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모가 삭제되었습니다.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모 삭제에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUsername == null ? 'MyHome' : 'MyHome (${_currentUsername!})'),
        actions: [
          if (_currentUsername != null)
            IconButton(
              tooltip: '로그아웃',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Session.clear();
                if (mounted) {
                  setState(() {
                    _currentUsername = null;
                    _memos.clear();
                  });
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentUsername == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '로그인이 필요합니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final username = await Session.ensureLoggedIn(context);
                            if (username != null && username.isNotEmpty) {
                              setState(() => _currentUsername = username);
                              await _loadMemos();
                            }
                          },
                          child: const Text('로그인 / 회원가입'),
                        ),
                      ],
                    ),
                  )
                : _memos.isEmpty
                    ? const Center(
                        child: Text(
                          '메모가 없습니다. + 버튼을 눌러 메모를 추가하세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                : GridView.builder(
                    itemCount: _memos.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final memo = _memos[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openMemoEditor(memo),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.yellow[200],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha((0.12 * 255).round()),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        memo.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      onPressed: () => _deleteMemo(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    memo.content,
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '생성: ${_formatDateTime(memo.createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                if (memo.dueAt != null)
                                  Text(
                                    '알림: ${_formatDateTime(memo.dueAt!)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: _currentUsername == null
          ? null
          : FloatingActionButton(
              onPressed: () => _openMemoEditor(),
              tooltip: '메모 추가',
              child: const Icon(Icons.add),
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
