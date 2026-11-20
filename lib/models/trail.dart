import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class TrailCategory {
  static const Map<String, String> labels = {
    'general': '일반',
    'dog': '반려견 산책',
    'night': '야경 맛집',
    'nature': '자연/숲길',
    'city': '도심',
    'family': '가족/데이트',
  };
}

class Trail {
  Trail({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.tags,
    required this.category,
    required this.path,
    required this.distanceM,
    required this.durationMin,
    this.photoUrl,
    this.photoPath,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.favoriteCount = 0,
    this.walkCount = 0,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final List<String> tags;
  final String category;
  final List<LatLng> path;
  final double distanceM;
  final int durationMin;
  final String? photoUrl;
  final String? photoPath;
  final double ratingAvg;
  final int ratingCount;
  final int favoriteCount;
  final int walkCount;
  final DateTime? createdAt;

  LatLng get start => path.first;

  factory Trail.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Trail(
      id: doc.id,
      ownerId: d['ownerId'] as String,
      ownerName: d['ownerName'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      tags: List<String>.from(d['tags'] as List? ?? const []),
      category: d['category'] as String? ?? 'general',
      path: (d['path'] as List? ?? const [])
          .cast<GeoPoint>()
          .map((g) => LatLng(g.latitude, g.longitude))
          .toList(),
      distanceM: (d['distanceM'] as num?)?.toDouble() ?? 0,
      durationMin: (d['durationMin'] as num?)?.toInt() ?? 0,
      photoUrl: d['photoUrl'] as String?,
      photoPath: d['photoPath'] as String?,
      ratingAvg: (d['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (d['favoriteCount'] as num?)?.toInt() ?? 0,
      walkCount: (d['walkCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Review {
  Review({
    required this.uid,
    required this.rating,
    required this.text,
    required this.authorName,
    this.createdAt,
  });

  final String uid;
  final int rating;
  final String text;
  final String authorName;
  final DateTime? createdAt;

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Review(
      uid: doc.id,
      rating: (d['rating'] as num).toInt(),
      text: d['text'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
