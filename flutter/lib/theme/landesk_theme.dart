import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Vibelet's minimal (素雅) design language, implemented with native Flutter
/// controls. Values are shared by every platform and every application window.
class SuyaPalette {
  const SuyaPalette({
    required this.background,
    required this.surface,
    required this.inset,
    required this.text,
    required this.secondary,
    required this.border,
    required this.strongBorder,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.dangerSurface,
  });

  final Color background, surface, inset, text, secondary, border, strongBorder;
  final Color accent, onAccent, danger, dangerSurface;
  Color get selection =>
      Color.alphaBlend(accent.withValues(alpha: .10), background);
  static const light = SuyaPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    inset: Color(0xFFF5F6F8),
    text: Color(0xFF141414),
    secondary: Color(0xFF62666D),
    border: Color(0x14000000),
    strongBorder: Color(0x29000000),
    accent: Color(0xFF2F7A4B),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC62828),
    dangerSurface: Color(0xFFFFF0F0),
  );
  static const dark = SuyaPalette(
    background: Color(0xFF181818),
    surface: Color(0xFF222222),
    inset: Color(0xFF2A2A2A),
    text: Color(0xFFECECEC),
    secondary: Color(0xFFB4B4B4),
    border: Color(0x14FFFFFF),
    strongBorder: Color(0x29FFFFFF),
    accent: Color(0xFF5BB575),
    onAccent: Color(0xFF181818),
    danger: Color(0xFFFF8585),
    dangerSurface: Color(0xFF402323),
  );
  static SuyaPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class LandeskTheme {
  static const controlRadius = 14.0;
  static const cardRadius = 20.0;
  static const motion = Duration(milliseconds: 150);

  static ThemeData build(Brightness brightness, {TargetPlatform? platform}) {
    platform ??= defaultTargetPlatform;
    final touch =
        platform == TargetPlatform.iOS || platform == TargetPlatform.android;
    final p = brightness == Brightness.dark
        ? SuyaPalette.dark
        : SuyaPalette.light;
    final height = touch ? 44.0 : 40.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: BorderSide(color: p.border),
    );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: p.onAccent,
          primaryContainer: p.selection,
          onPrimaryContainer: p.text,
          secondary: p.accent,
          onSecondary: p.onAccent,
          secondaryContainer: p.selection,
          onSecondaryContainer: p.text,
          // Legacy desktop pages still read these deprecated background fields.
          background: p.background,
          onBackground: p.text,
          surface: p.surface,
          onSurface: p.text,
          onSurfaceVariant: p.secondary,
          surfaceContainerLowest: p.background,
          surfaceContainerLow: p.surface,
          surfaceContainer: p.inset,
          surfaceContainerHigh: p.inset,
          surfaceContainerHighest: p.inset,
          outline: p.strongBorder,
          outlineVariant: p.border,
          error: p.danger,
          errorContainer: p.dangerSurface,
          onErrorContainer: p.danger,
          onError: p.onAccent,
          surfaceTint: Colors.transparent,
        );
    Color? overlay(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) return Colors.transparent;
      if (states.contains(WidgetState.pressed)) {
        return p.accent.withValues(alpha: .16);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return p.accent.withValues(alpha: .08);
      }
      return null;
    }

    final baseButton = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(64, height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      shape: WidgetStatePropertyAll(shape),
      elevation: const WidgetStatePropertyAll(0),
      animationDuration: motion,
      overlayColor: WidgetStateProperty.resolveWith(overlay),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused)
              ? p.accent
              : Colors.transparent,
          width: states.contains(WidgetState.focused) ? 2 : 1,
        ),
      ),
    );
    final filled = baseButton.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? p.inset : p.accent,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? p.secondary : p.onAccent,
      ),
    );
    final neutral = baseButton.copyWith(
      backgroundColor: WidgetStatePropertyAll(p.surface),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? p.secondary : p.text,
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused)
              ? p.accent
              : p.strongBorder,
          width: states.contains(WidgetState.focused) ? 2 : 1,
        ),
      ),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: color, width: width),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: platform,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      primaryColor: p.accent,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.surface,
      dividerColor: p.border,
      disabledColor: p.secondary.withValues(alpha: .56),
      hintColor: p.secondary,
      hoverColor: p.selection,
      focusColor: p.selection,
      splashFactory: NoSplash.splashFactory,
      textTheme: base.textTheme
          .apply(bodyColor: p.text, displayColor: p.text)
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: p.text,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: p.text,
            ),
            titleSmall: TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: p.text,
            ),
            bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: p.text),
            bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: p.text),
            bodySmall: TextStyle(fontSize: 12, height: 1.5, color: p.secondary),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: p.text,
            ),
          ),
      appBarTheme: AppBarThemeData(
        backgroundColor: p.background,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.text,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: cardShape,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.all(6),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: p.text, fontSize: 14, height: 1.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(cardRadius),
          ),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: p.inset,
        isDense: !touch,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.accent, 2),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 2),
        disabledBorder: inputBorder(p.border),
        hintStyle: TextStyle(color: p.secondary),
        labelStyle: TextStyle(color: p.secondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: filled),
      filledButtonTheme: FilledButtonThemeData(style: filled),
      outlinedButtonTheme: OutlinedButtonThemeData(style: neutral),
      textButtonTheme: TextButtonThemeData(
        style: baseButton.copyWith(
          foregroundColor: WidgetStatePropertyAll(p.accent),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: baseButton.copyWith(
          minimumSize: WidgetStatePropertyAll(Size.square(touch ? 44 : 32)),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
          foregroundColor: WidgetStatePropertyAll(p.secondary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: shape,
        tileColor: p.surface,
        selectedTileColor: p.selection,
        selectedColor: p.accent,
        iconColor: p.secondary,
        textColor: p.text,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.background,
        indicatorColor: p.selection,
        useIndicator: true,
        selectedIconTheme: IconThemeData(color: p.accent),
        unselectedIconTheme: IconThemeData(color: p.secondary),
        selectedLabelTextStyle: TextStyle(color: p.accent),
        unselectedLabelTextStyle: TextStyle(color: p.secondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        indicatorColor: p.selection,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.accent
                : p.secondary,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        selectedItemColor: p.accent,
        unselectedItemColor: p.secondary,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.accent,
        unselectedLabelColor: p.secondary,
        dividerColor: p.border,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: p.selection,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.inset,
        selectedColor: p.selection,
        disabledColor: p.inset,
        side: BorderSide(color: p.border),
        shape: shape,
        labelStyle: TextStyle(color: p.text, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: p.strongBorder),
        checkColor: WidgetStatePropertyAll(p.onAccent),
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.surface,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(p.surface),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.strongBorder,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.secondary,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        thumbColor: p.accent,
        inactiveTrackColor: p.inset,
        overlayColor: p.selection,
        trackHeight: 4,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          side: BorderSide(color: p.border),
        ),
        textStyle: TextStyle(color: p.text, fontSize: 14),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          elevation: const WidgetStatePropertyAll(2),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(controlRadius),
              side: BorderSide(color: p.border),
            ),
          ),
        ),
      ),
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: neutral.copyWith(
          side: const WidgetStatePropertyAll(BorderSide.none),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.text,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: p.background, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.text,
        contentTextStyle: TextStyle(color: p.background),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: shape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(6),
        thumbColor: WidgetStatePropertyAll(p.secondary.withValues(alpha: .4)),
      ),
    );
  }
}
