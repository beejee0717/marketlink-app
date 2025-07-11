import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String textLabel;
  final double fontSize;
  final Color textColor;
  final FontWeight fontWeight;
  final double letterSpacing;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final FontStyle fontStyle;
  final TextDecoration decoration;
  const CustomText(
      {super.key,
      required this.textLabel,
      required this.fontSize,
      this.textColor = Colors.black,
      this.fontWeight = FontWeight.normal,
      this.letterSpacing = 0,
      this.textAlign = TextAlign.start,
      this.maxLines = 1,
      this.decoration = TextDecoration.none,

      this.overflow = TextOverflow.clip,
      this.fontStyle = FontStyle.normal});

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      textLabel,
      textAlign: textAlign,
      maxLines: maxLines,
      style: TextStyle(
          fontStyle: fontStyle,
          fontSize: fontSize,
          overflow: overflow,
          color: textColor,
          fontWeight: fontWeight,
          decoration: decoration,
          letterSpacing: letterSpacing),
    );
  }
}
