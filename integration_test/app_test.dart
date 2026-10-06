// 真机回归测试（integration_test）— Shell-Mind 核心流程
//
// ─── 运行方式 ─────────────────────────────────────────────────────────────
//
// 1. 连接真机或启动模拟器后，在项目根目录执行：
//
//        flutter test integration_test/app_test.dart -d <device>
//
//    其中 <device> 通过 `flutter devices` 查询（如 `emulator-5554`）。
//
// 2. 按文件筛选部分用例（可选）：
//
//        flutter test integration_test/app_test.dart --plain-name "boot" -d <device>
//
// ─── 覆盖范围 ─────────────────────────────────────────────────────────────
//
//   1. App 启动 → 落在服务器列表 tab，渲染假机队卡片与健康摘要卡
//   2. 底部导航三 tab 切换（Servers → AI Chat → Settings → Servers）
//   3. AI 聊天页打开（欢迎引导 + 输入框就绪）
//   4. AI 聊天消息发送 UI 流程：输入 → 发送 → mock 仓库层流式回复 → 气泡渲染
//   5. 设置页各分区渲染（AI Provider / SSH / 关于与更新）
//
// ─── 测试策略 ─────────────────────────────────────────────────────────────
//
// 遵循项目 Clean Architecture：所有外部依赖经 Riverpod provider 注入，
// 用 `UncontrolledProviderScope` 外挂 `ProviderContainer`，在 overrides 中
// 换入确定性 fake（服务器仓库 / 聊天仓库 / 聊天历史 / API Key / 安全存储 /
// 更新服务），因此：
//
//   * 不触碰设备上的真实 Hive / SharedPreferences / SecureStorage 数据；
//   * 不发起任何真实网络请求（更新检查与 AI 请求均被 fake 掐断）；
//   * 不修改 lib/ 下任何业务代码，不新增 ARB 文案（断言全部基于
//     locale 无关的图标、widget 类型与常量文本）。
//
// lib/ 代码零改动是硬约束：所有可注入点均已在生产代码里预留
// （serverConfigRepositoryProvider / chatRepositoryProvider /
// chatHistoryStoreProvider / apiKeyProvider / secureStorageServiceProvider /
// updateServiceProvider）。
//
// Library-level annotation: @Timeout 只能标注在库上（不能挂在 main 函数）。
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shell_mind/app/app.dart';
import 'package:shell_mind/core/services/update_service.dart';
import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/ai_chat/data/chat_history_store.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';
import 'package:shell_mind/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:shell_mind/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/server_config/domain/repositories/server_config_repository.dart';
import 'package:shell_mind/features/server_config/presentation/pages/servers_page.dart';
import 'package:shell_mind/features/server_config/presentation/providers/server_config_providers.dart';
import 'package:shell_mind/features/server_config/presentation/widgets/health_summary_card.dart';
import 'package:shell_mind/features/settings/presentation/pages/settings_page.dart';
import 'package:shell_mind/features/settings/presentation/widgets/ai_settings_section.dart';
import 'package:shell_mind/features/settings/presentation/widgets/ssh_reconnect_section.dart';
import 'package:shell_mind/features/settings/presentation/widgets/update_section.dart';

// ─── Fakes ──────────────────────────────────────────────────────────────
//
// 注：以下 fake 类与 helper 均声明在库级作用域（main() 之外）——Dart 不允许
// 在函数体内声明 class；真机冷启动较慢，超时由文件顶部的库级 @Timeout 统一
// 放宽到 5 分钟。

