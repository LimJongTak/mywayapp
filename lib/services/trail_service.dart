import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../core/errors.dart';
import '../core/geo.dart';
import '../models/facility.dart';
import '../models/trail.dart';
import 'auth_service.dart';
import 'firebase_refs.dart';

class TrailInput {
  TrailInput({
    required this.title,
    required this.description,
    required this.tags,
    required this.category,
    this.photo,
  });
  final String title;
  final String description;
  final List<String> tags;
  final String category;
  final XFile? photo;
}

class WalkResult {
  WalkResult(this.verified, this.points, this.message, this.distanceM);
  final bool verified;
  final int points;
  final String message;
  final int distanceM;
}

class TrailService {
  TrailService._();
  static final instance = TrailService._();

  CollectionReference<Map<String, dynamic>> get _trails => Fb.db.collection('trails');

  Stream<List<Trail>> watchRecent({int limit = 300}) => _trails
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Trail.fromDoc).toList());

  Stream<List<Trail>> watchPopular({int limit = 20}) => _trails
      .orderBy('ratingAvg', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Trail.fromDoc).toList());

  Stream<List<Trail>> watchMine(String uid) => _trails
      .where('ownerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Trail.fromDoc).toList());

  Stream<Trail?> watch(String id) =>
      _trails.doc(id).snapshots().map((s) => s.exists ? Trail.fromDoc(s) : null);

  /// 제목 접두어 + 태그 일치 검색 (Firestore는 전문 검색 미지원 → 두 쿼리 병합)
  Future<List<Trail>> search(String query) async {
    final q = query.trim().replaceAll('#', '');
    if (q.isEmpty) return [];
    final results = await Future.wait([
      _trails
          .orderBy('title')
          .startAt([q])
          .endAt(['$q'])
          .limit(30)
          .get(),
      _trails.where('tags', arrayContains: q).orderBy('ratingAvg', descending: true).limit(30).get(),
    ]);
    final map = <String, Trail>{};
    for (final snap in results) {
      for (final d in snap.docs) {
        map[d.id] = Trail.fromDoc(d);
      }
    }
    return map.values.toList();
  }

  Future<({String url, String path})> _uploadPhoto(XFile photo) async {
    final uid = Fb.uid!;
    final ext = photo.name.split('.').last.toLowerCase();
    final safeExt = const ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext) ? ext : 'jpg';
    final path = 'users/$uid/trails/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final ref = Fb.storage.ref(path);
    final bytes = await photo.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw AppException('사진은 5MB 이하만 업로드할 수 있습니다.');
    }
    final contentType = safeExt == 'jpg' ? 'image/jpeg' : 'image/$safeExt';
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return (url: await ref.getDownloadURL(), path: path);
  }

  Future<String> create(List<LatLng> path, TrailInput input) async {
    final profile = AuthService.instance.profile!;
    final simplified = simplifyByDistance(path, 5);
    final distance = pathDistanceM(simplified);
    final photo = input.photo == null ? null : await _uploadPhoto(input.photo!);
    final doc = _trails.doc();
    await doc.set({
      'ownerId': profile.uid,
      'ownerName': profile.nickname,
      'title': input.title.trim(),
      'description': input.description.trim(),
      'tags': input.tags,
      'category': input.category,
      'path': simplified.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
      'distanceM': double.parse(distance.toStringAsFixed(1)),
      'durationMin': walkingMinutes(distance),
      'startLocation': GeoPoint(simplified.first.latitude, simplified.first.longitude),
      'photoUrl': photo?.url,
      'photoPath': photo?.path,
      'ratingAvg': 0,
      'ratingCount': 0,
      'favoriteCount': 0,
      'walkCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> update(Trail trail, TrailInput input) async {
    final data = <String, dynamic>{
      'title': input.title.trim(),
      'description': input.description.trim(),
      'tags': input.tags,
      'category': input.category,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (input.photo != null) {
      final photo = await _uploadPhoto(input.photo!);
      data['photoUrl'] = photo.url;
      data['photoPath'] = photo.path;
    }
    await _trails.doc(trail.id).update(data);
    if (input.photo != null && trail.photoPath != null) {
      try {
        await Fb.storage.ref(trail.photoPath).delete();
      } catch (_) {
        // 이전 사진 정리 실패는 무시
      }
    }
  }

  /// 문서 삭제 → onTrailDeleted 함수가 리뷰·사진 정리
  Future<void> delete(String id) => _trails.doc(id).delete();

  // ── 리뷰 ──
  Stream<List<Review>> watchReviews(String trailId) => _trails
      .doc(trailId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Review.fromDoc).toList());

  Future<void> saveReview(String trailId, int rating, String text) =>
      _trails.doc(trailId).collection('reviews').doc(Fb.uid).set({
        'rating': rating,
        'text': text.trim(),
        'authorName': AuthService.instance.profile!.nickname,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// 본인 리뷰 삭제 (관리자는 uid 지정 가능 — 규칙에서 권한 검증)
  Future<void> deleteReview(String trailId, {String? uid}) =>
      _trails.doc(trailId).collection('reviews').doc(uid ?? Fb.uid).delete();

  // ── 관심목록 ──
  CollectionReference<Map<String, dynamic>> _favs(String uid) =>
      Fb.db.collection('users').doc(uid).collection('favorites');

  Stream<Set<String>> watchFavoriteIds() {
    final uid = Fb.uid;
    if (uid == null) return Stream.value({});
    return _favs(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  Future<void> toggleFavorite(Trail trail, bool currentlyFav) async {
    final ref = _favs(Fb.uid!).doc(trail.id);
    if (currentlyFav) {
      await ref.delete();
    } else {
      await ref.set({'title': trail.title, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  // ── 산책 완료 (서버 검증 + 포인트) ──
  Future<WalkResult> completeWalk({
    required String trailId,
    required List<LatLng> walked,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final path = simplifyByDistance(walked, 3);
    final res = await Fb.call('completeWalk', {
      'trailId': trailId,
      'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'startedAt': startedAt.millisecondsSinceEpoch,
      'endedAt': endedAt.millisecondsSinceEpoch,
    });
    return WalkResult(
      res['verified'] == true,
      (res['points'] as num?)?.toInt() ?? 0,
      res['message'] as String? ?? '',
      (res['distanceM'] as num?)?.toInt() ?? 0,
    );
  }

  // ── 편의시설 ──
  Stream<List<Facility>> watchFacilities() => Fb.db
      .collection('facilities')
      .limit(1000)
      .snapshots()
      .map((s) => s.docs.map(Facility.fromDoc).whereType<Facility>().toList());
}
