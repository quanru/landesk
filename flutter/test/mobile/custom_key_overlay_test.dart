import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/custom_key_overlay.dart';
import 'package:flutter_hbb/mobile/widgets/remote_shortcut.dart';

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('virtual-keys-test');
    PathProviderPlatform.instance = _TestPaths(directory.path);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  testWidgets(
      'nine keys, background hit testing, edit drag and disk restoration',
      (tester) async {
    final sent = <RemoteShortcut>[];
    int canvasTaps = 0;
    Widget app() => MaterialApp(
            home: Scaffold(
                body: Stack(fit: StackFit.expand, children: [
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => canvasTaps++,
              child: const SizedBox.expand()),
          CustomKeyOverlay(send: (shortcut) async {
            sent.add(shortcut);
          }),
        ])));
    await tester.runAsync(() async {
      await tester.pumpWidget(app());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('⌘ Space'), findsOneWidget);
    await tester.tap(find.text('⌘ Space'));
    await tester.pumpAndSettle();
    expect(sent.single.key, 'VK_SPACE');
    expect(sent.single.command, isTrue);
    expect(canvasTaps, 0);
    await tester.tapAt(const Offset(400, 250));
    expect(canvasTaps, 1);
    final escape = find.byKey(const ValueKey('virtual-key-0'));
    await tester.longPress(escape);
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(escape);
    await tester.runAsync(() async {
      final drag = await tester.startGesture(tester.getCenter(escape));
      await Future<void>.delayed(const Duration(milliseconds: 650));
      await drag.moveBy(const Offset(20, 0));
      await drag.moveBy(const Offset(100, 50));
      await drag.up();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    final moved = tester.getTopLeft(escape);
    expect(moved.dx, greaterThan(before.dx + 50));
    expect(sent, hasLength(1));
    await tester.runAsync(() async {
      await tester.tap(find.bySemanticsLabel('Finish editing keys'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await tester.pumpWidget(app());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(escape), moved);
    await tester.runAsync(() async {
      await tester.tap(find.bySemanticsLabel('Toggle virtual keys'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(find.text('⌘ Space'), findsNothing);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  });
  testWidgets('add macro with appearance, isolate profiles, restore and delete',
      (tester) async {
    Future<void> flush() async {
      await tester.runAsync(() async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
    }

    Future<void> open(String profile) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: CustomKeyOverlay(
                    key: ValueKey(profile),
                    profileId: profile,
                    send: (_) async {}))));
      });
      await flush();
    }

    await open('host-a');
    await tester.longPress(find.text('Esc'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Add key'));
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My macro');
    final sizeSlider =
        tester.widget<Slider>(find.byKey(const ValueKey('key-size')));
    sizeSlider.onChanged!(80);
    final opacitySlider =
        tester.widget<Slider>(find.byKey(const ValueKey('key-opacity')));
    opacitySlider.onChanged!(.8);
    await tester.ensureVisible(find.text('Add step'));
    await tester.tap(find.text('Add step'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      await tester.pump();
    });
    await flush();
    expect(find.text('My macro'), findsOneWidget);
    expect(
        tester.getSize(find.byKey(const ValueKey('virtual-key-9'))).width, 80);
    await open('host-b');
    expect(find.text('My macro'), findsNothing);
    await open('host-a');
    expect(find.text('My macro'), findsOneWidget);
    await tester.longPress(find.text('My macro'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('My macro'));
    });
    await tester.pumpAndSettle();
    expect(find.text('2. Enter'), findsOneWidget);
    expect(
        tester.widget<Slider>(find.byKey(const ValueKey('key-opacity'))).value,
        .8);
    await tester.runAsync(() async {
      await tester.tap(find.text('Delete key'));
      await tester.pump();
    });
    await flush();
    expect(find.text('My macro'), findsNothing);
    await open('host-b');
    await open('host-a');
    expect(find.text('My macro'), findsNothing);
  });
}