/// In-memory [ServerConfigRepository] — serves a fixed fleet, no Hive.
  class _FakeServerConfigRepository implements ServerConfigRepository {
    _FakeServerConfigRepository(this._fleet);

    final List<ServerConfig> _fleet;

    @override
    Future<List<ServerConfig>> getAll() async =>
        List<ServerConfig>.unmodifiable(_fleet);

    @override
    Stream<List<ServerConfig>> watchAll() =>
        Stream<List<ServerConfig>>.value(
            List<ServerConfig>.unmodifiable(_fleet));

    @override
    Future<ServerConfig?> getById(String id) async {
      for (final ServerConfig config in _fleet) {
        if (config.id == id) return config;
      }
      return null;
    }

    @override
    Future<void> save(ServerConfig config) async {}

    @override
    Future<void> delete(String id) async {}

    @override
    Future<void> updateLastConnected(String id) async {}
  }

  /// Records what the UI sent and streams a scripted two-chunk reply, so the
  /// real ChatNotifier → ChatRepository seam is exercised without network.
  class _RecordingChatRepository implements ChatRepository {
    final List<List<ChatMessage>> historyCalls = <List<ChatMessage>>[];
    final List<String> userCalls = <String>[];

    @override
    Stream<String> sendMessageStream({
      required List<ChatMessage> history,
      required String userMessage,
    }) async* {
      historyCalls.add(List<ChatMessage>.unmodifiable(history));
      userCalls.add(userMessage);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      yield 'Hello from ';
      await Future<void>.delayed(const Duration(milliseconds: 60));
      yield 'mock repo';
    }

    @override
    Future<Result<String>> sendMessage({
      required List<ChatMessage> history,
      required String userMessage,
    }) async =>
        Result<String>.success('Hello from mock repo');
  }

  /// Volatile transcript store — keeps ChatNotifier persistence wiring happy
  /// without touching the `chat_history` Hive box.
  class _InMemoryChatHistoryStore implements ChatHistoryStore {
    List<ChatMessage> _saved = const <ChatMessage>[];

    @override
    Future<List<ChatMessage>> load() async =>
        List<ChatMessage>.unmodifiable(_saved);

    @override
    void saveMessages(List<ChatMessage> messages) =>
        _saved = List<ChatMessage>.unmodifiable(messages);

    @override
    Future<void> flush(List<ChatMessage> messages) async =>
        _saved = List<ChatMessage>.unmodifiable(messages);

    @override
    Future<void> clear() async => _saved = const <ChatMessage>[];

    @override
    bool get hasPendingWrite => false;

    @override
    Future<void> settleForTest() async {}
  }

  /// Substitutes the platform keystore with a plain map. The public
  /// high-level helpers all funnel through write/read/delete, so overriding
  /// those primitives covers every caller (AI settings, credentials…).
  class _InMemorySecureStorage extends SecureStorageService {
    _InMemorySecureStorage() : super();

    final Map<String, String> _store = <String, String>{};

    @override
    Future<void> write(String key, String value) async =>
        _store[key] = value;

    @override
    Future<String?> read(String key) async => _store[key];

    @override
    Future<bool> contains(String key) async => _store.containsKey(key);

    @override
    Future<void> delete(String key) async => _store.remove(key);

    @override
    Future<void> deleteAll() async => _store.clear();

    @override
    Future<Map<String, String>> readAll() async =>
        Map<String, String>.of(_store);
  }

  /// Dio transport that refuses every request instantly — the silent update
  /// check swallows the resulting failure and the UI never leaves idle.
  class _OfflineAdapter implements HttpClientAdapter {
    @override
    void close({bool force = false}) {}

    @override
    Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
    ) async =>
        throw const SocketException('network disabled in integration tests');
  }

  // ─── Fixtures ───────────────────────────────────────────────────────────

  List<ServerConfig> _fixtureFleet() => <ServerConfig>[
        ServerConfig(
          id: 'srv-1',
          name: 'web-01',
          host: '10.0.0.1',
          username: 'root',
          createdAt: DateTime(2024, 1, 1),
        ),
        ServerConfig(
          id: 'srv-2',
          name: 'db-01',
          host: '10.0.0.2',
          username: 'deploy',
          createdAt: DateTime(2024, 1, 2),
        ),
      ];

  /// UpdateService stub: a PackageInfo loader that throws (bootstrap falls
  /// back to the pubspec constants) plus an offline transport (the silent
  /// GitHub check fails and is swallowed). No real network, no dialogs.
  UpdateService _stubUpdateService() {
    final Dio dio = Dio()..httpClientAdapter = _OfflineAdapter();
    return UpdateService(
      dio,
      () async => throw const SocketException(
          'package info unavailable in integration tests'),
    );
  }

  List<Override> _buildOverrides({
    required ServerConfigRepository serverRepo,
    required ChatRepository chatRepo,
    required ChatHistoryStore history,
  }) =>
      <Override>[
        serverConfigRepositoryProvider.overrideWithValue(serverRepo),
        chatRepositoryProvider.overrideWithValue(chatRepo),
        chatHistoryStoreProvider.overrideWithValue(history),
        // Chat tab renders the transcript mode (not the setup guide) and the
        // composer stays enabled.
        apiKeyProvider.overrideWith((Ref ref) async => 'test-key'),
        secureStorageServiceProvider
            .overrideWith((Ref ref) => _InMemorySecureStorage()),
        updateServiceProvider.overrideWithValue(_stubUpdateService()),
      ];

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Boots the real app shell under [container] and waits for the first
  /// settled frame of the initial (servers) tab.
  Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ShellMindApp()),
    );
    await tester.pump(); // flush microtasks (providers resolve)
    await tester.pumpAndSettle();
  }

  /// Pumps frames until [condition] holds, failing with a clear message when
  /// the deadline passes. Works under the live (real-time) test binding.
  Future<void> _pumpUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final DateTime deadline = DateTime.now().add(timeout);
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (!condition()) {
      fail('condition not met within ${timeout.inSeconds}s');
    }
  }

  Future<void> _openTab(WidgetTester tester, IconData destinationIcon) async {
    await tester.tap(find.byIcon(destinationIcon));
    await tester.pumpAndSettle();
  }

