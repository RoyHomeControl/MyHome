import 'package:flutter/material.dart';

import 'couchdb.dart';

import 'const.dart';

typedef JsonMap = Map<String, dynamic>;

const String defaultMemoOwnerId = 'me';

class Memo {
  final String? id;
  final String? rev;
  final String ownerId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? dueAt;

  Memo({
    this.id,
    this.rev,
    required this.ownerId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.dueAt,
  });

  Memo copyWith({
    String? id,
    String? rev,
    String? ownerId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? dueAt,
  }) {
    return Memo(
      id: id ?? this.id,
      rev: rev ?? this.rev,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
    );
  }

  factory Memo.fromJson(JsonMap json) {
    return Memo(
      id: json['_id'] as String?,
      rev: json['_rev'] as String?,
      ownerId: json['ownerId']?.toString() ?? defaultMemoOwnerId,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'].toString()).toLocal()
          : null,
    );
  }

  JsonMap toDocument({bool includeCouchFields = false}) {
    final data = <String, dynamic>{
      'ownerId': ownerId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'dueAt': dueAt?.toUtc().toIso8601String(),
    };
    if (includeCouchFields) {
      if (id != null) data['_id'] = id;
      if (rev != null) data['_rev'] = rev;
    }
    return data;
  }
}

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
      final response = await CouchDb.updateDocument(memoDB, memo.id!, memo.toDocument(includeCouchFields: true));
      return memo.copyWith(rev: response['_rev'] as String?);
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
    await CouchDb.deleteDocument(memoDB, memo.id!, memo.rev!);
  }
}

class MemoService {
  MemoService._();

  static Future<List<Memo>> loadForUser(String ownerId) async {
    await MemoRepository.ensureDatabase();
    return MemoRepository.fetchByOwner(ownerId);
  }

  static Future<Memo?> openEditor(BuildContext context, {Memo? memo, required String ownerId}) async {
    final result = await Navigator.of(context).push<Memo>(
      MaterialPageRoute(builder: (_) => AddEditMemoPage(memo: memo, ownerId: ownerId)),
    );
    return result;
  }

  static Future<void> deleteMemo(Memo memo) async {
    await MemoRepository.delete(memo);
  }
}

class AddEditMemoPage extends StatefulWidget {
  final Memo? memo;
  final String ownerId;

  const AddEditMemoPage({super.key, this.memo, required this.ownerId});

  @override
  State<AddEditMemoPage> createState() => _AddEditMemoPageState();
}

class _AddEditMemoPageState extends State<AddEditMemoPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _createdAt;
  DateTime? _dueAt;
  final _formKey = GlobalKey<FormState>();
  late final FocusNode _contentFocusNode;
  bool _isContentFocused = false;

  @override
  void initState() {
    super.initState();
    final memo = widget.memo;
    _titleController = TextEditingController(text: memo?.title ?? '');
    _contentController = TextEditingController(text: memo?.content ?? '');
    _createdAt = memo?.createdAt ?? DateTime.now();
    _dueAt = memo?.dueAt;
    _contentFocusNode = FocusNode();
    _contentFocusNode.addListener(() {
      setState(() {
        _isContentFocused = _contentFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.removeListener(() {});
    _contentFocusNode.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _dueAt ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (selectedTime == null) {
      _dueAt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    } else {
      _dueAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    }
    setState(() {});
  }

  void _clearDueDate() {
    setState(() {
      _dueAt = null;
    });
  }

  Future<void> _saveMemo() async {
    if (!_formKey.currentState!.validate()) return;

    final memo = Memo(
      id: widget.memo?.id,
      rev: widget.memo?.rev,
      ownerId: widget.memo?.ownerId ?? widget.ownerId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: _createdAt,
      dueAt: _dueAt,
    );

    final saved = await MemoRepository.save(memo);
    if (mounted) {
      Navigator.of(context).pop(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '메모 수정' : '메모 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목은 항상 보이도록 둠
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                  validator: (value) => value == null || value.trim().isEmpty ? '제목을 입력하세요.' : null,
                ),
                const SizedBox(height: 12),
                // 내용 영역은 크기를 제한해서 키보드가 올라와도 덜 줄어들게 함
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 160, maxHeight: MediaQuery.of(context).size.height * 0.6),
                    child: TextFormField(
                      focusNode: _contentFocusNode,
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      expands: false,
                      textInputAction: TextInputAction.newline,
                      validator: (value) => value == null || value.trim().isEmpty ? '내용을 입력하세요.' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 생성일 / 알림일 및 관련 버튼은 내용 포커스 시 숨김
                if (!_isContentFocused) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('생성일', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(_formatDateTime(_createdAt)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('알림일', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(_dueAt != null ? _formatDateTime(_dueAt!) : '설정 없음'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _pickDueDate,
                          child: const Text('알림일 선택'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _dueAt != null ? _clearDueDate : null,
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saveMemo,
              child: Text(isEditing ? '저장' : '추가'),
            ),
          ),
        ),
      ),
    );
  }
}
