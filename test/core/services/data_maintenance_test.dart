import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/services/data_maintenance.dart';
import 'package:shell_mind/core/utils/result.dart';

void main() {
  group('DataMaintenance.clearAll', () {
    test('runs all three wipes in order on success', () async {
      final List<String> calls = <String>[];
      final DataMaintenance m = DataMaintenance(
        wipeHive: () async => calls.add('hive'),
        clearSecure: () async => calls.add('secure'),
        clearPrefs: () async => calls.add('prefs'),
      );

      final Result<void> result = await m.clearAll();

      expect(result.isSuccess, isTrue);
      expect(calls, <String>['hive', 'secure', 'prefs']);
    });

    test('surfaces a Hive failure and skips the later steps', () async {
      final List<String> calls = <String>[];
      final DataMaintenance m = DataMaintenance(
        wipeHive: () async => throw StateError('hive boom'),
        clearSecure: () async => calls.add('secure'),
        clearPrefs: () async => calls.add('prefs'),
      );

      final Result<void> result = await m.clearAll();

      expect(result.isFailure, isTrue);
      expect(calls, isEmpty, reason: 'later steps must not run after a failure');
    });

    test('stops before prefs when the keystore wipe fails', () async {
      final List<String> calls = <String>[];
      final DataMaintenance m = DataMaintenance(
        wipeHive: () async => calls.add('hive'),
        clearSecure: () async => throw StateError('secure boom'),
        clearPrefs: () async => calls.add('prefs'),
      );

      final Result<void> result = await m.clearAll();

      expect(result.isFailure, isTrue);
      expect(calls, <String>['hive']);
    });

    test('exposes the thrown error as the failure message', () async {
      final DataMaintenance m = DataMaintenance(
        wipeHive: () async => throw StateError('specific reason'),
        clearSecure: () async {},
        clearPrefs: () async {},
      );

      final Result<void> result = await m.clearAll();
      final AppFailure failure = result.failureOrNull!.failure;

      expect(failure.kind, FailureKind.unexpected);
      expect(failure.cause, isA<StateError>());
    });
  });
}
