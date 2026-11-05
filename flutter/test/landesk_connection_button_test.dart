import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_hbb/desktop/widgets/connection_action_button.dart';

void main() {
  testWidgets('connection labels retain vertical padding at larger text scales',
      (tester) async {
    for (final label in ['连接', 'Connect']) {
      for (final scale in [1.0, 1.5, 2.0]) {
        var clicks = 0;
        await tester.pumpWidget(MaterialApp(
          theme: LandeskTheme.build(Brightness.light,
              platform: TargetPlatform.macOS),
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: Center(
                      child: ConnectionActionButton(
                          label: label, onPressed: () => clicks++)))),
        ));
        await tester.pumpAndSettle();
        final button = tester.getRect(find.byType(ElevatedButton));
        final text = tester.getRect(find.text(label));
        expect(button.height, greaterThanOrEqualTo(text.height + 20));
        expect(button.contains(text.topLeft), isTrue);
        expect(button.contains(text.bottomRight), isTrue);
        await tester.tap(find.text(label));
        expect(clicks, 1);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
