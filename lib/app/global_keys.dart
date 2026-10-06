import 'package:flutter/material.dart';

/// Global root-navigator key shared by the GoRouter config and any code that
/// must present UI above **every** route (host-key trust prompt, overlays).
///
/// Kept in a leaf module so data-layer code (e.g. [SshSessionRegistry]) can
/// bridge out to the UI without importing the router — which would create a
/// features → app → features dependency cycle.
///
/// The [routerProvider] uses this same key as its `navigatorKey`, so
/// `showDialog(context: rootNavigatorKey.currentContext!)` always resolves to
/// the navigator that owns all top-level routes, including the full-screen
/// terminal page.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
