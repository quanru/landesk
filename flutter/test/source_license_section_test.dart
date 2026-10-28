import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/source_license_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('license remains readable offline from bundled asset', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: SourceLicenseSection())),
    ));
    expect(find.text('Get corresponding source'), findsOneWidget);
    await tester.tap(find.text('AGPL-3.0'));
    await tester.pumpAndSettle();
    expect(find.text('GNU AGPL v3'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is SelectableText &&
        (widget.data?.contains('Remote Network Interaction') ?? false)), findsOneWidget);
  });
}
