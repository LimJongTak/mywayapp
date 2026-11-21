import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'auth_service.dart';
import 'firebase_refs.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  DocumentReference<Map<String, dynamic>> get _me => Fb.db.collection('users').doc(Fb.uid);

  Stream<List<PointLog>> watchPointLogs() => _me
      .collection('pointLogs')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(PointLog.fromDoc).toList());

  Stream<List<WalkRecord>> watchWalks() => _me
      .collection('walks')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(WalkRecord.fromDoc).toList());

  Stream<List<Coupon>> watchCoupons() => _me
      .collection('coupons')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Coupon.fromDoc).toList());

  Stream<List<Reward>> watchRewards() => Fb.db
      .collection('rewards')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(Reward.fromDoc).toList()..sort((a, b) => a.cost.compareTo(b.cost)));

  Future<String> redeem(String rewardId) async {
    final res = await Fb.call('redeemReward', {'rewardId': rewardId});
    return res['code'] as String;
  }

  // ── 고객센터 ──
  CollectionReference<Map<String, dynamic>> get _inquiries => Fb.db.collection('inquiries');

  Stream<List<Inquiry>> watchMyInquiries() => _inquiries
      .where('uid', isEqualTo: Fb.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Inquiry.fromDoc).toList());

  Stream<List<Inquiry>> watchOpenInquiries() => _inquiries
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Inquiry.fromDoc).toList());

  Future<void> createInquiry(String title, String content) => _inquiries.add({
        'uid': Fb.uid,
        'authorName': AuthService.instance.profile!.nickname,
        'title': title.trim(),
        'content': content.trim(),
        'status': 'open',
        'answer': null,
        'createdAt': FieldValue.serverTimestamp(),
        'answeredAt': null,
      });

  Future<void> answerInquiry(String id, String answer) => _inquiries.doc(id).update({
        'answer': answer.trim(),
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });
}
