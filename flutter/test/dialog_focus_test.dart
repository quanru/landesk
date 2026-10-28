import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dialog rebuild retains active field and composing text', (
    tester,
  ) async {
    final username = TextEditingController();
    final password = TextEditingController();
    addTearDown(username.dispose);
    addTearDown(password.dispose);
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return CustomAlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DialogTextField(title: 'Username', controller: username),
                    DialogTextField(
                      title: 'Password',
                      controller: password,
                      autofocus: false,
                      obscureText: true,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).last);
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'typing',
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 0, end: 6),
      ),
    );
    await tester.pump();
    final activeFocus = FocusManager.instance.primaryFocus;
    final oldScope = activeFocus!.enclosingScope;
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(activeFocus));
    expect(activeFocus.enclosingScope, same(oldScope));
    expect(password.value.composing, const TextRange(start: 0, end: 6));
    expect(username.text, isEmpty);
  });
}
