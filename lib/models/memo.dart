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