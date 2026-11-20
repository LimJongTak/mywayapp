import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.uid,
    required this.nickname,
    this.email,
    this.photoUrl,
    this.points = 0,
    this.referralCode = '',
    this.trailCount = 0,
    this.walkCount = 0,
    this.totalWalkM = 0,
    this.createdAt,
  });

  final String uid;
  final String nickname;
  final String? email;
  final String? photoUrl;
  final int points;
  final String referralCode;
  final int trailCount;
  final int walkCount;
  final int totalWalkM;
  final DateTime? createdAt;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppUser(
      uid: doc.id,
      nickname: d['nickname'] as String? ?? '',
      email: d['email'] as String?,
      photoUrl: d['photoUrl'] as String?,
      points: (d['points'] as num?)?.toInt() ?? 0,
      referralCode: d['referralCode'] as String? ?? '',
      trailCount: (d['trailCount'] as num?)?.toInt() ?? 0,
      walkCount: (d['walkCount'] as num?)?.toInt() ?? 0,
      totalWalkM: (d['totalWalkM'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class PointLog {
  PointLog({required this.amount, required this.reason, this.createdAt});
  final int amount;
  final String reason;
  final DateTime? createdAt;

  factory PointLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PointLog(
      amount: (d['amount'] as num).toInt(),
      reason: d['reason'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Reward {
  Reward({
    required this.id,
    required this.title,
    required this.partnerName,
    required this.cost,
    required this.stock,
  });
  final String id;
  final String title;
  final String partnerName;
  final int cost;
  final int stock;

  factory Reward.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Reward(
      id: doc.id,
      title: d['title'] as String? ?? '',
      partnerName: d['partnerName'] as String? ?? '',
      cost: (d['cost'] as num?)?.toInt() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
    );
  }
}

class Coupon {
  Coupon({
    required this.id,
    required this.title,
    required this.partnerName,
    required this.code,
    required this.used,
    this.expiresAt,
  });
  final String id;
  final String title;
  final String partnerName;
  final String code;
  final bool used;
  final DateTime? expiresAt;

  factory Coupon.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Coupon(
      id: doc.id,
      title: d['title'] as String? ?? '',
      partnerName: d['partnerName'] as String? ?? '',
      code: d['code'] as String? ?? '',
      used: d['used'] as bool? ?? false,
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Inquiry {
  Inquiry({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.title,
    required this.content,
    required this.status,
    this.answer,
    this.createdAt,
  });
  final String id;
  final String uid;
  final String authorName;
  final String title;
  final String content;
  final String status;
  final String? answer;
  final DateTime? createdAt;

  bool get answered => status == 'answered';

  factory Inquiry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Inquiry(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      title: d['title'] as String? ?? '',
      content: d['content'] as String? ?? '',
      status: d['status'] as String? ?? 'open',
      answer: d['answer'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class WalkRecord {
  WalkRecord({
    required this.trailTitle,
    required this.distanceM,
    required this.durationSec,
    required this.points,
    required this.verified,
    this.createdAt,
  });
  final String trailTitle;
  final int distanceM;
  final int durationSec;
  final int points;
  final bool verified;
  final DateTime? createdAt;

  factory WalkRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return WalkRecord(
      trailTitle: d['trailTitle'] as String? ?? '',
      distanceM: (d['distanceM'] as num?)?.toInt() ?? 0,
      durationSec: (d['durationSec'] as num?)?.toInt() ?? 0,
      points: (d['points'] as num?)?.toInt() ?? 0,
      verified: d['verified'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
