import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';
import 'package:shell_mind/features/command_snippets/data/command_snippet_repository_impl.dart';
import 'package:shell_mind/features/command_snippets/data/models/command_snippet_model.dart';
import 'package:shell_mind/features/command_snippets/domain/entities/command_snippet.dart';
import 'package:shell_mind/features/command_snippets/presentation/providers/command_snippet_providers.dart';

/// Test-friendly HiveStorageService backed by a pre-initialised Hive in a
/// temp directory (avoids path_provider, mirrors the custom-provider tests).
class _TestHiveStorageService implements HiveStorageService {
  @override
  bool get isInitialised => true;

  @override
  Box<dynamic> box(String name) => Hive.box<dynamic>(name);

  @override
  Future<Box<dynamic>> openBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<dynamic>(name);
    return Hive.openBox<dynamic>(name);
  }

  @override
  Future<void> closeBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box<dynamic>(name).close();
    }
  }

  @override
  Future<void> clearBox(String name) async => box(name).clear();

  @override
  Future<void> deleteBox(String name) async => Hive.deleteBoxFromDisk(name);

  @override
  T? get<T>(String boxName, String key, {T? defaultValue}) {
    final dynamic v = box(boxName).get(key, defaultValue: defaultValue);
    return v is T ? v : defaultValue;
  }

  @override
  List<T> getAll<T>(String boxName) =>
      box(boxName).values.whereType<T>().toList();

  @override
  Map<String, dynamic> toMap(String boxName) =>
      box(boxName).toMap().cast<String, dynamic>();

  @override
  Future<void> put(String boxName, String key, dynamic value) =>
      box(boxName).put(key, value);

  @override
  Future<void> putAll(String boxName, Map<String, dynamic> entries) =>
      box(boxName).putAll(entries);

  @override
  Future<void> delete(String boxName, String key) => box(boxName).delete(key);

  @override
  Future<void> deleteAllKeys(String boxName, Iterable<String> keys) =>
      box(boxName).deleteAll(keys);

  @override
  Future<int> add(String boxName, dynamic value) => box(boxName).add(value);

  @override
  bool hasKey(String boxName, String key) => box(boxName).containsKey(key);

  @override
  int length(String boxName) => box(boxName).length;

  @override
  Stream<BoxEvent> watch(String boxName, {String? key}) =>
      box(boxName).watch(key: key);

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, {bool internal = false}) {
    if (!Hive.isAdapterRegistered(adapter.typeId) || internal) {
      Hive.registerAdapter<T>(adapter, internal: internal);
    }
  }

  @override
  Future<void> init({String? subDirectory}) async {}

  @override
  Future<void> close() async => Hive.close();

  @override
  Future<void> wipeEverything() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _TestHiveStorageService hive;
  late CommandSnippetRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('snippets_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxSnippets);
    hive = _TestHiveStorageService();
    repo = CommandSnippetRepositoryImpl(hive);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxSnippets);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  CommandSnippet snippet(
    String id,
    String command, {
    String? name,
    DateTime? createdAt,
  }) =>
      CommandSnippet(
        id: id,
        command: command,
        name: name,
        createdAt: createdAt ?? DateTime(2024, 1, 1),
      );

  group('CommandSnippet entity', () {
    test('tryCreate trims and rejects blank commands', () {
      expect(CommandSnippet.tryCreate(command: '  '), isNull);
      expect(CommandSnippet.tryCreate(command: ''), isNull);

      final CommandSnippet? s = CommandSnippet.tryCreate(
        command: '  docker ps  ',
        name: '  ',
      );
      expect(s, isNotNull);
      expect(s!.command, 'docker ps');
      expect(s.name, isNull, reason: 'a blank name must collapse to null');
    });

    test('displayLabel falls back to the command when unnamed', () {
      expect(
        snippet('1', 'tail -f /var/log/syslog').displayLabel,
        'tail -f /var/log/syslog',
      );
      expect(
        snippet('2', 'tail -f x', name: 'Logs').displayLabel,
        'Logs',
      );
    });
  });

  group('CommandSnippetModel JSON mapping', () {
    test('round-trips name, command and createdAt', () {
      final CommandSnippet original = snippet(
        's1',
        'grep -rn "TODO" .',
        name: 'Find TODOs',
        createdAt: DateTime(2024, 6, 1, 12, 30),
      );

      final CommandSnippet decoded =
          CommandSnippetModel.fromJsonMap(
              CommandSnippetModel.fromEntity(original).toJsonMap())!
          .toEntity();

      expect(decoded, equals(original));
    });

    test('fromJsonMap rejects malformed frames', () {
      expect(CommandSnippetModel.fromJsonMap(null), isNull);
      expect(CommandSnippetModel.fromJsonMap('nope'), isNull);
      expect(CommandSnippetModel.fromJsonMap(<String, dynamic>{}), isNull);
      expect(
        CommandSnippetModel.fromJsonMap(<String, dynamic>{
          'id': 'x',
          'command': '',
          'createdAt': '2024-01-01T00:00:00.000',
        }),
        isNull,
        reason: 'blank command is invalid',
      );
      expect(
        CommandSnippetModel.fromJsonMap(<String, dynamic>{
          'id': 'x',
          'command': 'ls',
        }),
        isNull,
        reason: 'missing createdAt is invalid',
      );
    });
  });

  group('CommandSnippetRepositoryImpl CRUD', () {
    test('add + getAll returns snippets newest first', () async {
      await repo.add(snippet('old', 'first', createdAt: DateTime(2024, 1, 1)));
      await repo.add(snippet('new', 'second', createdAt: DateTime(2024, 2, 1)));

      final List<CommandSnippet> all = await repo.getAll();
      expect(all.map((CommandSnippet s) => s.id).toList(),
          <String>['new', 'old']);
    });

    test('add rejects duplicate ids', () async {
      await repo.add(snippet('dup', 'one'));
      expect(() => repo.add(snippet('dup', 'two')), throwsStateError);
    });

    test('remove deletes only the targeted snippet', () async {
      await repo.add(snippet('a', 'one'));
      await repo.add(snippet('b', 'two'));

      await repo.remove('a');

      final List<CommandSnippet> all = await repo.getAll();
      expect(all.map((CommandSnippet s) => s.id).toList(), <String>['b']);
    });

    test('remove of an unknown id is a no-op', () async {
      await repo.add(snippet('a', 'one'));
      await repo.remove('ghost');
      expect(await repo.getAll(), hasLength(1));
    });

    test('clear wipes every snippet', () async {
      await repo.add(snippet('a', 'one'));
      await repo.add(snippet('b', 'two'));
      await repo.clear();
      expect(await repo.getAll(), isEmpty);
    });

    test('persistence round-trip: data survives a fresh repository',
        () async {
      await repo.add(snippet('keep', 'docker system prune -a',
          name: 'Prune everything',
          createdAt: DateTime(2024, 3, 3)));

      // A brand-new repository over the same Hive dir simulates an app
      // restart: the snippet must come back from the box itself.
      final CommandSnippetRepositoryImpl fresh =
          CommandSnippetRepositoryImpl(hive);
      final List<CommandSnippet> loaded = await fresh.getAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'keep');
      expect(loaded.single.command, 'docker system prune -a');
      expect(loaded.single.name, 'Prune everything');
    });
  });

  group('CommandSnippetsController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: <Override>[
        hiveStorageServiceProvider.overrideWithValue(hive),
        commandSnippetRepositoryProvider
            .overrideWithValue(repo),
      ]);
    });

    tearDown(() => container.dispose());

    test('addSnippet trims input, persists and refreshes the list',
        () async {
      await container
          .read(commandSnippetsProvider.notifier)
          .addSnippet(command: '  htop  ', name: '  Process viewer ');

      final AsyncValue<List<CommandSnippet>> state =
          container.read(commandSnippetsProvider);
      expect(state.value, hasLength(1));
      expect(state.value!.single.command, 'htop');
      expect(state.value!.single.name, 'Process viewer');
    });

    test('addSnippet ignores blank commands', () async {
      await container
          .read(commandSnippetsProvider.notifier)
          .addSnippet(command: '   ');
      expect(container.read(commandSnippetsProvider).value, isEmpty);
    });

    test('removeSnippet deletes and refreshes', () async {
      await container
          .read(commandSnippetsProvider.notifier)
          .addSnippet(command: 'one');
      await container
          .read(commandSnippetsProvider.notifier)
          .addSnippet(command: 'two');

      final String firstId =
          container.read(commandSnippetsProvider).value!.last.id;
      await container
          .read(commandSnippetsProvider.notifier)
          .removeSnippet(firstId);

      final List<CommandSnippet> remaining =
          container.read(commandSnippetsProvider).value!;
      expect(remaining, hasLength(1));
      expect(remaining.single.command, 'two');
    });
  });
}
