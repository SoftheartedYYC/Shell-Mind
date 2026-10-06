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
import 'core/services/notification_service.dart';
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
  // SharedPreferences and Hive are independent stores — open them in parallel
  // so neither's disk/plugin latency delays the other on cold start.
  await Future.wait(<Future<void>>[
    HiveStorageService.instance.init(),
    PreferencesService.instance.init(),
  ]);
  // The three Hive-backed snapshots are independent reads — load them
  // concurrently once the boxes are open.
  await Future.wait(<Future<void>>[
    CustomAiProviderStore.instance.preload(),
    CommandAuditLog.instance.preload(),
    crash.preload(),
  ]);
  // Stamp device info onto every subsequent crash entry.
  crash.configure(
    platformLabel: Platform.operatingSystem,
    localeTag: PlatformDispatcher.instance.locale.toString(),
  );

  // Local notifications (session-disconnect / AI-completion). Initialised
  // fire-and-forget so a permission prompt never blocks first paint.
  unawaited(NotificationService.instance.init());

  runApp(
    ProviderScope(
      overrides: [
        hiveStorageServiceProvider.overrideWithValue(HiveStorageService.instance),
        preferencesServiceProvider
            .overrideWithValue(PreferencesService.instance),
      ],
      // Riverpod 3 auto-retries failing providers by default. The app renders
      // explicit error states with manual retry affordances (models fetch, fleet
      // load, key probe…), so disable automatic retry to preserve that UX.
      retry: (int retryCount, Object error) => null,
      child: const ShellMindApp(),
    ),
  );
}
