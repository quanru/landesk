import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/remote_shortcut.dart';
import 'package:flutter_hbb/mobile/widgets/window_overview.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';

void main() {
  test(
    'Windows and Mac overview chords release the main key before modifiers',
    () async {
      for (final shortcut in [windowsWindowOverview, macWindowOverview]) {
        final events = <String>[];
        await sendRemoteShortcut(shortcut, (
          key,
          down, {
          required ctrl,
          required alt,
          required shift,
          required command,
        }) async {
          events.add('$key:$down:$ctrl:$command');
        });
        expect(
          events,
          shortcut == windowsWindowOverview
              ? [
                  'Meta:true:false:true',
                  'VK_TAB:true:false:true',
                  'VK_TAB:false:false:true',
                  'Meta:false:false:false',
                ]
              : [
                  'VK_CONTROL:true:true:false',
                  'VK_UP:true:true:false',
                  'VK_UP:false:true:false',
                  'VK_CONTROL:false:false:false',
                ],
        );
      }
    },
  );

  test('Linux config rejects damaged data and restores custom modifiers', () {
    for (final value in [
      null,
      '',
      '{',
      '[]',
      '{"key":"unknown"}',
      '{"key":"VK_TAB","title":123}',
    ]) {
      expect(decodeWindowOverview(value), isNull);
    }
    const custom = RemoteShortcut(
      'All windows',
      'VK_O',
      command: true,
      shift: true,
    );
    expect(
      decodeWindowOverview(jsonEncode(custom.toJson()))?.toJson(),
      custom.toJson(),
    );
  });

  Future<void> openSettings(
    WidgetTester tester,
    Future<void> Function(RemoteShortcut) save, {
    RemoteShortcut? initial,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LandeskTheme.build(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) =>
                    WindowOverviewSettings(initial: initial, onSave: save),
              ),
              child: const Text('Configure'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Configure'));
    await tester.pumpAndSettle();
  }

  testWidgets('save failure keeps settings open and allows retry', (
    tester,
  ) async {
    var attempts = 0;
    await openSettings(tester, (_) async {
      if (++attempts == 1) throw StateError('write failed');
    });
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
    expect(find.byType(WindowOverviewSettings), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(WindowOverviewSettings), findsNothing);
  });

  testWidgets('cancel does not save; reopening restores the saved chord', (
    tester,
  ) async {
    RemoteShortcut? saved;
    const initial = RemoteShortcut('All windows', 'VK_F10', ctrl: true);
    await openSettings(tester, (s) async => saved = s, initial: initial);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('Configure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved?.toJson(), initial.toJson());
  });

  testWidgets('settings fit phone portrait and landscape in both themes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [
      const Size(375, 667),
      const Size(852, 393),
      const Size(1024, 768),
    ]) {
      await tester.binding.setSurfaceSize(size);
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 2.0]) {
          await openSettings(
            tester,
            (_) async {},
            brightness: brightness,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Save').hitTestable(), findsOneWidget);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }
      }
    }
  });
}
