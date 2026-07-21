import 'package:flutter/material.dart';
import '../core/notification_service.dart';
import '../models/memo.dart';
import '../providers/memo_provider.dart';

class MemoEditorResult {
  final Memo? memo;
  final bool deleted;

  const MemoEditorResult({this.memo, this.deleted = false});
}

class MemoEditorPage extends StatefulWidget {
  final Memo? memo;
  final String ownerId;

  const MemoEditorPage({super.key, this.memo, required this.ownerId});
  static Future<MemoEditorResult?> open(
    BuildContext context, {
    Memo? memo,
    required String ownerId,
    }) {
    return Navigator.of(context).push<MemoEditorResult>(
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
  bool _isDeleting = false;
  bool _useTitle = false;
  DateTime? _dueAt;
  final _formKey = GlobalKey<FormState>();
  late final FocusNode _contentFocusNode;
  late final FocusNode _titleFocusNode;

  @override
  void initState() {
    super.initState();
    final memo = widget.memo;
    _titleController = TextEditingController(text: memo?.title ?? '');
    _contentController = TextEditingController(text: memo?.content ?? '');
    _createdAt = memo?.createdAt ?? DateTime.now();
    _dueAt = memo?.dueAt;
    _useTitle = (memo?.title ?? '').trim().isNotEmpty;
    _contentFocusNode = FocusNode();
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _titleFocusNode.dispose();
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

    final title = _useTitle ? _titleController.text.trim() : '';
    final content = _contentController.text.trim();

    final memo = Memo(
      id: widget.memo?.id,
      rev: widget.memo?.rev,
      ownerId: widget.memo?.ownerId ?? widget.ownerId,
      title: title,
      content: content,
      createdAt: _createdAt,
      dueAt: _dueAt,
    );

    try {
      final saved = await MemoProvider.saveMemo(memo);
      // if (saved.dueAt != null) {
      //   await NotificationService.instance.scheduleMemoNotification(saved);
      // } else {
      //   await NotificationService.instance.cancelMemoNotification(saved);
      // }
      if (mounted) {
        Navigator.of(context).pop(MemoEditorResult(memo: saved));
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
    if (_isDeleting) return;

    if (widget.memo == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      // await NotificationService.instance.cancelMemoNotification(widget.memo!);
      await MemoProvider.deleteMemo(widget.memo!);
      if (mounted) {
        Navigator.of(context).pop(const MemoEditorResult(deleted: true));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제에 실패했습니다: $e')),
        );
      }
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('제목 사용'),
                      value: _useTitle,
                      onChanged: (value) {
                        setState(() {
                          _useTitle = value;
                          if (!value) {
                            _titleController.clear();
                          }
                        });
                      },
                    ),
                    if (_useTitle) ...[
                      TextFormField(
                        focusNode: _titleFocusNode,
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: '제목'),
                        validator: (value) => value == null || value.trim().isEmpty ? '제목을 입력하세요.' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 160,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
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
                const SizedBox(height: 12),
                // 생성일 / 알림일 및 관련 버튼은 키보드가 올라왔을 때 숨김
                if (!keyboardVisible) ...[
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveMemo,
        icon: const Icon(Icons.save),
        label: const Text('저장'),
      ),
    );
  }
}
