import 'package:flutter/material.dart';
import '../../common/landesk_text.dart';

/// Keeps the existing host restriction and explains how to recover.
class SettingsSessionGuard extends StatelessWidget {
  const SettingsSessionGuard(
      {super.key,
      required this.blocked,
      required this.onBack,
      required this.child});
  final bool blocked;
  final VoidCallback onBack;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        ExcludeFocus(
            excluding: blocked,
            child: AbsorbPointer(absorbing: blocked, child: child)),
        if (blocked) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
                width: 440,
                child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.lock_outline, size: 32),
                        const SizedBox(height: 16),
                        Text(
                            landeskText(context,
                                'Settings protected during remote access'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Text(
                            landeskText(context,
                                'Disconnect the remote session, then unlock Security settings on this computer to change the password. Settings become available automatically after disconnection.'),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: onBack,
                            child: Text(landeskText(context, 'Back to home'))),
                      ])),
                )),
          )),
        ],
      ]);
}
