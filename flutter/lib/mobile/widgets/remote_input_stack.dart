import 'package:flutter/widgets.dart';

/// Covers a connecting toolbar without taking space from the remote body.
class RemoteToolbarMask extends StatelessWidget {
  const RemoteToolbarMask({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Positioned.fill(child: ColoredBox(color: color));
}

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
