class LocalAnnouncement {
  const LocalAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? publishedAt;

  bool get published => publishedAt != null;

  LocalAnnouncement copyWith({
    String? title,
    String? content,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
  }) {
    return LocalAnnouncement(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'publishedAt': publishedAt?.toIso8601String(),
  };

  factory LocalAnnouncement.fromJson(Map<String, dynamic> json) {
    return LocalAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
    );
  }
}
