import 'package:flutter/material.dart';

/// Keeps remote input mounted when the rail, keyboard or a panel changes.
class RemoteSessionLayout extends StatelessWidget {
  const RemoteSessionLayout({
    super.key,
    required this.child,
    this.rail,
    this.panel,
  });

  final Widget child;
  final Widget? rail;
  final Widget? panel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (panel != null)
              Align(alignment: Alignment.centerRight, child: panel),
          ],
        ),
      ),
      if (rail != null) rail!,
    ],
  );
}

class RemoteActionRail extends StatelessWidget {
  const RemoteActionRail({
    super.key,
    required this.children,
    required this.onCollapse,
    required this.collapseLabel,
  });

  static const double width = 72;
  final List<Widget> children;
  final VoidCallback onCollapse;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      left: false,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: collapseLabel,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onCollapse,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ),
  );
}

class RemoteRailButton extends StatelessWidget {
  const RemoteRailButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Semantics(
        selected: selected,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurface,
            backgroundColor: selected ? colors.surfaceContainerHighest : null,
            minimumSize: const Size(64, 64),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RemoteSessionPanel extends StatelessWidget {
  const RemoteSessionPanel({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.clamp(0.0, 360.0).toDouble();
      final colors = Theme.of(context).colorScheme;
      return SizedBox(
        width: width,
        child: Material(
          color: colors.surfaceContainerLow,
          child: SafeArea(
            left: false,
            right: false,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(
                  (width - 24).clamp(0.0, width),
                  constraints.maxHeight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 4, top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: onClose,
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
