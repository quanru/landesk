import 'package:flutter/widgets.dart';

/// Keeps the focused remote input mounted while floating controls appear/hide.
class RemoteInputStack extends StatelessWidget {
  const RemoteInputStack({super.key, required this.child, this.controls});

  final Widget child;
  final Widget? controls;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [child, if (controls != null) controls!],
  );
}
