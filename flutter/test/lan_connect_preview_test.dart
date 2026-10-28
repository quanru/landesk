import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common/widgets/lan_connect_dialog.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Optional screenshots of the production dialog, not native window captures.
void main() {
  final output = Platform.environment['LANDESK_DIALOG_PREVIEW_DIR'];
  if (output == null) return;
  setUpAll(() async {
    final font = Platform.environment['LANDESK_PREVIEW_FONT'];
    if (font != null) {
      for (final family in [
        'Roboto',
        '.SF UI Text',
        '.SF UI Display',
        'Ahem',
      ]) {
        await (FontLoader(family)..addFont(
              File(
                font,
              ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            ))
            .load();
      }
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final brightness in Brightness.values) {
    testWidgets('connection dialog preview $brightness', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final endpoint = TextEditingController(text: '192.168.1.2');
      final username = TextEditingController(text: 'username');
      final password = TextEditingController();
      addTearDown(endpoint.dispose);
      addTearDown(username.dispose);
      addTearDown(password.dispose);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: LandeskTheme.build(
              brightness,
              platform: TargetPlatform.macOS,
            ),
            home: Scaffold(
              body: LanConnectDialog(
                endpoint: endpoint,
                username: username,
                password: password,
                translate: (text) => text,
                onConnect: (_) async => false,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Username · Password'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 2);
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/connect-${brightness.name}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        rendered.dispose();
      });
    });
  }
}
