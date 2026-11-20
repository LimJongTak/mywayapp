import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/geo.dart';
import '../core/theme.dart';
import '../models/trail.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => AppColors.brandGradient.createShader(r),
      child: Text('MyWay',
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

/// 상단 네이비 배너 "' 산책이 일상으로 '"
class SloganBanner extends StatelessWidget {
  const SloganBanner({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ShaderMask(
              shaderCallback: (r) => AppColors.brandGradient.createShader(r),
              child: const Text("' 산책이 일상으로 '",
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.count});
  final double rating;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
      const SizedBox(width: 2),
      Text(rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      if (count != null) Text(' ($count)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}

class TrailThumb extends StatelessWidget {
  const TrailThumb({super.key, required this.url, this.size = 64, this.radius = 8});
  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.directions_walk, color: Colors.white, size: size * 0.5),
    );
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

class TrailCard extends StatelessWidget {
  const TrailCard({super.key, required this.trail, this.onTap, this.trailing});
  final Trail trail;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            TrailThumb(url: trail.photoUrl, size: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trail.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(trail.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  RatingBadge(rating: trail.ratingAvg, count: trail.ratingCount),
                  const SizedBox(width: 8),
                  Text('${formatDistance(trail.distanceM)} · 도보 ${formatMinutes(trail.durationMin)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
                if (trail.tags.isNotEmpty)
                  Text(trail.tags.map((t) => '#$t').join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ]),
            ),
            ?trailing,
          ]),
        ),
      ),
    );
  }
}

class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          tooltip: '${i + 1}점',
          onPressed: () => onChanged(i + 1),
          icon: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.star, size: 32),
        );
      }),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

/// Stream 로딩/에러/빈 상태 처리 공통 위젯
class StreamView<T> extends StatelessWidget {
  const StreamView({
    super.key,
    required this.stream,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = '데이터가 없습니다.',
  });
  final Stream<T> stream;
  final Widget Function(BuildContext, T) builder;
  final bool Function(T)? isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const EmptyView(message: '불러오지 못했습니다.', icon: Icons.error_outline);
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data as T;
        if (isEmpty?.call(data) ?? false) return EmptyView(message: emptyMessage);
        return builder(context, data);
      },
    );
  }
}

final _dateFmt = DateFormat('yyyy.MM.dd', 'ko_KR');
final _dateTimeFmt = DateFormat('yyyy.MM.dd HH:mm', 'ko_KR');
String fmtDate(DateTime? d) => d == null ? '' : _dateFmt.format(d);
String fmtDateTime(DateTime? d) => d == null ? '' : _dateTimeFmt.format(d);
