import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/remote_input_stack.dart';
import 'package:flutter_hbb/common/widgets/overlay.dart';

void main() {
  testWidgets('connecting toolbar mask leaves room for session login dialogs', (
    tester,
  ) async {
    for (final height in [0.0, 80.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(key: ValueKey('session body')),
            bottomNavigationBar: Stack(
              children: [
                SizedBox(height: height),
                const RemoteToolbarMask(color: Colors.black),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('session body'))).height,
        tester.view.physicalSize.height / tester.view.devicePixelRatio - height,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'keyboard inset and floating controls preserve the input connection',
    (tester) async {
      final focus = FocusNode();
      final controller = TextEditingController();
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);
      Widget app(bool keyboard) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(852, 393),
            viewInsets: EdgeInsets.only(bottom: keyboard ? 180 : 0),
          ),
          child: Scaffold(
            body: RemoteInputStack(
              controls: keyboard
                  ? null
                  : const Align(
                      alignment: Alignment.topRight,
                      child: Text('floating keys'),
                    ),
              child: TextField(focusNode: focus, controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(false));
      await tester.showKeyboard(find.byType(TextField));
      final input = tester.state(find.byType(EditableText));
      await tester.pumpWidget(app(true));
      expect(tester.state(find.byType(EditableText)), same(input));
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.enterText('landscape typing');
      expect(controller.text, 'landscape typing');
      await tester.pumpWidget(app(false));
      expect(tester.state(find.byType(EditableText)), same(input));
      expect(focus.hasFocus, isTrue);
    },
  );

  testWidgets('session overlay remains available after controls disappear', (
    tester,
  ) async {
    final overlay = BlockableOverlayState();
    Widget app(bool controls) => MaterialApp(
      home: Scaffold(
        body: RemoteInputStack(
          controls: controls ? const Text('floating keys') : null,
          child: BlockableOverlay(
            state: overlay,
            underlying: Text(controls ? 'remote image' : 'keyboard requested'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(true));
    final state = overlay.state;
    expect(state, isNotNull);
    expect(overlay.key!.currentState, same(state));
    await tester.pumpWidget(app(false));
    expect(overlay.state, same(state));
    expect(find.text('keyboard requested'), findsOneWidget);
    expect(find.text('remote image'), findsNothing);
    final entry = OverlayEntry(
      builder: (_) => const Align(child: Text('chat window')),
    );
    state!.insert(entry);
    await tester.pump();
    expect(find.text('chat window'), findsOneWidget);
    entry.remove();
    entry.dispose();
  });
}
