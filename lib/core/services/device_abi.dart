/// Runtime detection of the device's primary ABI, used by the in-app updater
/// to pick the per-ABI APK that matches this device from a release's asset
/// list (see `pickApkAsset` in release_selector.dart).
///
/// Implemented with `dart:ffi`'s [Abi.current] so no extra plugin dependency
/// is required. On non-Android runtimes (VM tests, desktop) the value maps to
/// `null` and the asset chooser falls back to its universal/static preference
/// chain — detection must never break the update flow.
library;

import 'dart:ffi' show Abi;

/// Flutter/Gradle ABI directory names, in release-pipeline upload order.
const List<String> supportedAbis = <String>[
  'arm64-v8a',
  'armeabi-v7a',
  'x86_64',
];

/// ABI name (e.g. `arm64-v8a`) of the current device, or `null` when the
/// runtime is not Android (or the ABI is not one we build for).
String? currentDeviceAbi() => abiName(Abi.current());

/// Maps an ffi [Abi] to the Flutter/Gradle ABI directory name.
///
/// Returns `null` for anything outside [supportedAbis] — including non-Android
/// operating systems, which is exactly how VM-based unit tests behave.
String? abiName(Abi abi) => switch (abi) {
      Abi.androidArm64 => 'arm64-v8a',
      Abi.androidArm => 'armeabi-v7a',
      Abi.androidX64 => 'x86_64',
      _ => null,
    };
