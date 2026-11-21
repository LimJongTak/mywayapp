import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/geo.dart';
import '../../core/theme.dart';
import '../../models/trail.dart';
import '../../services/auth_service.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';
import '../../widgets/map_tiles.dart';

class TrailDetailScreen extends StatelessWidget {
  const TrailDetailScreen({super.key, required this.trailId});
  final String trailId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Trail?>(
      stream: TrailService.instance.watch(trailId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final trail = snap.data;
        if (trail == null) {
          return Scaffold(
              appBar: AppBar(), body: const EmptyView(message: '삭제되었거나 없는 산책로입니다.'));
        }
        return _TrailDetail(trail: trail);
      },
    );
  }
}

class _TrailDetail extends StatelessWidget {
  const _TrailDetail({required this.trail});
  final Trail trail;

  bool get _isOwner => AuthService.instance.user?.uid == trail.ownerId;

  Future<void> _delete(BuildContext context) async {
    if (!await confirmDialog(context, '산책로 삭제', '"${trail.title}" 산책로를 삭제할까요?')) return;
    try {
      await TrailService.instance.delete(trail.id);
      if (context.mounted) {
        showSnack(context, '삭제되었습니다.');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds.fromPoints(trail.path);
    return Scaffold(
      appBar: AppBar(
        title: Text(trail.title),
        actions: [
          _FavoriteButton(trail: trail),
          if (_isOwner || AuthService.instance.isAdmin)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') context.push('/trail/${trail.id}/edit');
                if (v == 'delete') _delete(context);
              },
              itemBuilder: (_) => [
                if (_isOwner) const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
        // 히어로 사진 카드
        Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(fit: StackFit.expand, children: [
              TrailPhoto(
                  url: trail.photoUrl,
                  category: trail.category,
                  radius: 0,
                  emojiSize: 56,
                  emojiAlignment: const Alignment(0, -0.62)),
              const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.photoScrim)),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trail.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${TrailCategory.labels[trail.category] ?? '일반'} · by ${trail.ownerName}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text('${trail.walkCount}명이 이 길을 걸었어요',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white),
                    child: RatingStars(rating: trail.ratingAvg, size: 16),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        const _Heading('산책 정보'),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            InfoPill(icon: Icons.straighten, label: formatDistance(trail.distanceM)),
            const SizedBox(width: 10),
            InfoPill(icon: Icons.schedule, label: '도보 ${formatMinutes(trail.durationMin)}'),
            const SizedBox(width: 10),
            InfoPill(icon: Icons.directions_walk, label: '${trail.walkCount}회'),
            const SizedBox(width: 10),
            InfoPill(icon: Icons.favorite_border, label: '관심 ${trail.favoriteCount}'),
          ]),
        ),

        if (trail.description.isNotEmpty || trail.tags.isNotEmpty) ...[
          const _Heading('소개'),
          if (trail.description.isNotEmpty)
            Text(trail.description,
                style: const TextStyle(height: 1.7, fontSize: 14, color: Color(0xFF3A3A3A))),
          if (trail.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in trail.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('#$t', style: const TextStyle(fontSize: 13)),
                ),
            ]),
          ],
        ],

        const _Heading('경로'),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit:
                    CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
              ),
              children: [
                const OsmTileLayer(),
                PolylineLayer(polylines: [
                  Polyline(
                      points: trail.path,
                      strokeWidth: 5,
                      color: AppColors.black,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: trail.path.first,
                    width: 32,
                    height: 32,
                    child: const _MapPin(color: AppColors.yellow500, icon: Icons.flag_rounded),
                  ),
                  Marker(
                    point: trail.path.last,
                    width: 32,
                    height: 32,
                    child: const _MapPin(color: AppColors.black, icon: Icons.sports_score),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ReviewSection(trail: trail),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -6))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
            child: Row(children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                    text: formatDistance(trail.distanceM),
                    style: const TextStyle(
                        color: AppColors.orange, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' / 도보 ${formatMinutes(trail.durationMin)}',
                    style: const TextStyle(color: AppColors.grey400, fontSize: 13),
                  ),
                ])),
              ),
              SizedBox(
                width: 170,
                child: FilledButton(
                  onPressed: () => context.push('/trail/${trail.id}/walk'),
                  child: const Text('산책 시작'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 14),
        child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
      );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
        ),
        child: Icon(icon,
            size: 16, color: color == AppColors.black ? Colors.white : AppColors.black),
      );
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.trail});
  final Trail trail;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: TrailService.instance.watchFavoriteIds(),
      builder: (context, snap) {
        final fav = snap.data?.contains(trail.id) ?? false;
        return IconButton(
          tooltip: fav ? '관심목록에서 제거' : '관심목록에 추가',
          icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? AppColors.orange : null),
          onPressed: () async {
            try {
              await TrailService.instance.toggleFavorite(trail, fav);
            } catch (e) {
              if (context.mounted) showSnack(context, friendlyError(e));
            }
          },
        );
      },
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.trail});
  final Trail trail;

  Future<void> _write(BuildContext context, Review? mine) async {
    var rating = mine?.rating ?? 5;
    final ctrl = TextEditingController(text: mine?.text ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('리뷰 작성'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            StarPicker(value: rating, onChanged: (v) => setState(() => rating = v)),
            TextField(
              controller: ctrl,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '산책로는 어떠셨나요?'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('등록')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await TrailService.instance.saveReview(trail.id, rating, ctrl.text);
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService.instance.user?.uid;
    return StreamBuilder<List<Review>>(
      stream: TrailService.instance.watchReviews(trail.id),
      builder: (context, snap) {
        final reviews = snap.data ?? [];
        final mine = reviews.where((r) => r.uid == myUid).firstOrNull;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Row(children: [
              Text('리뷰 (${trail.ratingCount})',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.star_rounded, color: AppColors.yellow500, size: 22),
              const SizedBox(width: 4),
              Text(trail.ratingAvg.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            onPressed: () => _write(context, mine),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: Text(mine == null ? '리뷰 쓰기' : '내 리뷰 수정'),
          ),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('첫 리뷰를 남겨주세요!', style: TextStyle(color: AppColors.grey400)),
            ),
          for (final r in reviews)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.grey100,
                  child: Text(r.authorName.isEmpty ? '?' : r.authorName.characters.first,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.black)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(r.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      Text(fmtDate(r.createdAt),
                          style: const TextStyle(color: AppColors.grey300, fontSize: 12)),
                      if (r.uid == myUid || AuthService.instance.isAdmin)
                        GestureDetector(
                          onTap: () async {
                            if (!await confirmDialog(context, '리뷰 삭제', '리뷰를 삭제할까요?')) return;
                            try {
                              await TrailService.instance.deleteReview(trail.id, uid: r.uid);
                            } catch (e) {
                              if (context.mounted) showSnack(context, friendlyError(e));
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.close, size: 16, color: AppColors.grey300),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    RatingStars(rating: r.rating.toDouble(), showValue: false, size: 15),
                    if (r.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.text, style: const TextStyle(height: 1.5, color: Color(0xFF3A3A3A))),
                    ],
                  ]),
                ),
              ]),
            ),
        ]);
      },
    );
  }
}