// ─── Bootstrap + Tests ──────────────────────────────────────────────────
//
// Device cold-start + first-frame build can exceed the default 30s test
// timeout on low-end hardware; the library-level @Timeout at the top of this
// file gives every case a generous 5-minute ceiling.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Deterministic preferences: mock values short-circuit the platform
    // channel both on-device and on the host, so theme/locale/provider
    // selection never depends on leftovers from a previous app run.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.instance.init();
  });

  // ─── Tests ──────────────────────────────────────────────────────────────

  testWidgets('app boots into the servers tab and renders the fake fleet',
      (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: _buildOverrides(
        serverRepo: _FakeServerConfigRepository(_fixtureFleet()),
        chatRepo: _RecordingChatRepository(),
        history: _InMemoryChatHistoryStore(),
      ),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);

    // Landing route is /servers — the real page widget is on stage.
    expect(find.byType(ServersPage), findsOneWidget);

    // Both fixture servers render as cards (name text comes straight from
    // ServerConfig.name — locale independent).
    expect(find.text('web-01'), findsOneWidget);
    expect(find.text('db-01'), findsOneWidget);

    // Fleet chrome: health summary card + add-server FAB.
    expect(find.byType(HealthSummaryCard), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // The repository layer actually fed the list controller.
    expect(container.read(serverConfigListProvider).value, isNotNull);
    expect(
      container.read(serverConfigListProvider).value!.length,
      2,
    );
  });

  testWidgets('bottom navigation switches between the three tabs',
      (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: _buildOverrides(
        serverRepo: _FakeServerConfigRepository(_fixtureFleet()),
        chatRepo: _RecordingChatRepository(),
        history: _InMemoryChatHistoryStore(),
      ),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);

    // Servers → AI chat. Destination icons are locale independent.
    await _openTab(tester, Icons.chat_bubble_outline_rounded);
    expect(find.byType(AiChatPage), findsOneWidget);
    expect(find.byType(ServersPage), findsNothing);

    // AI chat → settings.
    await _openTab(tester, Icons.settings_outlined);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(AiChatPage), findsNothing);

    // Settings → servers (full round trip).
    await _openTab(tester, Icons.dns_outlined);
    expect(find.byType(ServersPage), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
  });

  testWidgets('AI chat tab opens with the welcome transcript and composer',
      (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: _buildOverrides(
        serverRepo: _FakeServerConfigRepository(_fixtureFleet()),
        chatRepo: _RecordingChatRepository(),
        history: _InMemoryChatHistoryStore(),
      ),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);
    await _openTab(tester, Icons.chat_bubble_outline_rounded);

    // API key override satisfied → welcome view (intro card) instead of the
    // setup guide.
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);

    // Composer is present with a send affordance (disabled while empty).
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // Assistant state starts clean.
    final ChatState chat = container.read(chatMessagesProvider);
    expect(chat.isEmpty, isTrue);
    expect(chat.isStreaming, isFalse);
    expect(chat.failure, isNull);
  });

  testWidgets('sending a chat message streams the mock reply into bubbles',
      (WidgetTester tester) async {
    final _RecordingChatRepository chatRepo = _RecordingChatRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: _buildOverrides(
        serverRepo: _FakeServerConfigRepository(_fixtureFleet()),
        chatRepo: chatRepo,
        history: _InMemoryChatHistoryStore(),
      ),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);
    await _openTab(tester, Icons.chat_bubble_outline_rounded);

    // Type into the composer — the send button enables via its listener.
    await tester.enterText(find.byType(TextField), 'hello shell-mind');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    // Wait for the scripted stream to finish: not streaming and the last
    // message carries the full concatenated reply.
    await _pumpUntil(tester, () {
      final ChatState chat = container.read(chatMessagesProvider);
      return !chat.isStreaming &&
          chat.messages.isNotEmpty &&
          chat.messages.last.role == MessageRole.assistant &&
          chat.messages.last.content == 'Hello from mock repo';
    });

    // Repository seam received exactly the typed turn, with no history.
    expect(chatRepo.userCalls, <String>['hello shell-mind']);
    expect(chatRepo.historyCalls.single, isEmpty);

    // Both bubbles render; the stop affordance is gone once settled.
    expect(find.textContaining('hello shell-mind'), findsWidgets);
    expect(find.textContaining('Hello from mock repo'), findsWidgets);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);

    // No failure banner was raised on the happy path.
    expect(container.read(chatMessagesProvider).failure, isNull);
  });

  testWidgets('settings page renders its main sections',
      (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: _buildOverrides(
        serverRepo: _FakeServerConfigRepository(_fixtureFleet()),
        chatRepo: _RecordingChatRepository(),
        history: _InMemoryChatHistoryStore(),
      ),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);
    await _openTab(tester, Icons.settings_outlined);

    expect(find.byType(SettingsPage), findsOneWidget);

    // Section widgets that make up the page body.
    expect(find.byType(AiSettingsSection), findsOneWidget);
    expect(find.byType(SshReconnectSection), findsOneWidget);
    expect(find.byType(UpdateSection), findsOneWidget);

    // Update section shows the pubspec-pinned version constants (the stubbed
    // PackageInfo loader makes bootstrap fall back to these exact values).
    expect(find.textContaining('v1.5.1'), findsWidgets);
  });
}
