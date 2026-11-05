import 'package:flutter/material.dart';

/// Keeps keyboard shortcuts reachable without covering the landscape desktop.
class CompactKeyboardToolbar extends StatelessWidget {
  const CompactKeyboardToolbar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in children)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: child,
              ),
          ],
        ),
      );
}
