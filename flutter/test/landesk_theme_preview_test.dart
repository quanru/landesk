import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Optional local design review artifact: LANDESK_THEME_PREVIEW_DIR=/tmp/... flutter test ...
void main() {
  setUpAll(() async {
    final font = Platform.environment['LANDESK_PREVIEW_FONT'];
    if (font != null) {
      final loader = FontLoader('Preview')
        ..addFont(
          File(font).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  for (final brightness in Brightness.values) {
    testWidgets('component preview $brightness', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: previewTheme(brightness),
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: AppBar(title: const Text('landesk')),
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: 0,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.devices),
                        label: Text('Devices'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your local workspace',
                            style: previewTheme(
                              brightness,
                            ).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Computer address',
                                      hintText: '192.168.1.2',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {},
                                        child: const Text('Connect'),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () {},
                                        child: const Text('Settings'),
                                      ),
                                      const SizedBox(width: 12),
                                      const ElevatedButton(
                                        onPressed: null,
                                        child: Text('Unavailable'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Column(
                              children: [
                                const ListTile(
                                  leading: Icon(Icons.desktop_mac),
                                  title: Text('Mac mini'),
                                  subtitle: Text('100.66.69.79'),
                                  trailing: Icon(Icons.chevron_right),
                                ),
                                SwitchListTile(
                                  title: const Text('Remember credentials'),
                                  value: true,
                                  onChanged: (_) {},
                                ),
                                CheckboxListTile(
                                  title: const Text('Show virtual keys'),
                                  value: true,
                                  onChanged: (_) {},
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('System'),
                                selected: true,
                                onSelected: (_) {},
                              ),
                              ChoiceChip(
                                label: const Text('Light'),
                                selected: false,
                                onSelected: (_) {},
                              ),
                              ChoiceChip(
                                label: const Text('Dark'),
                                selected: false,
                                onSelected: (_) {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final output = Platform.environment['LANDESK_THEME_PREVIEW_DIR'];
      if (output != null) {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory(output).create(recursive: true);
          await File(
            '$output/${brightness.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }
    });
  }
}

ThemeData previewTheme(Brightness brightness) {
  final theme = LandeskTheme.build(brightness, platform: TargetPlatform.macOS);
  return Platform.environment['LANDESK_PREVIEW_FONT'] == null
      ? theme
      : theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Preview'),
          primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Preview'),
        );
}
