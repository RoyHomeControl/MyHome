import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../providers/memo_provider.dart';

class MemoEditorPage extends StatefulWidget {
  final Memo? memo;
  final String ownerId;

  const MemoEditorPage({super.key, this.memo, required this.ownerId});
  static Future<Memo?> open(
    BuildContext context, {
    Memo? memo,
    required String ownerId,
    }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemoEditorPage(
          memo: memo,
          ownerId: ownerId,
        ),
      ),
    );
  }
  @override
  State<MemoEditorPage> createState() => _MemoEditorPageState();
}

class _MemoEditorPageState extends State<MemoEditorPage> {
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

    try {
      final saved = await MemoProvider.saveMemo(memo);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteMemo() async {
    if (widget.memo == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      await MemoProvider.deleteMemo(widget.memo!);
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '메모 수정' : '메모 추가'),
        actions: [
          IconButton(
            tooltip: '삭제',
            onPressed: _deleteMemo,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Scrollbar(
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
                const SizedBox(height: 24),
              ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveMemo,
        icon: const Icon(Icons.save),
        label: const Text('저장'),
      ),
    );
  }
}
