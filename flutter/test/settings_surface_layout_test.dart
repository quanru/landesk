import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/settings_section_card.dart';
import 'package:flutter_hbb/theme/landesk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      testWidgets('settings $brightness $size with large text', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var remember = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: LandeskTheme.build(brightness, platform: TargetPlatform.iOS),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SettingsSectionCard(
                      title: 'Connection preferences',
                      children: [
                        StatefulBuilder(
                          builder: (context, setState) => CheckboxListTile(
                            title: const Text('Remember credentials'),
                            subtitle: const Text(
                              'Use saved credentials on this device',
                            ),
                            value: remember,
                            onChanged: (value) =>
                                setState(() => remember = value!),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Computer address',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        expect(remember, isTrue);
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '192.168.1.2');
        expect(find.text('192.168.1.2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
