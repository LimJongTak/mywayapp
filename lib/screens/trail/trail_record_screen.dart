import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/geo.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../widgets/map_tiles.dart';

enum RecordMode { draw, gps }

/// 산책로 등록 — 지도에 직접 경로 찍기 / GPS로 걸으며 기록
class TrailRecordScreen extends StatefulWidget {
  const TrailRecordScreen({super.key});

  @override
  State<TrailRecordScreen> createState() => _TrailRecordScreenState();
}

class _TrailRecordScreenState extends State<TrailRecordScreen> {
  final _map = MapController();
  RecordMode _mode = RecordMode.draw;
  final List<LatLng> _points = [];
  StreamSubscription<LatLng>? _gpsSub;
  bool get _recording => _gpsSub != null;

  @override
  void initState() {
    super.initState();
    // 현재 위치로 이동 (실패해도 기본 위치 사용)
    LocationService.current().then((p) {
      if (mounted) _map.move(p, 17);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  void _startGps() {
    setState(() {
      _points.clear();
      _gpsSub = LocationService.track().listen(
        (p) {
          // 순간이동(GPS 튐) 필터: 직전 지점에서 100m 이상 점프는 무시
          if (_points.isNotEmpty && distanceM(_points.last, p) > 100) return;
          setState(() => _points.add(p));
          _map.move(p, _map.camera.zoom);
        },
        onError: (Object e) {
          _stopGps();
          if (mounted) showSnack(context, friendlyError(e));
        },
      );
    });
  }

  void _stopGps() {
    _gpsSub?.cancel();
    setState(() => _gpsSub = null);
  }

  void _next() {
    final dist = pathDistanceM(_points);
    if (_points.length < 2 || dist < 50) {
      showSnack(context, '산책로는 50m 이상이어야 합니다.');
      return;
    }
    if (_points.length > 5000) {
      showSnack(context, '경로가 너무 깁니다.');
      return;
    }
    context.push('/trail/new', extra: List<LatLng>.of(_points));
  }

  @override
  Widget build(BuildContext context) {
    final total = pathDistanceM(_points);
    final showLabels = _mode == RecordMode.draw && _points.length <= 40;
    return Scaffold(
      appBar: AppBar(title: const Text('산책로 등록')),
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: const LatLng(37.5796, 126.9770),
            initialZoom: 16,
            onTap: (_, p) {
              if (_mode == RecordMode.draw) setState(() => _points.add(p));
            },
          ),
          children: [
            const OsmTileLayer(),
            PolylineLayer(polylines: [
              Polyline(points: _points, strokeWidth: 4, color: Colors.red.shade700),
            ]),
            MarkerLayer(markers: [
              if (showLabels)
                for (var i = 1; i < _points.length; i++) distanceLabel(_points[i - 1], _points[i]),
              if (_mode == RecordMode.draw)
                for (final p in _points)
                  Marker(
                    point: p,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.shade700, width: 2),
                      ),
                    ),
                  ),
              if (_points.length >= 2)
                Marker(
                  point: _points.last,
                  width: 120,
                  height: 44,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      '총거리 ${formatDistance(total)}\n도보 ${formatMinutes(walkingMinutes(total))}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
            ]),
            const OsmAttribution(),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Center(
            child: SegmentedButton<RecordMode>(
              style: SegmentedButton.styleFrom(backgroundColor: Colors.white),
              segments: const [
                ButtonSegment(
                    value: RecordMode.draw, icon: Icon(Icons.touch_app), label: Text('지도에 그리기')),
                ButtonSegment(
                    value: RecordMode.gps, icon: Icon(Icons.gps_fixed), label: Text('걸으며 기록')),
              ],
              selected: {_mode},
              onSelectionChanged: _recording
                  ? null
                  : (s) => setState(() {
                        _mode = s.first;
                        _points.clear();
                      }),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              _mode == RecordMode.draw
                  ? '지도를 눌러 산책로 경로를 순서대로 찍어주세요.'
                  : (_recording ? '기록 중... 산책로를 따라 걸어주세요.' : '시작을 누르고 산책로를 걸어주세요.'),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text('${formatDistance(total)} · 도보 약 ${formatMinutes(walkingMinutes(total))}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              if (_mode == RecordMode.draw) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: _points.isEmpty ? null : () => setState(_points.removeLast),
                    icon: const Icon(Icons.undo),
                    label: const Text('되돌리기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: _points.isEmpty ? null : () => setState(_points.clear),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('초기화'),
                  ),
                ),
              ] else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _recording ? _stopGps : _startGps,
                    icon: Icon(_recording ? Icons.stop : Icons.play_arrow),
                    label: Text(_recording ? '기록 종료' : '기록 시작'),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40), backgroundColor: AppColors.primary),
                  onPressed: _recording ? null : _next,
                  child: const Text('다음'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
