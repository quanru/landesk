import 'package:flutter/material.dart';

/// Let the active theme and text scale determine the connection button height.
class ConnectionActionButton extends StatelessWidget {
  const ConnectionActionButton(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      );
}
