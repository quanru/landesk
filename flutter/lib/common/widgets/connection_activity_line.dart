import 'package:flutter/material.dart';
import '../../common.dart';
import '../../models/connection_activity.dart';

class ConnectionActivityLine extends StatelessWidget {
  const ConnectionActivityLine({
    super.key,
    required this.endpoint,
    required this.onReconnect,
  });
  final String endpoint;
  final VoidCallback onReconnect;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: connectionActivities,
    builder: (context, _) {
      final activity = connectionActivities.forPeer(endpoint);
      if (activity == null || activity.phase == ConnectionPhase.closed) {
        return const SizedBox.shrink();
      }
      final failed = activity.phase == ConnectionPhase.failed;
      final waiting = activity.phase == ConnectionPhase.connecting;
      final auth = activity.phase == ConnectionPhase.authentication;
      final label = activity.message.isNotEmpty
          ? translate(activity.message)
          : translate(switch (activity.phase) {
              ConnectionPhase.connecting => 'Connecting...',
              ConnectionPhase.connected => 'Ready',
              ConnectionPhase.authentication => 'Password Required',
              _ => 'Connection Error',
            });
      final color = failed
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurfaceVariant;
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            if (waiting)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Icon(
                auth
                    ? Icons.lock_outline
                    : failed
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                size: 14,
                color: color,
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Tooltip(
                message: label,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ),
            if (failed || auth)
              TextButton(
                onPressed: () async {
                  if (!await connectionActivities.retry(endpoint)) {
                    onReconnect();
                  }
                },
                child: Text(translate('Retry')),
              ),
          ],
        ),
      );
    },
  );
}
