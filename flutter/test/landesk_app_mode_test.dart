import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/app_mode_picker.dart';
import 'package:flutter_hbb/models/app_mode_model.dart';

void main() {
  test(
      'fitted window corners map back to remote coordinates in both orientations',
      () {
    const window = Rect.fromLTWH(120, 80, 480, 800);
    const portrait = AppViewport(window, Size(375, 700));
    expect(portrait.visible, const Rect.fromLTWH(0, 37.5, 375, 625));
    const landscape = AppViewport(window, Size(800, 350));
    expect(landscape.visible, const Rect.fromLTWH(295, 0, 210, 350));
    for (final size in [const Size(375, 700), const Size(800, 350)]) {
      final view = AppViewport(window, size);
      for (final corner in [
        window.topLeft,
        window.bottomRight,
        window.center
      ]) {
        final screen = corner * view.scale + view.offset;
        final remote = (screen - view.offset) / view.scale;
        expect((remote - corner).distance, lessThan(0.0001));
      }
      expect(view.visible.width, lessThanOrEqualTo(size.width));
      expect(view.visible.height, lessThanOrEqualTo(size.height));
    }
  });

  testWidgets(
      'app selection sends chosen window and fit preference; errors permit retry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const window =
        AppWindow(42, 'Notes', 'Demo', Rect.fromLTWH(0, 0, 600, 800));
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AppModePicker(
                chinese: true,
                load: () async => [window],
                select: (selected, fit, scale) async {
                  expect(selected.id, 42);
                  expect(fit, false);
                  expect(scale, 1.25);
                  attempts++;
                  throw StateError('Window unavailable');
                }))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('125%'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Window unavailable'), findsOneWidget);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker scrolls in landscape with large text and a loading state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final windows = Completer<List<AppWindow>>();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
                body: AppModePicker(
                    chinese: true,
                    load: () => windows.future,
                    select: (_, __, ___) async {})))));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
    windows.complete([]);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('此显示器上暂无可用窗口'));
    expect(tester.takeException(), isNull);
  });
}
