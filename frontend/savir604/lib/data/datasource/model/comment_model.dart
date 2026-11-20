// lib/data/models/comment_model.dart
class CommentModel {
  final int commentId;
  final int videoId;
  final int userId;
  final String commentText;
  int commentLikes;
  final String commentDate;
  final String usersName;
  final String userRole;
  List<CommentModel> replies;

  CommentModel({
    required this.commentId,
    required this.videoId,
    required this.userId,
    required this.commentText,
    required this.commentLikes,
    required this.commentDate,
    required this.usersName,
    required this.userRole,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Defensive parsing: API sometimes omits fields for replies (e.g. video_id),
    // so use safe parsing to avoid FormatException and fall back to sensible defaults.
    int safeParseId(Object? value) =>
        int.tryParse(value?.toString() ?? '') ?? 0;

    return CommentModel(
      commentId: safeParseId(json['comment_id']),
      videoId: safeParseId(json['video_id']),
      userId: safeParseId(json['user_id']),
      commentText: json['comment_text'] ?? '',
      commentLikes: int.tryParse(json['comment_likes']?.toString() ?? '') ?? 0,
      commentDate: json['comment_date']?.toString() ?? '',
      usersName: json['users_name']?.toString() ?? '',
      userRole: json['user_role']?.toString() ?? 'user',
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) return CommentModel.fromJson(e);
                // sometimes replies might be returned in a non-map form; ignore safely
                return null;
              })
              .whereType<CommentModel>()
              .toList() ??
          [],
    );
  }
}
