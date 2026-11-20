import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

const _distance = Distance();

/// 두 지점 사이 거리 (m)
double distanceM(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

/// 경로 전체 거리 (m)
double pathDistanceM(List<LatLng> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += distanceM(path[i - 1], path[i]);
  }
  return total;
}

/// 도보 예상 시간 (분) — 평균 보행 속도 4km/h (약 67m/분)
int walkingMinutes(double meters) => math.max(1, (meters / 67).round());

String formatDistance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)}km'
    : '${meters.round()}m';

String formatMinutes(int min) =>
    min >= 60 ? '${min ~/ 60}시간 ${min % 60}분' : '$min분';

LatLng midpoint(LatLng a, LatLng b) =>
    LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);

/// 너무 촘촘한 GPS 포인트를 간격 기준으로 줄인다 (저장 용량/비용 절감)
List<LatLng> simplifyByDistance(List<LatLng> path, double minGapM) {
  if (path.length <= 2) return List.of(path);
  final out = <LatLng>[path.first];
  for (var i = 1; i < path.length - 1; i++) {
    if (distanceM(out.last, path[i]) >= minGapM) out.add(path[i]);
  }
  out.add(path.last);
  return out;
}
