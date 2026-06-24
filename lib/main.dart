import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:device_preview/device_preview.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (contex) => const ApartHubResidenceApp(),
    ),
  );
}
