import 'package:flutter/material.dart';

/// One appearance control shared by desktop and mobile settings.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.translate,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode>? onChanged;
  final String Function(String) translate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const choices = [
      (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
      (ThemeMode.system, Icons.brightness_auto_outlined, 'Follow System'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal =
            constraints.maxWidth >= 560 &&
            MediaQuery.textScalerOf(context).scale(14) <= 18;
        final width = horizontal
            ? (constraints.maxWidth - 16) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: choices.map((choice) {
            final selected = value == choice.$1;
            return SizedBox(
              width: width,
              child: Semantics(
                selected: selected,
                child: OutlinedButton(
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(choice.$1),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? theme.colorScheme.surface
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(choice.$2, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(translate(choice.$3))),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 18,
                        child: selected
                            ? const Icon(Icons.check_rounded, size: 18)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
