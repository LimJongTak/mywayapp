import 'package:cached_network_image/cached_network_image.dart';
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
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: trail.photoUrl == null ? null : 240,
          flexibleSpace: trail.photoUrl == null
              ? null
              : FlexibleSpaceBar(
                  background: CachedNetworkImage(imageUrl: trail.photoUrl!, fit: BoxFit.cover),
                ),
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
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            Row(children: [
              Expanded(
                child: Text(trail.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              Chip(label: Text(TrailCategory.labels[trail.category] ?? '일반')),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              RatingBadge(rating: trail.ratingAvg, count: trail.ratingCount),
              const SizedBox(width: 12),
              Text('by ${trail.ownerName}', style: const TextStyle(color: Colors.black54)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _Stat(icon: Icons.straighten, label: '거리', value: formatDistance(trail.distanceM)),
              _Stat(icon: Icons.timer_outlined, label: '도보', value: formatMinutes(trail.durationMin)),
              _Stat(icon: Icons.directions_walk, label: '걸은 횟수', value: '${trail.walkCount}회'),
              _Stat(icon: Icons.favorite_border, label: '관심', value: '${trail.favoriteCount}'),
            ]),
            const SizedBox(height: 16),
            if (trail.description.isNotEmpty) Text(trail.description, style: const TextStyle(height: 1.5)),
            if (trail.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (final t in trail.tags)
                  Text('#$t', style: const TextStyle(color: AppColors.primary)),
              ]),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                        bounds: bounds, padding: const EdgeInsets.all(32)),
                  ),
                  children: [
                    const OsmTileLayer(),
                    PolylineLayer(polylines: [
                      Polyline(points: trail.path, strokeWidth: 5, color: AppColors.primary),
                    ]),
                    MarkerLayer(markers: [
                      Marker(
                          point: trail.path.first,
                          child: const Icon(Icons.flag, color: Colors.green)),
                      Marker(
                          point: trail.path.last,
                          child: const Icon(Icons.sports_score, color: Colors.red)),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/trail/${trail.id}/walk'),
              icon: const Icon(Icons.directions_walk),
              label: const Text('이 산책로 걷기 (포인트 적립)'),
            ),
            const SizedBox(height: 24),
            _ReviewSection(trail: trail),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: AppColors.primary),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]),
    );
  }
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
          icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.red : null),
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
          Row(children: [
            Text('리뷰 ${trail.ratingCount}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _write(context, mine),
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(mine == null ? '리뷰 쓰기' : '내 리뷰 수정'),
            ),
          ]),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('첫 리뷰를 남겨주세요!', style: TextStyle(color: Colors.black54)),
            ),
          for (final r in reviews)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(children: [
                Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                ...List.generate(
                    5,
                    (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14, color: AppColors.star)),
              ]),
              subtitle: Text(r.text.isEmpty ? fmtDate(r.createdAt) : '${r.text}\n${fmtDate(r.createdAt)}'),
              trailing: r.uid == myUid || AuthService.instance.isAdmin
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        if (!await confirmDialog(context, '리뷰 삭제', '리뷰를 삭제할까요?')) return;
                        try {
                          await TrailService.instance.deleteReview(trail.id, uid: r.uid);
                        } catch (e) {
                          if (context.mounted) showSnack(context, friendlyError(e));
                        }
                      },
                    )
                  : null,
            ),
        ]);
      },
    );
  }
}
