/// A single note/task item under a specific course, stored as part of
/// a list at /users/{uid}/notes/{courseKey}.json.
class NoteItem {
  final String id;
  final String text;
  final bool done;
  final String createdAt;

  const NoteItem({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAt,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      done: json['done'] == true,
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        'createdAt': createdAt,
      };

  NoteItem copyWith({bool? done}) => NoteItem(
        id: id,
        text: text,
        done: done ?? this.done,
        createdAt: createdAt,
      );
}
