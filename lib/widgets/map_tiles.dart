import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../core/geo.dart';

/// OpenStreetMap 타일 (API 키 불필요).
/// 대규모 서비스 시에는 OSM 타일 사용 정책에 따라 상용 타일 서버로 교체하세요.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'uk.mywayapp.myway',
      maxZoom: 19,
    );
  }
}

class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(2),
        child: ColoredBox(
          color: Color(0xCCFFFFFF),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text('© OpenStreetMap', style: TextStyle(fontSize: 10, color: Colors.black54)),
          ),
        ),
      ),
    );
  }
}

/// 구간 거리 라벨 마커 ("거리 375m")
Marker distanceLabel(LatLng a, LatLng b) => Marker(
      point: midpoint(a, b),
      width: 90,
      height: 24,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text.rich(TextSpan(children: [
          const TextSpan(text: '거리 ', style: TextStyle(fontSize: 11)),
          TextSpan(
            text: formatDistance(distanceM(a, b)),
            style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w700),
          ),
        ])),
      ),
    );
