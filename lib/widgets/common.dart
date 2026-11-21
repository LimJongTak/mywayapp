import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/geo.dart';
import '../core/theme.dart';
import '../models/trail.dart';

/// "MyWay" 워드마크 — 검정 글자 + 노란 포인트 (Figma 로고 스타일)
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Text('myway',
          style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
              letterSpacing: -0.5)),
      Positioned(
        top: size * 0.12,
        left: size * 1.64,
        child: Container(
          width: size * 0.26,
          height: size * 0.26,
          decoration: const BoxDecoration(color: AppColors.yellow500, shape: BoxShape.circle),
        ),
      ),
    ]);
  }
}

/// 큰 제목 헤더 (예: "Your Profile")
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.trailing, this.padding});
  final String text;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
        ),
        ?trailing,
      ]),
    );
  }
}

/// 섹션 제목 + 우측 "전체보기"
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
      child: Row(children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}

/// 회색 배경 검색창 (우측 돋보기)
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hint = '산책로를 검색해보세요',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.onClear,
  });
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final none = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    );
    final hasText = controller?.text.isNotEmpty ?? false;
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        fillColor: AppColors.grey100,
        border: none,
        enabledBorder: none,
        focusedBorder: none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixIcon: hasText && onClear != null
            ? IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onClear)
            : const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.search, color: AppColors.black),
              ),
      ),
    );
  }
}

/// 별 5개 평점 (노란 별)
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 14, this.showValue = true});
  final double rating;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 5; i++)
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(Icons.star_rounded,
              size: size, color: i < rating.round() ? AppColors.yellow500 : AppColors.grey200),
        ),
      if (showValue) ...[
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1),
            style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w600)),
      ],
    ]);
  }
}

/// 별 1개 + 숫자 (마커 등 좁은 곳)
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.count, this.color});
  final double rating;
  final int? count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, size: 16, color: AppColors.yellow500),
      const SizedBox(width: 2),
      Text(rating.toStringAsFixed(1),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      if (count != null)
        Text(' ($count)', style: TextStyle(fontSize: 12, color: color ?? AppColors.grey400)),
    ]);
  }
}

/// 카테고리별 대표 이모지 (사진이 없을 때 표시)
const categoryEmoji = {
  'general': '🚶',
  'dog': '🐕',
  'night': '🌃',
  'nature': '🌲',
  'city': '🏙️',
  'family': '🧺',
};

/// 산책로 사진 (없으면 카테고리 이모지 플레이스홀더)
class TrailPhoto extends StatelessWidget {
  const TrailPhoto({
    super.key,
    required this.url,
    this.category = 'general',
    this.width,
    this.height,
    this.radius = AppRadius.sm,
    this.emojiSize = 32,
    this.emojiAlignment = Alignment.center,
  });
  final String? url;
  final String category;
  final Alignment emojiAlignment;
  final double? width;
  final double? height;
  final double radius;
  final double emojiSize;

  static const _bg = {
    'general': Color(0xFFFEF3B2),
    'dog': Color(0xFFFFE3D3),
    'night': Color(0xFF2B2D42),
    'nature': Color(0xFFD1FCDA),
    'city': Color(0xFFD0E7FF),
    'family': Color(0xFFFEEAD2),
  };

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      alignment: emojiAlignment,
      color: _bg[category] ?? AppColors.yellow200,
      child: Text(categoryEmoji[category] ?? '🚶', style: TextStyle(fontSize: emojiSize)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}

/// 하위 호환: 정사각 썸네일
class TrailThumb extends StatelessWidget {
  const TrailThumb({super.key, required this.url, this.size = 64, this.radius = 8});
  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      TrailPhoto(url: url, width: size, height: size, radius: radius, emojiSize: size * 0.4);
}

/// 목록형 카드 — 좌측 사진 + 제목/거리/별점/설명 + 우측 하트 (Figma "Popular Package")
class TrailCard extends StatelessWidget {
  const TrailCard({
    super.key,
    required this.trail,
    this.onTap,
    this.trailing,
    this.favorite,
    this.onFavorite,
  });
  final Trail trail;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool? favorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TrailPhoto(
                  url: trail.photoUrl, category: trail.category, width: 86, height: 116),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(trail.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                    ),
                    if (favorite != null)
                      GestureDetector(
                        onTap: onFavorite,
                        child: Icon(favorite! ? Icons.favorite : Icons.favorite_border,
                            size: 22, color: favorite! ? AppColors.orange : AppColors.grey300),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    '${formatDistance(trail.distanceM)} · 도보 ${formatMinutes(trail.durationMin)}',
                    style: const TextStyle(
                        color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  RatingStars(rating: trail.ratingAvg),
                  const SizedBox(height: 6),
                  Text(
                    trail.description.isNotEmpty
                        ? trail.description
                        : trail.tags.map((t) => '#$t').join(' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grey400, fontSize: 13, height: 1.5),
                  ),
                ]),
              ),
              ?trailing,
            ]),
          ),
        ),
      ),
    );
  }
}

/// 큰 사진 카드 — 사진 위 제목/위치/별점 (Figma "Favorite Place")
class TrailFeatureCard extends StatelessWidget {
  const TrailFeatureCard({
    super.key,
    required this.trail,
    this.onTap,
    this.favorite = false,
    this.onFavorite,
    this.width = 186,
    this.height = 246,
  });
  final Trail trail;
  final VoidCallback? onTap;
  final bool favorite;
  final VoidCallback? onFavorite;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(fit: StackFit.expand, children: [
            TrailPhoto(
                url: trail.photoUrl,
                category: trail.category,
                radius: 0,
                emojiSize: 64,
                emojiAlignment: const Alignment(0, -0.35)),
            const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.photoScrim)),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onFavorite,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(favorite ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: favorite ? AppColors.orange : AppColors.grey400),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trail.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.place_outlined, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${formatDistance(trail.distanceM)} · ${TrailCategory.labels[trail.category]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white),
                  child: RatingStars(rating: trail.ratingAvg, size: 15),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 이모지 + 라벨 알약형 카테고리 칩 (Figma "Choose Category")
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.emoji,
    required this.label,
    this.selected = false,
    this.onTap,
  });
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? AppColors.black : AppColors.grey200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.black)),
        ]),
      ),
    );
  }
}

/// 테두리 둥근 메뉴 항목 (Figma 프로필 메뉴)
class MenuTile extends StatelessWidget {
  const MenuTile({super.key, required this.title, required this.icon, this.onTap, this.trailing});
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              trailing ?? Icon(icon, size: 22, color: AppColors.black),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 아이콘 + 라벨 정보 칩 (Figma "What's Included?")
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 20, color: AppColors.yellow700),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ]),
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
        return IconButton(
          tooltip: '${i + 1}점',
          onPressed: () => onChanged(i + 1),
          icon: Icon(Icons.star_rounded,
              color: i < value ? AppColors.yellow500 : AppColors.grey200, size: 34),
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
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.yellow100, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.yellow700),
          ),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey400, height: 1.5)),
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
