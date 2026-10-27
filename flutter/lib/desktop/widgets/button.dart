import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../common.dart';

/// Legacy call sites share native themed buttons, including keyboard activation,
/// focus, disabled/hover/pressed states and the same touch target as mobile.
class Button extends StatelessWidget {
  const Button({
    super.key,
    this.minWidth,
    this.isOutline = false,
    this.textSize,
    this.padding,
    this.textColor,
    this.radius,
    this.borderColor,
    required this.onTap,
    required this.text,
  });
  final GestureTapCallback onTap;
  final String text;
  final double? textSize, minWidth, padding, radius;
  final bool isOutline;
  final Color? textColor, borderColor;

  @override
  Widget build(BuildContext context) => _themedButton(
    context,
    onTap: onTap,
    text: text,
    isOutline: isOutline,
    textSize: textSize,
    padding: padding,
    textColor: textColor,
    radius: radius,
    borderColor: borderColor,
    minWidth: minWidth,
  );
}

class FixedWidthButton extends StatelessWidget {
  const FixedWidthButton({
    super.key,
    required this.width,
    this.maxLines,
    this.isOutline = false,
    this.textSize,
    this.padding,
    this.textColor,
    this.radius,
    this.borderColor,
    required this.onTap,
    required this.text,
  });
  final GestureTapCallback onTap;
  final String text;
  final double width;
  final double? textSize, padding, radius;
  final bool isOutline;
  final Color? textColor, borderColor;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: _themedButton(
      context,
      onTap: onTap,
      text: text,
      isOutline: isOutline,
      textSize: textSize,
      padding: padding,
      textColor: textColor,
      radius: radius,
      borderColor: borderColor,
      maxLines: maxLines,
    ),
  );
}

Widget _themedButton(
  BuildContext context, {
  required GestureTapCallback onTap,
  required String text,
  required bool isOutline,
  double? textSize,
  double? padding,
  Color? textColor,
  double? radius,
  Color? borderColor,
  double? minWidth,
  int? maxLines,
}) {
  final style = ButtonStyle(
    minimumSize: minWidth == null
        ? null
        : WidgetStatePropertyAll(
            Size(
              minWidth,
              Theme.of(context).elevatedButtonTheme.style?.minimumSize?.resolve({})?.height ?? 44,
            ),
          ),
    padding: padding == null
        ? null
        : WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: padding),
          ),
    foregroundColor: textColor == null
        ? null
        : WidgetStatePropertyAll(textColor),
    shape: radius == null
        ? null
        : WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          ),
    side: borderColor == null
        ? null
        : WidgetStatePropertyAll(BorderSide(color: borderColor)),
  );
  final child = AutoSizeText(
    translate(text),
    maxLines: maxLines ?? 1,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: textSize ?? 14),
  );
  return isOutline
      ? OutlinedButton(onPressed: onTap, style: style, child: child)
      : ElevatedButton(onPressed: onTap, style: style, child: child);
}
