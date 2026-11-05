import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/desktop/widgets/native_network_settings.dart';

class _Binding extends Fake implements RustdeskImpl {
  final saved = <String, String>{};
  @override
  String mainGetOptionSync({required String key, dynamic hint}) =>
      key == 'landesk-local-endpoints' ? '192.168.1.2:21118' : '';
  @override
  Future<void> mainSetOption({required String key, required String value, dynamic hint}) async {
    saved[key] = value;
  }
}

void main() {
  testWidgets('network settings expose only a native port and validate it', (tester) async {
    final binding = _Binding();
    platformFFI.setBindingForTesting(binding);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: NativeNetworkSettings(locked: false))));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Use a port between 1 and 65535'), findsOneWidget);
    expect(binding.saved, isEmpty);
    await tester.enterText(find.byType(TextField), '21218');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(binding.saved, {'direct-access-port': '21218'});
  });
}
