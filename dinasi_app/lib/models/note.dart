class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'] as String,
    title: j['title'] as String,
    content: j['content'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
