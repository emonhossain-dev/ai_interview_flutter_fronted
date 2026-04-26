import 'package:flutter/material.dart';

double getFontSize(String text, double maxWidth, int maxLines) {
  double fontSize = 15;
  final textPainter = TextPainter(textDirection: TextDirection.ltr);

  while (fontSize > 8) {
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, height: 1.6),
    );
    textPainter.layout(maxWidth: maxWidth);
    if (textPainter.computeLineMetrics().length <= maxLines) break;
    fontSize -= 0.5;
  }
  return fontSize;
}