import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/preferences_service.dart';

/// Riverpod Notifier that manages the "hide IP addresses" privacy toggle.
///
/// Loads the persisted preference on first build and writes back whenever
/// the user changes it. Consumer widgets watching this provider re-render
/// immediately, so masking applies live across the app.
class HideIpNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.hideIpAddresses;
  }

  Future<void> setHideIpAddresses(bool value) async {
    state = value;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setHideIpAddresses(value);
  }
}

final hideIpAddressesProvider =
    NotifierProvider<HideIpNotifier, bool>(HideIpNotifier.new);
