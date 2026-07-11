class CommentModel {
  final int id;
  final int taskId;
  final int authorId;
  final String authorName;
  final String content;
  final int? parentId;
  final bool edited;
  final String? createdAt;

  CommentModel({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.parentId,
    required this.edited,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? 0,
      taskId: json['taskId'] ?? 0,
      authorId: json['authorId'] ?? 0,
      authorName: json['authorName'] ?? '',
      content: json['content'] ?? '',
      parentId: json['parentId'],
      edited: json['edited'] ?? false,
      createdAt: json['createdAt'],
    );
  }
}
