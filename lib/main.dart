import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/hive_storage_service.dart';
import 'core/storage/preferences_service.dart';
import 'features/server_config/data/models/server_config_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar — colour adapts to the active theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Bootstrap persistent storage before the widget tree comes alive.
  // Adapters must be registered before init() eagerly opens the boxes.
  HiveStorageService.instance
      .registerAdapter<ServerConfigModel>(ServerConfigModelAdapter());
  await HiveStorageService.instance.init();
  await PreferencesService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        hiveStorageServiceProvider.overrideWithValue(HiveStorageService.instance),
        preferencesServiceProvider
            .overrideWithValue(PreferencesService.instance),
      ],
      child: const ShellMindApp(),
    ),
  );
}
