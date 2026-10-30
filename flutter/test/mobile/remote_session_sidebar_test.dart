import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/remote_session_sidebar.dart';

void main() {
  Widget rail() => RemoteActionRail(
    collapseLabel: 'Hide',
    onCollapse: () {},
    children: [
      for (final label in ['Operations', 'Keyboard', 'Display', 'Chat'])
        RemoteRailButton(icon: Icons.tune, label: label, onPressed: () {}),
    ],
  );

  testWidgets('right rail preserves body height across sizes and themes', (
    tester,
  ) async {
    for (final size in [
      const Size(393, 852),
      const Size(852, 393),
      const Size(320, 568),
      const Size(1024, 768),
      const Size(852, 140),
    ]) {
      await tester.binding.setSurfaceSize(size);
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: RemoteSessionLayout(
                  rail: rail(),
                  child: const SizedBox.expand(key: ValueKey('desktop')),
                ),
              ),
            ),
          ),
        );
        final desktop = tester.getRect(find.byKey(const ValueKey('desktop')));
        expect(desktop.height, size.height);
        expect(desktop.right, size.width - RemoteActionRail.width);
        expect(tester.getRect(find.byType(RemoteActionRail)).right, size.width);
        expect(tester.takeException(), isNull);
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'side panel consumes its own taps and leaves the desktop interactive',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var desktopTaps = 0;
      var panelTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteSessionLayout(
              rail: rail(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => desktopTaps++,
                child: const SizedBox.expand(),
              ),
              panel: RemoteSessionPanel(
                title: 'Operations',
                onClose: () {},
                child: TextButton(
                  onPressed: () => panelTaps++,
                  child: const Text('Action'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Action'));
      expect(panelTaps, 1);
      expect(desktopTaps, 0);
      await tester.tapAt(const Offset(40, 100));
      expect(desktopTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hiding the rail for the keyboard retains focused input', (
    tester,
  ) async {
    final focus = FocusNode();
    final controller = TextEditingController();
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    Widget app(bool showRail) => MaterialApp(
      home: Scaffold(
        body: RemoteSessionLayout(
          rail: showRail ? rail() : null,
          child: TextField(focusNode: focus, controller: controller),
        ),
      ),
    );
    await tester.pumpWidget(app(true));
    await tester.showKeyboard(find.byType(TextField));
    final state = tester.state(find.byType(EditableText));
    await tester.pumpWidget(app(false));
    expect(tester.state(find.byType(EditableText)), same(state));
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.pumpWidget(app(true));
    expect(tester.state(find.byType(EditableText)), same(state));
  });
}
