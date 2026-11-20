import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/errors.dart';

class LocationService {
  /// 위치 권한 확인/요청. 실패 시 사용자에게 보여줄 메시지를 던진다.
  static Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw AppException('위치 서비스(GPS)를 켜주세요.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw AppException('위치 권한이 필요합니다. 설정에서 허용해주세요.');
    }
  }

  static Future<LatLng> current() async {
    await ensurePermission();
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(p.latitude, p.longitude);
  }

  /// 산책 기록용 위치 스트림 (5m 이동마다, 정확도 낮은 값은 걸러냄)
  static Stream<LatLng> track() async* {
    await ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).where((p) => p.accuracy <= 30).map((p) => LatLng(p.latitude, p.longitude));
  }
}
