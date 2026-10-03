import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';
import 'package:shell_mind/features/settings/presentation/widgets/model_picker_sheet.dart';
import 'package:shell_mind/l10n/app_localizations.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService mockSecure;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.instance.init();

    mockSecure = MockSecureStorageService();
    // No key configured -> the catalogue resolves from built-ins only, so the
    // tests never touch the network.
    when(() => mockSecure.getProviderApiKey(any()))
        .thenAnswer((_) async => null);
  });

  /// Pumps a shell app whose button opens the sheet through
  /// [ModelPickerSheet.show]; the sheet's pop result lands in [picked].
  Future<ProviderContainer> pumpShell(
    WidgetTester tester,
    Completer<String?> picked,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        preferencesServiceProvider
            .overrideWithValue(PreferencesService.instance),
        secureStorageServiceProvider.overrideWithValue(mockSecure),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    picked.complete(await ModelPickerSheet.show(context));
                  },
                  child: const Text('open-sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the merged catalogue with the default model checked',
      (WidgetTester tester) async {
    await pumpShell(tester, Completer<String?>());
    await openSheet(tester);

    // Built-in OpenAI catalogue rendered without a key (no network fetch).
    expect(find.text('GPT-4o Mini'), findsOneWidget);
    expect(find.text('GPT-4o'), findsOneWidget);
    expect(find.text('GPT-3.5 Turbo'), findsOneWidget);

    // The default model row is the checked one (radio + trailing check).
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Title and search field are present.
    expect(find.text('Choose model'), findsOneWidget);
    expect(find.text('Search models'), findsOneWidget);
  });

  testWidgets('filters models by id or name and shows the empty state',
      (WidgetTester tester) async {
    await pumpShell(tester, Completer<String?>());
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'mini');
    await tester.pump();

    expect(find.text('GPT-4o Mini'), findsOneWidget);
    expect(find.text('GPT-4o'), findsNothing);
    expect(find.text('GPT-3.5 Turbo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pump();
    expect(find.text('No models match your search.'), findsOneWidget);

    // The clear affordance restores the full list.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.text('GPT-4o'), findsOneWidget);
    expect(find.text('GPT-3.5 Turbo'), findsOneWidget);
  });

  testWidgets('tapping a model pops the sheet with its id',
      (WidgetTester tester) async {
    final Completer<String?> picked = Completer<String?>();
    await pumpShell(tester, picked);
    await openSheet(tester);

    await tester.tap(find.text('GPT-4o'));

    expect(await picked.future, 'gpt-4o');
    await tester.pumpAndSettle();
    // Sheet has closed after the selection.
    expect(find.text('Choose model'), findsNothing);
  });

  testWidgets('shows the currently selected model as checked',
      (WidgetTester tester) async {
    // Seed the stored selection before the shell (and its providers) build.
    await PreferencesService.instance.setSelectedModel('openai', 'gpt-4o');

    await pumpShell(tester, Completer<String?>());
    await openSheet(tester);

    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(2));
  });
}
