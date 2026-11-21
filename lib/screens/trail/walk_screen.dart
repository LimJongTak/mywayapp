import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/geo.dart';
import '../../core/theme.dart';
import '../../models/trail.dart';
import '../../services/location_service.dart';
import '../../services/trail_service.dart';
import '../../widgets/map_tiles.dart';

/// 산책로 따라 걷기 → 완료 시 서버 검증 후 포인트 적립
class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key, required this.trailId});
  final String trailId;

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {
  final _map = MapController();
  Trail? _trail;
  final List<LatLng> _walked = [];
  StreamSubscription<LatLng>? _sub;
  DateTime? _startedAt;
  Timer? _ticker;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    TrailService.instance.watch(widget.trailId).first.then((t) {
      if (mounted) setState(() => _trail = t);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _walked.clear();
      _startedAt = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      _sub = LocationService.track().listen(
        (p) {
          if (_walked.isNotEmpty && distanceM(_walked.last, p) > 100) return;
          setState(() => _walked.add(p));
          _map.move(p, _map.camera.zoom);
        },
        onError: (Object e) {
          _cancel();
          if (mounted) showSnack(context, friendlyError(e));
        },
      );
    });
  }

  void _cancel() {
    _sub?.cancel();
    _ticker?.cancel();
    setState(() {
      _sub = null;
      _ticker = null;
      _startedAt = null;
    });
  }

  Future<void> _finish() async {
    final started = _startedAt!;
    _sub?.cancel();
    _ticker?.cancel();
    setState(() => _submitting = true);
    try {
      final r = await TrailService.instance.completeWalk(
        trailId: widget.trailId,
        walked: _walked,
        startedAt: started,
        endedAt: DateTime.now(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(r.points > 0 ? Icons.celebration : Icons.info_outline,
              size: 48, color: r.points > 0 ? AppColors.star : Colors.grey),
          title: Text(r.points > 0 ? '+${r.points}P 적립!' : (r.verified ? '산책 완료' : '산책 미인정')),
          content: Text('${r.message}\n이동 거리: ${formatDistance(r.distanceM.toDouble())}'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _sub = null;
          _ticker = null;
          _startedAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trail = _trail;
    if (trail == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final walking = _startedAt != null;
    final elapsed = walking ? DateTime.now().difference(_startedAt!) : Duration.zero;
    final walkedM = pathDistanceM(_walked);
    final progress = (walkedM / trail.distanceM).clamp(0.0, 1.0);

    return PopScope(
      canPop: !walking,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmDialog(context, '산책 중단', '기록 중인 산책을 중단할까요?')) {
          _cancel();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(trail.title)),
        body: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(trail.path), padding: const EdgeInsets.all(48)),
          ),
          children: [
            const OsmTileLayer(),
            PolylineLayer(polylines: [
              Polyline(
                  points: trail.path,
                  strokeWidth: 8,
                  color: AppColors.yellow500.withValues(alpha: 0.8)),
              Polyline(points: _walked, strokeWidth: 4, color: AppColors.black),
            ]),
            MarkerLayer(markers: [
              Marker(point: trail.path.first, child: const Icon(Icons.flag, color: Colors.green)),
              if (_walked.isNotEmpty)
                Marker(
                  point: _walked.last,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ]),
            const OsmAttribution(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _metric('시간',
                    '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}'),
                _metric('이동', formatDistance(walkedM)),
                _metric('목표', formatDistance(trail.distanceM)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: AppColors.yellow500,
                  backgroundColor: AppColors.grey100,
                ),
              ),
              const SizedBox(height: 12),
              if (!walking)
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('산책 시작'),
                )
              else
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: _submitting ? null : _cancel,
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting ? null : _finish,
                      child: _submitting
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('산책 완료'),
                    ),
                  ),
                ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => Column(children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ]);
}
