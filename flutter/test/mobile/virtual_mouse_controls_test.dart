import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/virtual_mouse_controls.dart';

void main() {
  Widget app(
    Future<void> Function(int) scroll, {
    bool editing = false,
    void Function(String, Offset)? onPosition,
    VoidCallback? background,
  }) => MaterialApp(
    home: Stack(
      children: [
        GestureDetector(
          onTap: background,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
        VirtualMouseControls(
          scroll: scroll,
          translate: (s) => s,
          editing: editing,
          onPosition: onPosition ?? (_, __) {},
          onPositionEnd: () {},
        ),
      ],
    ),
  );
  final wheel = find.byKey(const ValueKey('virtual-wheel-slide'));

  testWidgets(
    'single wheel: hold does nothing, drag both ways, release stops',
    (tester) async {
      final steps = <int>[];
      int canvasTaps = 0;
      await tester.pumpWidget(
        app((n) async => steps.add(n), background: () => canvasTaps++),
      );
      expect(find.byKey(const ValueKey('virtual-mouse-left')), findsNothing);
      expect(find.byKey(const ValueKey('virtual-wheel-up')), findsNothing);
      final drag = await tester.startGesture(tester.getCenter(wheel));
      await tester.pump(const Duration(seconds: 1));
      expect(steps, isEmpty);
      await drag.moveBy(const Offset(0, -24));
      await tester.pump();
      await drag.moveBy(const Offset(0, 36));
      await tester.pump();
      expect(steps, [2, -3]);
      await drag.up();
      await tester.pump(const Duration(seconds: 1));
      expect(steps, [2, -3]);
      expect(canvasTaps, 0);
      await tester.tapAt(const Offset(400, 200));
      expect(canvasTaps, 1);
    },
  );

  testWidgets('slow transport never queues a tail; ignores second finger', (
    tester,
  ) async {
    final pending = Completer<void>();
    final steps = <int>[];
    await tester.pumpWidget(
      app((n) {
        steps.add(n);
        return pending.future;
      }),
    );
    final drag = await tester.startGesture(tester.getCenter(wheel), pointer: 1);
    final second = await tester.startGesture(
      tester.getCenter(wheel),
      pointer: 2,
    );
    await second.moveBy(const Offset(0, 40));
    await second.up();
    expect(steps, isEmpty);
    await drag.moveBy(const Offset(0, -24));
    await tester.pump();
    await drag.moveBy(const Offset(0, -24));
    await tester.pump();
    await drag.up();
    pending.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(steps, [2]);
  });

  testWidgets('background and cancellation discard the active drag', (
    tester,
  ) async {
    final steps = <int>[];
    await tester.pumpWidget(app((n) async => steps.add(n)));
    final drag = await tester.startGesture(tester.getCenter(wheel));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await drag.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(steps, isEmpty);
    await drag.cancel();
    final next = await tester.startGesture(tester.getCenter(wheel));
    await next.moveBy(const Offset(0, -12));
    await tester.pump();
    await next.cancel();
    expect(steps, [1]);
  });

  testWidgets('layout editing moves the wheel without scrolling', (
    tester,
  ) async {
    final steps = <int>[];
    Offset? position;
    await tester.pumpWidget(
      app(
        (n) async => steps.add(n),
        editing: true,
        onPosition: (_, p) => position = p,
      ),
    );
    await tester.drag(wheel, const Offset(50, 30));
    expect(position, isNotNull);
    expect(steps, isEmpty);
  });
  testWidgets('direction feedback resets and resize cancels wheel ownership', (tester) async {
    final steps = <int>[];
    await tester.pumpWidget(app((n) async => steps.add(n)));
    final finger = await tester.startGesture(tester.getCenter(wheel));
    await finger.moveBy(const Offset(0, -24));
    await tester.pump();
    final indicator = find.byKey(const ValueKey('virtual-wheel-direction'));
    expect(tester.widget<AnimatedSlide>(indicator).offset.dy, lessThan(0));
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pump();
    expect(tester.widget<AnimatedSlide>(indicator).offset, Offset.zero);
    await finger.moveBy(const Offset(0, 36));
    await finger.cancel();
    expect(steps, [2]);
  });

}
