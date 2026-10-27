import 'package:flutter/material.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    final p = brightness == Brightness.dark
        ? SuyaPalette.dark
        : SuyaPalette.light;
    test('$brightness text and action contrast', () {
      for (final surface in [p.background, p.surface, p.inset]) {
        expect(contrast(p.text, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.secondary, surface), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(p.accent, p.onAccent), greaterThanOrEqualTo(4.5));
    });
    for (final platform in TargetPlatform.values) {
      testWidgets('$platform $brightness components and interaction', (
        tester,
      ) async {
        final theme = LandeskTheme.build(brightness, platform: platform);
        var clicks = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('landesk'),
                          const TextField(
                            decoration: InputDecoration(
                              labelText: 'LAN address',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => clicks++,
                            child: const Text('Connect'),
                          ),
                          const ElevatedButton(
                            onPressed: null,
                            child: Text('Unavailable'),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Settings'),
                          ),
                          Checkbox(value: true, onChanged: (_) {}),
                          Switch(value: true, onChanged: (_) {}),
                        ],
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('Connection'),
                          content: Text('Local network'),
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.text('Connect'));
        await tester.pumpAndSettle();
        expect(clicks, 1);
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '192.168.1.2');
        expect(find.text('192.168.1.2'), findsOneWidget);
        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        final touch =
            platform == TargetPlatform.iOS ||
            platform == TargetPlatform.android;
        expect(
          theme.elevatedButtonTheme.style!.minimumSize!.resolve({})!.height,
          touch ? 44 : 40,
        );
        expect(
          theme.elevatedButtonTheme.style!.backgroundColor!.resolve({
            WidgetState.disabled,
          }),
          p.inset,
        );
        expect(
          theme.outlinedButtonTheme.style!.side!.resolve({
            WidgetState.focused,
          })!.width,
          2,
        );
      });
    }
  }
}
