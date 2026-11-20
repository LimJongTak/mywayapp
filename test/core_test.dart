import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:myway/core/geo.dart';
import 'package:myway/core/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('nope'), isNotNull);
    });
    test('password needs letters+digits, 8+', () {
      expect(Validators.password('abcd1234'), isNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('ab12'), isNotNull);
    });
    test('nickname', () {
      expect(Validators.nickname('산책왕_01'), isNull);
      expect(Validators.nickname('<b>'), isNotNull);
    });
    test('parseTags dedupes and strips #', () {
      expect(Validators.parseTags('#노을뷰 #산책로, 노을뷰  데이트'), ['노을뷰', '산책로', '데이트']);
    });
  });

  group('geo', () {
    test('distance ~111m per 0.001 deg', () {
      final d = distanceM(const LatLng(37, 127), const LatLng(37.001, 127));
      expect(d, closeTo(111, 1.5));
    });
    test('walking minutes at 4km/h', () {
      expect(walkingMinutes(670), 10);
      expect(walkingMinutes(0), 1);
    });
    test('format', () {
      expect(formatDistance(697), '697m');
      expect(formatDistance(1500), '1.5km');
      expect(formatMinutes(75), '1시간 15분');
    });
    test('simplify keeps endpoints and drops dense points', () {
      final path = List.generate(100, (i) => LatLng(37 + i * 0.00001, 127)); // ~1.1m 간격
      final s = simplifyByDistance(path, 5);
      expect(s.first, path.first);
      expect(s.last, path.last);
      expect(s.length, lessThan(30));
    });
  });
}
