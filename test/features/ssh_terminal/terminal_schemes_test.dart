import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ssh_terminal/presentation/terminal_schemes.dart';

void main() {
  group('TerminalColorScheme', () {
    test('catalogue has unique ids and a sane default', () {
      final Set<String> ids = <String>{
        for (final TerminalColorScheme s in TerminalColorScheme.all) s.id,
      };
      expect(ids, hasLength(TerminalColorScheme.all.length));
      expect(TerminalColorScheme.defaultId, 'tokyo-night');
      expect(TerminalColorScheme.byId(TerminalColorScheme.defaultId).id,
          TerminalColorScheme.defaultId);
    });

    test('byId falls back to tokyo-night for unknown ids', () {
      expect(TerminalColorScheme.byId(null).id, 'tokyo-night');
      expect(TerminalColorScheme.byId('nope').id, 'tokyo-night');
    });

    test('every scheme exposes a dark background and 16-colour palette', () {
      for (final TerminalColorScheme s in TerminalColorScheme.all) {
        final t = s.theme;
        expect(s.background, t.background);
        // The terminal viewport is always dark by design.
        expect(t.background.computeLuminance(), lessThan(0.3));
        expect(t.foreground, isNotNull);
        expect(t.black, isNotNull);
        expect(t.brightWhite, isNotNull);
      }
    });
  });
}
