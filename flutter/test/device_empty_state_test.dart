import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common/widgets/device_empty_state.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final output = Platform.environment['LANDESK_EMPTY_PREVIEW_DIR'];
  setUpAll(() async {
    final font = Platform.environment['LANDESK_PREVIEW_FONT'];
    if (font != null) {
      await (FontLoader('Preview')..addFont(
            File(
              font,
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  for (final brightness in Brightness.values) {
    for (final size in [const Size(320, 240), const Size(800, 600)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('empty search $brightness $size text $scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final capture = GlobalKey();
          var cleared = false;
          final theme = LandeskTheme.build(brightness);
          final styled = output == null
              ? theme
              : theme.copyWith(
                  textTheme: theme.textTheme.apply(fontFamily: 'Preview'),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: theme.outlinedButtonTheme.style!.copyWith(
                      textStyle: WidgetStatePropertyAll(
                        theme.textTheme.labelLarge!.copyWith(
                          fontFamily: 'Preview',
                        ),
                      ),
                    ),
                  ),
                );
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: styled,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: DeviceEmptyState(
                    title: 'No matching devices',
                    description:
                        'Try another device name or IP address, or clear the search to see all devices.',
                    icon: Icons.search_off_rounded,
                    actionLabel: 'Clear search',
                    onAction: () => cleared = true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (output != null && size.width == 800 && scale == 1) {
            final boundary =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final rendered = await boundary.toImage(pixelRatio: 2);
              final bytes = await rendered.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(output).create(recursive: true);
              await File(
                '$output/search-${brightness.name}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              rendered.dispose();
            });
          }
          await tester.ensureVisible(find.byType(OutlinedButton));
          await tester.tap(find.byType(OutlinedButton));
          await tester.pumpAndSettle();
          expect(cleared, isTrue);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
