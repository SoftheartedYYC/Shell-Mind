import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/utils/result.dart';

void main() {
  group('Result<T>', () {
    group('Success', () {
      test('creates with value and isSuccess is true', () {
        final result = Result<int>.success(42);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.valueOrNull, 42);
        expect(result.failureOrNull, isNull);
      });

      test('getOrElse returns value on success', () {
        final result = Result<String>.success('hello');
        expect(result.getOrElse('fallback'), 'hello');
      });

      test('getOrElseWith returns value on success', () {
        final result = Result<String>.success('hello');
        expect(result.getOrElseWith((_) => 'fallback'), 'hello');
      });

      test('getOrThrow returns value on success', () {
        final result = Result<int>.success(99);
        expect(result.getOrThrow(), 99);
      });

      test('value equality', () {
        final a = Result<int>.success(10);
        final b = Result<int>.success(10);
        final c = Result<int>.success(20);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a, isNot(equals(c)));
      });
    });

    group('Failure', () {
      test('creates with AppFailure and isFailure is true', () {
        final failure = AppFailure.network('timeout');
        final result = Result<int>.failure(failure);
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.failureOrNull, isNotNull);
        expect(result.failureOrNull!.failure.kind, FailureKind.network);
      });

      test('getOrElse returns fallback on failure', () {
        final result = Result<String>.failure(AppFailure.auth());
        expect(result.getOrElse('fallback'), 'fallback');
      });

      test('getOrElseWith invokes callback on failure', () {
        final result = Result<String>.failure(
          AppFailure.validation('bad input'),
        );
        expect(
          result.getOrElseWith((f) => 'error: ${f.failure.message}'),
          'error: bad input',
        );
      });

      test('getOrThrow throws on failure', () {
        final result = Result<int>.failure(AppFailure.notFound());
        expect(() => result.getOrThrow(), throwsA(isA<Object>()));
      });

      test('value equality', () {
        final a = Result<int>.failure(AppFailure.auth(message: 'x'));
        final b = Result<int>.failure(AppFailure.auth(message: 'x'));
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('when', () {
      test('dispatches success branch', () {
        final result = Result<int>.success(5);
        final output = result.when(
          success: (v) => 'value=$v',
          failure: (f) => 'error=${f.message}',
        );
        expect(output, 'value=5');
      });

      test('dispatches failure branch', () {
        final result = Result<int>.failure(
          AppFailure.timeout(const Duration(seconds: 5)),
        );
        final output = result.when(
          success: (v) => 'value=$v',
          failure: (f) => 'kind=${f.kind.name}',
        );
        expect(output, 'kind=timeout');
      });
    });

    group('maybeWhen', () {
      test('dispatches success branch', () {
        final result = Result<int>.success(7);
        final output = result.maybeWhen(
          success: (v) => 'got $v',
          orElse: () => 'default',
        );
        expect(output, 'got 7');
      });

      test('dispatches failure branch when provided', () {
        final result = Result<int>.failure(AppFailure.auth());
        final output = result.maybeWhen(
          success: (v) => 'got $v',
          failure: (f) => 'auth error',
          orElse: () => 'default',
        );
        expect(output, 'auth error');
      });

      test('dispatches orElse when failure handler is null', () {
        final result = Result<int>.failure(AppFailure.auth());
        final output = result.maybeWhen(
          success: (v) => 'got $v',
          orElse: () => 'default',
        );
        expect(output, 'default');
      });
    });

    group('map', () {
      test('transforms success value', () {
        final result = Result<int>.success(3);
        final mapped = result.map<String>((v) => 'num=$v');
        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, 'num=3');
      });

      test('propagates failure unchanged', () {
        final failure = AppFailure.storage('disk full');
        final result = Result<int>.failure(failure);
        final mapped = result.map<String>((v) => 'num=$v');
        expect(mapped.isFailure, isTrue);
        expect(mapped.failureOrNull!.failure.message, 'disk full');
      });
    });

    group('flatMap', () {
      test('chains on success', () {
        final result = Result<int>.success(10);
        final chained = result.flatMap<String>(
          (v) => Result<String>.success('doubled=${v * 2}'),
        );
        expect(chained.valueOrNull, 'doubled=20');
      });

      test('chains failure from inner operation', () {
        final result = Result<int>.success(10);
        final chained = result.flatMap<String>(
          (v) => Result<String>.failure(AppFailure.validation('too big')),
        );
        expect(chained.isFailure, isTrue);
        expect(chained.failureOrNull!.failure.message, 'too big');
      });

      test('short-circuits on outer failure', () {
        final result = Result<int>.failure(AppFailure.network('offline'));
        final chained = result.flatMap<String>(
          (v) => Result<String>.success('never reached'),
        );
        expect(chained.isFailure, isTrue);
        expect(chained.failureOrNull!.failure.kind, FailureKind.network);
      });
    });

    group('guard', () {
      test('returns success when body completes', () async {
        final result = await Result.guard<int>(() async => 42);
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, 42);
      });

      test('returns failure when body throws', () async {
        final result = await Result.guard<int>(() async {
          throw Exception('boom');
        });
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull!.failure.kind, FailureKind.unexpected);
      });

      test('uses onError hook for custom mapping', () async {
        final result = await Result.guard<int>(
          () async => throw FormatException('bad'),
          onError: (e, st) => AppFailure.validation('custom: $e'),
        );
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull!.failure.kind, FailureKind.validation);
        expect(result.failureOrNull!.failure.message, contains('custom:'));
      });

      test('works with synchronous body', () async {
        final result = await Result.guard<String>(() => 'sync value');
        expect(result.valueOrNull, 'sync value');
      });
    });

    group('guardSync', () {
      test('returns success when body completes', () {
        final result = Result.guardSync<int>(() => 7);
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, 7);
      });

      test('returns failure when body throws', () {
        final result = Result.guardSync<int>(() => throw StateError('oops'));
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull!.failure.kind, FailureKind.unexpected);
        expect(result.failureOrNull!.failure.cause, isA<StateError>());
      });

      test('uses onError hook for custom mapping', () {
        final result = Result.guardSync<int>(
          () => throw ArgumentError('bad arg'),
          onError: (e, st) => AppFailure.validation('mapped'),
        );
        expect(result.failureOrNull!.failure.kind, FailureKind.validation);
        expect(result.failureOrNull!.failure.message, 'mapped');
      });
    });
  });

  group('AppFailure', () {
    test('network factory sets recoverable', () {
      final f = AppFailure.network('socket closed');
      expect(f.kind, FailureKind.network);
      expect(f.recoverable, isTrue);
      expect(f.message, 'Network unreachable.');
      expect(f.cause, 'socket closed');
    });

    test('timeout factory includes duration in message', () {
      final f = AppFailure.timeout(const Duration(seconds: 30));
      expect(f.kind, FailureKind.timeout);
      expect(f.message, contains('30'));
      expect(f.recoverable, isTrue);
    });

    test('auth factory with custom message', () {
      final f = AppFailure.auth(message: 'Token expired');
      expect(f.kind, FailureKind.auth);
      expect(f.message, 'Token expired');
      expect(f.recoverable, isFalse);
    });

    test('aiProvider factory sets recoverable for 5xx', () {
      final f500 = AppFailure.aiProvider('server error', statusCode: 500);
      expect(f500.recoverable, isTrue);
      final f400 = AppFailure.aiProvider('bad request', statusCode: 400);
      expect(f400.recoverable, isFalse);
    });

    test('ssh factory sets recoverable', () {
      final f = AppFailure.ssh('connection refused', code: 1);
      expect(f.kind, FailureKind.ssh);
      expect(f.recoverable, isTrue);
      expect(f.code, 1);
    });

    test('equality based on kind, message, code', () {
      final a = AppFailure.auth(message: 'fail');
      final b = AppFailure.auth(message: 'fail');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith overrides fields', () {
      final original = AppFailure.network('err');
      final copy = original.copyWith(message: 'new msg', recoverable: false);
      expect(copy.message, 'new msg');
      expect(copy.recoverable, isFalse);
      expect(copy.kind, FailureKind.network);
    });

    test('toException returns cause when available', () {
      final err = Exception('root cause');
      final f = AppFailure.unexpected(err);
      expect(f.toException(), same(err));
    });

    test('toException wraps in AppFailureException when no cause', () {
      final f = AppFailure.auth(message: 'no cause');
      final ex = f.toException();
      expect(ex, isA<AppFailureException>());
      expect((ex as AppFailureException).failure.message, 'no cause');
    });

    test('toString includes kind and message', () {
      final f = AppFailure.validation('bad input');
      expect(f.toString(), contains('validation'));
      expect(f.toString(), contains('bad input'));
    });
  });
}
