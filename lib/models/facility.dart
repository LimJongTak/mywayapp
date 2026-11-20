import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum FacilityType {
  toilet('화장실'),
  shelter('쉼터'),
  bike('자전거');

  const FacilityType(this.label);
  final String label;
}

class Facility {
  Facility({required this.id, required this.type, required this.name, required this.location});

  final String id;
  final FacilityType type;
  final String name;
  final LatLng location;

  static Facility? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    final type = FacilityType.values.where((t) => t.name == d['type']).firstOrNull;
    final g = d['location'];
    if (type == null || g is! GeoPoint) return null;
    return Facility(
      id: doc.id,
      type: type,
      name: d['name'] as String? ?? type.label,
      location: LatLng(g.latitude, g.longitude),
    );
  }
}
