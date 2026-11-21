import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';
import 'auth_service.dart';
import 'firebase_refs.dart';

class CommunityService {
  CommunityService._();
  static final instance = CommunityService._();

  CollectionReference<Map<String, dynamic>> get _posts => Fb.db.collection('posts');

  Stream<List<Post>> watchBoard(Board board, {int limit = 100}) => _posts
      .where('board', isEqualTo: board.name)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Post.fromDoc).toList());

  /// HOT 게시물: 조회수 상위
  Stream<List<Post>> watchHot({int limit = 3}) => _posts
      .where('board', isEqualTo: Board.free.name)
      .orderBy('viewCount', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Post.fromDoc).toList());

  Stream<Post?> watchPost(String id) =>
      _posts.doc(id).snapshots().map((s) => s.exists ? Post.fromDoc(s) : null);

  Future<String> create(Board board, String title, String content) async {
    final p = AuthService.instance.profile!;
    final doc = _posts.doc();
    await doc.set({
      'board': board.name,
      'title': title.trim(),
      'content': content.trim(),
      'authorId': p.uid,
      'authorName': p.nickname,
      'viewCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> update(String id, String title, String content) => _posts.doc(id).update({
        'title': title.trim(),
        'content': content.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) => _posts.doc(id).delete();

  /// 조회수는 서버에서 사용자당 1회만 증가
  Future<void> markViewed(String id) async {
    try {
      await Fb.call('viewPost', {'postId': id});
    } catch (_) {
      // 조회수 실패는 화면 표시에 영향 없음
    }
  }

  Stream<List<Comment>> watchComments(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(Comment.fromDoc).toList());

  Future<void> addComment(String postId, String content) {
    final p = AuthService.instance.profile!;
    return _posts.doc(postId).collection('comments').add({
      'authorId': p.uid,
      'authorName': p.nickname,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, String commentId) =>
      _posts.doc(postId).collection('comments').doc(commentId).delete();
}
