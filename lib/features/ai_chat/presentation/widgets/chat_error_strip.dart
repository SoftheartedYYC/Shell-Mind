import 'package:flutter/material.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';

// ─── Error strip ────────────────────────────────────────────────────────

/// Compact error banner slotted between the transcript and the composer.
class ChatErrorStrip extends StatelessWidget {
  const ChatErrorStrip({super.key, required this.failure, required this.onDismiss});

  final AppFailure failure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ErrorBanner(failure: failure, onDismiss: onDismiss, dense: true),
    );
  }
}
