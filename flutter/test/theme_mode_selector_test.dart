import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common/widgets/settings_section_card.dart';
import 'package:flutter_hbb/common/widgets/theme_mode_selector.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final output = Platform.environment['LANDESK_THEME_SELECTOR_PREVIEW_DIR'];
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
    for (final width in [375.0, 800.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$brightness width $width text $scale', (tester) async {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var selected = ThemeMode.system;
          var enabled = true;
          final capture = GlobalKey();
          final theme = LandeskTheme.build(brightness);
          final preview = output == null
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
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: preview,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: StatefulBuilder(
                    builder: (context, setState) => ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        RepaintBoundary(
                          key: capture,
                          child: ColoredBox(
                            color: theme.scaffoldBackgroundColor,
                            child: SettingsSectionCard(
                              title: 'Appearance',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: ThemeModeSelector(
                                    value: selected,
                                    translate: (text) => text,
                                    onChanged: enabled
                                        ? (value) =>
                                              setState(() => selected = value)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => enabled = false),
                          child: const Text('Disable'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Dark'));
          await tester.pumpAndSettle();
          expect(selected, ThemeMode.dark);
          expect(tester.takeException(), isNull);
          if (output != null && width == 800 && scale == 1) {
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
                '$output/appearance-${brightness.name}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              rendered.dispose();
            });
          }
          await tester.ensureVisible(find.text('Disable'));
          await tester.tap(find.text('Disable'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widgetList<OutlinedButton>(find.byType(OutlinedButton))
                .every((button) => button.onPressed == null),
            isTrue,
          );
          expect(selected, ThemeMode.dark);
        });
      }
    }
  }
}
