import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/compact_keyboard_toolbar.dart';

void main() {
  testWidgets('landscape shortcuts leave room for desktop and remain reachable',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 360,
          height: 140,
          child: Column(children: [
            CompactKeyboardToolbar(children: [
              for (var i = 0; i < 20; i++)
                TextButton(onPressed: () {}, child: Text('Key $i')),
            ]),
            const Expanded(child: SizedBox(key: ValueKey('desktop'))),
          ]),
        ),
      ),
    ));
    expect(tester.getSize(find.byKey(const ValueKey('desktop'))).height,
        greaterThan(80));
    await tester.dragUntilVisible(find.text('Key 19'),
        find.byType(SingleChildScrollView), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(find.text('Key 19').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
