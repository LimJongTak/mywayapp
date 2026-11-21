import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firebase_refs.dart';

/// 로컬 개발: flutter run --dart-define=USE_EMULATOR=true
const _useEmulator = bool.fromEnvironment('USE_EMULATOR');

/// 실제 기기에서 PC의 에뮬레이터에 붙을 때: --dart-define=EMULATOR_HOST=192.168.0.10
const _emulatorHost = String.fromEnvironment('EMULATOR_HOST');

/// 웹 App Check 용 reCAPTCHA v3 사이트 키: --dart-define=RECAPTCHA_SITE_KEY=...
const _recaptchaKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR');

  // App Check: 정식 앱에서 온 요청만 백엔드(Functions/Firestore/Storage)에 접근
  if (!_useEmulator && (!kIsWeb || _recaptchaKey.isNotEmpty)) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb ? ReCaptchaV3Provider(_recaptchaKey) : null,
      providerAndroid:
          kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }

  if (_useEmulator) {
    // Android 에뮬레이터는 10.0.2.2 로 PC에 접속. 실제 폰은 --dart-define=EMULATOR_HOST=<PC의 IP>
    final host = _emulatorHost.isNotEmpty
        ? _emulatorHost
        : (defaultTargetPlatform == TargetPlatform.android && !kIsWeb ? '10.0.2.2' : 'localhost');
    await Fb.auth.useAuthEmulator(host, 9099);
    Fb.db.useFirestoreEmulator(host, 8080);
    Fb.functions.useFunctionsEmulator(host, 5001);
    await Fb.storage.useStorageEmulator(host, 9199);
  } else {
    Fb.db.settings = const Settings(persistenceEnabled: true);
  }

  runApp(const MyWayApp());
}
