import 'package:cloud_firestore/cloud_firestore.dart';

enum Board {
  notice('공지사항'),
  free('자유게시판'),
  qna('Q&A');

  const Board(this.label);
  final String label;

  static Board parse(String? v) =>
      Board.values.where((b) => b.name == v).firstOrNull ?? Board.free;
}

class Post {
  Post({
    required this.id,
    required this.board,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.viewCount = 0,
    this.commentCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final Board board;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final int viewCount;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Post(
      id: doc.id,
      board: Board.parse(d['board'] as String?),
      title: d['title'] as String? ?? '',
      content: d['content'] as String? ?? '',
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      viewCount: (d['viewCount'] as num?)?.toInt() ?? 0,
      commentCount: (d['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Comment {
  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime? createdAt;

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Comment(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      content: d['content'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
