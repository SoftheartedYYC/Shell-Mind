import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/command_audit_log.dart';
import 'core/services/crash_report_service.dart';
import 'core/storage/hive_storage_service.dart';
import 'core/storage/preferences_service.dart';
import 'features/ai_chat/data/custom_ai_provider_store.dart';
import 'features/server_config/data/models/server_config_model.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () => _bootstrap(),
    (Object error, StackTrace stack) =>
        // Last-resort net for errors escaping every other handler (async
        // zone errors). Recording itself is fail-safe and never rethrows.
        CrashReportService.instance.recordError(
      source: 'zone',
      error: error,
      stack: stack,
    ),
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Global error capture ──────────────────────────────────────────────
  // Both handlers write into the crash ring buffer (see CrashReportService);
  // the original behaviour (console dump) is preserved on top of it.
  final CrashReportService crash = CrashReportService.instance;
  final FlutterExceptionHandler previousFlutterError = FlutterError.onError!;
  FlutterError.onError = (FlutterErrorDetails details) {
    crash.recordError(
      source: 'flutter',
      error: details.exception,
      stack: details.stack,
    );
    previousFlutterError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    crash.recordError(source: 'platform', error: error, stack: stack);
    // Unhandled: let the platform log it as before.
    return false;
  };

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
  // Custom AI providers live in the `app_meta` box — load after Hive init.
  await CustomAiProviderStore.instance.preload();
  // AI command audit trail also lives in `app_meta` — load after Hive init.
  await CommandAuditLog.instance.preload();
  // Crash ring buffer as well — load before the UI can read it.
  await crash.preload();
  // Stamp device info onto every subsequent crash entry.
  crash.configure(
    platformLabel: Platform.operatingSystem,
    localeTag: PlatformDispatcher.instance.locale.toString(),
  );

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
