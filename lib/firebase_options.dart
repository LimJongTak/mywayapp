// ⚠️ 이 파일은 `flutterfire configure` 명령으로 자동 생성/덮어쓰기 됩니다.
// 아래 값은 자리표시자이며, 실제 Firebase 프로젝트 값으로 교체해야 합니다.
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// API 키 등은 클라이언트 식별용 공개 값이며, 실제 보안은
// Firestore/Storage 보안 규칙 + App Check + Cloud Functions 검증으로 보장합니다.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('이 플랫폼은 지원하지 않습니다.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-myway',
    authDomain: 'demo-myway.firebaseapp.com',
    storageBucket: 'demo-myway.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-myway',
    storageBucket: 'demo-myway.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-myway',
    storageBucket: 'demo-myway.appspot.com',
    iosBundleId: 'uk.mywayapp.myway',
  );
}
