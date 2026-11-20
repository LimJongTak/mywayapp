import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/facility.dart';
import '../../models/trail.dart';
import '../../services/location_service.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';
import '../../widgets/map_tiles.dart';

/// 홈 — 지도에서 산책로(사진+평점 마커)와 주변 편의시설을 한눈에
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum _Filter { toilet, shelter, bike, trail, favorite }

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  final _filters = <_Filter>{_Filter.trail};
  List<Trail> _trails = [];
  List<Facility> _facilities = [];
  Set<String> _favIds = {};
  LatLng? _me;
  Trail? _selected;
  final _subs = <StreamSubscription>[];

  static const _seoul = LatLng(37.5796, 126.9770);

  @override
  void initState() {
    super.initState();
    final svc = TrailService.instance;
    _subs.add(svc.watchRecent().listen((t) => setState(() => _trails = t)));
    _subs.add(svc.watchFacilities().listen((f) => setState(() => _facilities = f)));
    _subs.add(svc.watchFavoriteIds().listen((f) => setState(() => _favIds = f)));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _search.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    try {
      final p = await LocationService.current();
      setState(() => _me = p);
      _map.move(p, 16);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  List<Trail> get _visibleTrails {
    final q = _search.text.trim().replaceAll('#', '');
    Iterable<Trail> list = _trails;
    if (_filters.contains(_Filter.favorite)) {
      list = list.where((t) => _favIds.contains(t.id));
    } else if (!_filters.contains(_Filter.trail)) {
      return [];
    }
    if (q.isNotEmpty) {
      list = list.where((t) => t.title.contains(q) || t.tags.any((tag) => tag.contains(q)));
    }
    return list.toList();
  }

  void _onSearch() {
    final results = _visibleTrails;
    if (results.isEmpty) {
      showSnack(context, '검색 결과가 없습니다.');
      return;
    }
    setState(() => _selected = results.first);
    _map.move(results.first.start, 16);
  }

  @override
  Widget build(BuildContext context) {
    final trails = _visibleTrails;
    final facilityTypes = {
      if (_filters.contains(_Filter.toilet)) FacilityType.toilet,
      if (_filters.contains(_Filter.shelter)) FacilityType.shelter,
      if (_filters.contains(_Filter.bike)) FacilityType.bike,
    };
    final facilities = _facilities.where((f) => facilityTypes.contains(f.type));

    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _seoul,
            initialZoom: 15,
            onTap: (_, _) => setState(() => _selected = null),
          ),
          children: [
            const OsmTileLayer(),
            if (_selected != null)
              PolylineLayer(polylines: [
                Polyline(points: _selected!.path, strokeWidth: 5, color: AppColors.primary),
              ]),
            MarkerLayer(markers: [
              for (final f in facilities)
                Marker(
                  point: f.location,
                  width: 34,
                  height: 34,
                  child: Tooltip(message: f.name, child: _FacilityPin(type: f.type)),
                ),
              for (final t in trails)
                Marker(
                  point: t.start,
                  width: 64,
                  height: 78,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = t),
                    child: _TrailPin(trail: t, selected: _selected?.id == t.id),
                  ),
                ),
              if (_me != null)
                Marker(
                  point: _me!,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
                    ),
                  ),
                ),
            ]),
            const OsmAttribution(),
          ],
        ),
        // 상단 검색 + 필터 칩
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearch(),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '산책로 이름이나 #태그를 검색하세요.',
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _chip(_Filter.toilet, Icons.wc, '화장실'),
                  _chip(_Filter.shelter, Icons.chair_outlined, '쉼터'),
                  _chip(_Filter.bike, Icons.pedal_bike, '자전거'),
                  _chip(_Filter.trail, Icons.directions_walk, '산책로'),
                  _chip(_Filter.favorite, Icons.favorite, '관심목록'),
                ]),
              ),
            ]),
          ),
        ),
        // 좌하단 메뉴 / 우하단 내 위치
        Positioned(
          left: 12,
          bottom: _selected == null ? 16 : 150,
          child: _MapMenu(),
        ),
        Positioned(
          right: 12,
          bottom: _selected == null ? 16 : 150,
          child: FloatingActionButton.small(
            heroTag: 'locate',
            tooltip: '내 위치',
            backgroundColor: Colors.white,
            onPressed: _locateMe,
            child: const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),
        if (_selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: TrailCard(
                trail: _selected!,
                onTap: () => context.push('/trail/${_selected!.id}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _chip(_Filter f, IconData icon, String label) {
    final on = _filters.contains(f);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: on,
        showCheckmark: false,
        avatar: Icon(icon, size: 18, color: on ? Colors.white : AppColors.primary),
        label: Text(label),
        labelStyle: TextStyle(color: on ? Colors.white : Colors.black87),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        shape: const StadiumBorder(),
        onSelected: (v) => setState(() => v ? _filters.add(f) : _filters.remove(f)),
      ),
    );
  }
}

class _MapMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '산책로 메뉴',
      position: PopupMenuPosition.over,
      offset: const Offset(0, -120),
      onSelected: (v) => context.push(v),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: '/trail/record',
          child: ListTile(
            leading: Icon(Icons.play_arrow, color: AppColors.primary),
            title: Text('산책로 등록 시작 / 종료'),
          ),
        ),
        PopupMenuItem(
          value: '/trails',
          child: ListTile(
            leading: Icon(Icons.list_alt, color: AppColors.primary),
            title: Text('산책로 목록'),
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: const Icon(Icons.menu, color: AppColors.primary),
      ),
    );
  }
}

/// 원형 사진 + 평점 마커 (기획서 지도 화면)
class _TrailPin extends StatelessWidget {
  const _TrailPin({required this.trail, required this.selected});
  final Trail trail;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 56.0 : 48.0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? AppColors.primary : Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          gradient: AppColors.brandGradient,
          image: trail.photoUrl == null
              ? null
              : DecorationImage(
                  image: CachedNetworkImageProvider(trail.photoUrl!), fit: BoxFit.cover),
        ),
        child: trail.photoUrl == null
            ? const Icon(Icons.directions_walk, color: Colors.white)
            : null,
      ),
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: RatingBadge(rating: trail.ratingAvg),
      ),
    ]);
  }
}

class _FacilityPin extends StatelessWidget {
  const _FacilityPin({required this.type});
  final FacilityType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      FacilityType.toilet => (Icons.wc, Colors.teal),
      FacilityType.shelter => (Icons.chair, Colors.brown),
      FacilityType.bike => (Icons.pedal_bike, Colors.green),
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
