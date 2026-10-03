import 'package:flutter/foundation.dart';

/// A single selectable model offered by an [AiProvider].
///
/// All supported providers speak the OpenAI Chat Completions protocol, so a
/// model is fully described by the [id] sent on the wire plus presentation
/// metadata ([name], [description]) for the picker UI.
@immutable
class AiModel {
  const AiModel({
    required this.id,
    required this.name,
    this.description,
  });

  /// Wire identifier sent as the `model` field (e.g. `gpt-4o-mini`).
  final String id;

  /// Human-friendly label shown in the model picker.
  final String name;

  /// Short one-liner describing the model's positioning.
  final String? description;

  @override
  bool operator ==(Object other) =>
      other is AiModel &&
      other.id == id &&
      other.name == name &&
      other.description == description;

  @override
  int get hashCode => Object.hash(id, name, description);

  @override
  String toString() => 'AiModel($id)';
}

/// Definition of an AI service provider.
///
/// Every provider in [AiProviders] is OpenAI-compatible: same request body,
/// same `Authorization: Bearer` header, same SSE response shape. Only the
/// [baseUrl], the credential, and the model catalogue differ.
@immutable
class AiProvider {
  const AiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.models,
    this.websiteUrl,
    this.shortLabel,
    this.isCustom = false,
  });

  /// Stable unique key — also used to namespace the stored API key
  /// (`openai`, `deepseek`, `qwen`, `glm`, `mimo`).
  final String id;

  /// Display name shown across settings and the chat header.
  final String name;

  /// API root; the chat path (`/chat/completions`) is appended at call time.
  final String baseUrl;

  /// Catalogue of selectable models. The first entry is the default.
  final List<AiModel> models;

  /// Where the user obtains an API key — surfaced as a "Get key" hint.
  final String? websiteUrl;

  /// Compact badge text (defaults to the first two letters of [name]).
  final String? shortLabel;

  /// True for user-defined providers persisted in Hive (see
  /// `CustomAiProviderStore`); only those may be deleted in Settings.
  final bool isCustom;

  /// The model used when the user hasn't picked one yet.
  ///
  /// Safe against an empty catalogue (freshly created custom providers may
  /// have none until models are fetched or added): returns a blank
  /// placeholder instead of throwing — such a chat request fails at the API
  /// level until the user picks a model.
  AiModel get defaultModel =>
      models.isNotEmpty ? models.first : AiModel(id: '', name: name);

  /// Two-letter badge label for list avatars.
  String get initials =>
      shortLabel ?? (name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase());

  /// Looks up a model by [id]; falls back to [defaultModel] when unknown so a
  /// stale preference never breaks the request.
  AiModel modelById(String id) {
    for (final AiModel m in models) {
      if (m.id == id) return m;
    }
    return defaultModel;
  }

  @override
  bool operator ==(Object other) =>
      other is AiProvider &&
      other.id == id &&
      other.name == name &&
      other.baseUrl == baseUrl;

  @override
  int get hashCode => Object.hash(id, name, baseUrl);

  @override
  String toString() => 'AiProvider($id)';
}

/// Registry of the built-in AI providers.
///
/// All endpoints implement the OpenAI Chat Completions API, so a single
/// transport ([AiService]) drives every one of them.
abstract final class AiProviders {
  static const AiProvider openai = AiProvider(
    id: 'openai',
    name: 'OpenAI',
    shortLabel: 'AI',
    baseUrl: 'https://api.openai.com/v1',
    models: <AiModel>[
      AiModel(
          id: 'gpt-4o-mini',
          name: 'GPT-4o Mini',
          description: 'Fast & affordable'),
      AiModel(id: 'gpt-4o', name: 'GPT-4o', description: 'Most capable'),
      AiModel(
          id: 'gpt-3.5-turbo',
          name: 'GPT-3.5 Turbo',
          description: 'Legacy fast'),
    ],
    websiteUrl: 'https://platform.openai.com/api-keys',
  );

  static const AiProvider deepseek = AiProvider(
    id: 'deepseek',
    name: 'DeepSeek',
    shortLabel: 'DS',
    baseUrl: 'https://api.deepseek.com/v1',
    models: <AiModel>[
      AiModel(
          id: 'deepseek-chat',
          name: 'DeepSeek Chat',
          description: 'General conversation'),
      AiModel(
          id: 'deepseek-reasoner',
          name: 'DeepSeek Reasoner',
          description: 'Advanced reasoning'),
    ],
    websiteUrl: 'https://platform.deepseek.com/api_keys',
  );

  static const AiProvider qwen = AiProvider(
    id: 'qwen',
    name: 'Qwen (通义千问)',
    shortLabel: 'QW',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    models: <AiModel>[
      AiModel(id: 'qwen-turbo', name: 'Qwen Turbo', description: 'Fast response'),
      AiModel(id: 'qwen-plus', name: 'Qwen Plus', description: 'Balanced'),
      AiModel(id: 'qwen-max', name: 'Qwen Max', description: 'Most capable'),
    ],
    websiteUrl: 'https://dashscope.console.aliyun.com/apiKey',
  );

  static const AiProvider glm = AiProvider(
    id: 'glm',
    name: 'GLM (智谱清言)',
    shortLabel: 'GLM',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    models: <AiModel>[
      AiModel(id: 'glm-4-flash', name: 'GLM-4 Flash', description: 'Free & fast'),
      AiModel(id: 'glm-4-plus', name: 'GLM-4 Plus', description: 'Enhanced'),
      AiModel(id: 'glm-4', name: 'GLM-4', description: 'Standard'),
    ],
    websiteUrl: 'https://open.bigmodel.cn/usercenter/apikeys',
  );

  /// Xiaomi MiMo. NOTE: the public API host for MiMo is not fully documented;
  /// this OpenAI-compatible endpoint is a best-effort placeholder and may need
  /// updating once Xiaomi publishes the official base URL.
  static const AiProvider mimo = AiProvider(
    id: 'mimo',
    name: 'MiMo (小米)',
    shortLabel: 'Mi',
    baseUrl: 'https://api.mimo.xiaomi.com/v1',
    models: <AiModel>[
      AiModel(id: 'mimo-7b', name: 'MiMo-7B', description: 'Lightweight'),
      AiModel(id: 'mimo-7b-rl', name: 'MiMo-7B-RL', description: 'RL enhanced'),
    ],
    websiteUrl: 'https://platform.xiaomi.com/',
  );

  /// Every built-in provider, in display order.
  static const List<AiProvider> all = <AiProvider>[
    openai,
    deepseek,
    qwen,
    glm,
    mimo,
  ];

  /// Resolves a provider by [id]; falls back to [openai] when unknown so a
  /// stale/invalid preference never leaves the app without a backend.
  static AiProvider getById(String id) {
    for (final AiProvider p in all) {
      if (p.id == id) return p;
    }
    return openai;
  }
}
