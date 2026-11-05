import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/desktop/widgets/settings_session_guard.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';

void main() {
  testWidgets('blocked settings explain recovery and allow returning home',
      (tester) async {
    var edits = 0;
    var returned = false;
    Widget page(bool blocked) => MaterialApp(
        theme: LandeskTheme.build(Brightness.light),
        home: Scaffold(
            body: SettingsSessionGuard(
                blocked: blocked,
                onBack: () => returned = true,
                child: Align(
                    alignment: Alignment.topLeft,
                    child: TextButton(
                        onPressed: () => edits++,
                        child: const Text('Change password'))))));
    await tester.pumpWidget(page(true));
    expect(
        find.text('Settings protected during remote access'), findsOneWidget);
    await tester.tap(find.text('Change password'), warnIfMissed: false);
    expect(edits, 0);
    await tester.tap(find.text('Back to home'));
    expect(returned, isTrue);
    await tester.pumpWidget(page(false));
    expect(find.descendant(of: find.byType(SettingsSessionGuard), matching: find.byType(ModalBarrier)), findsNothing);
    await tester.tap(find.text('Change password'));
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });
}
