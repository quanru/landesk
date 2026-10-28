import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/lan_connect_dialog.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('small window: checkbox and connect work in $brightness', (tester) async {
      tester.view.physicalSize = const Size(800, 510);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final endpoint = TextEditingController();
      final username = TextEditingController(text: 'test-user');
      final password = TextEditingController(text: 'test-only-password');
      addTearDown(endpoint.dispose);
      addTearDown(username.dispose);
      addTearDown(password.dispose);
      var calls = 0;
      bool? remembered;
      String? submittedEndpoint;
      await tester.pumpWidget(MaterialApp(
        theme: LandeskTheme.build(brightness, platform: TargetPlatform.macOS),
        home: Builder(builder: (context) => Scaffold(body: TextButton(
          onPressed: () => showDialog<void>(context: context, builder: (_) => LanConnectDialog(
            endpoint: endpoint, username: username, password: password,
            translate: (text) => text,
            onConnect: (remember) async {
              calls++;
              remembered = remember;
              submittedEndpoint = endpoint.text;
              return true;
            },
          )),
          child: const Text('Open'),
        ))),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Username · Password'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Invalid IP'), findsOneWidget);
      final ip = find.byKey(const ValueKey('lan-endpoint'));
      await tester.ensureVisible(ip);
      await tester.enterText(ip, '127.0.0.1:21118');
      await tester.pumpAndSettle();
      final remember = find.byKey(const ValueKey('lan-remember'));
      await tester.ensureVisible(remember);
      await tester.pumpAndSettle();
      await tester.tap(remember, warnIfMissed: true);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(remember).value, isTrue);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(remembered, isTrue);
      expect(submittedEndpoint, '127.0.0.1:21118');
      expect(find.byType(LanConnectDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
