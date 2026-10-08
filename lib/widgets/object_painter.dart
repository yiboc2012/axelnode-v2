import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final Size widgetSize;

  ObjectPainter(this.objects, this.imageSize, this.widgetSize);

  @override
  void paint(Canvas canvas, Size size) {
    double scale = max(widgetSize.width / imageSize.width, widgetSize.height / imageSize.height);
    double offsetX = (widgetSize.width - imageSize.width * scale) / 2;
    double offsetY = (widgetSize.height - imageSize.height * scale) / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.greenAccent;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var object in objects) {
      final rect = Rect.fromLTRB(
        object.boundingBox.left * scale + offsetX,
        object.boundingBox.top * scale + offsetY,
        object.boundingBox.right * scale + offsetX,
        object.boundingBox.bottom * scale + offsetY,
      );

      canvas.drawRect(rect, paint);

      final label = object.labels.isNotEmpty ? object.labels.first.text : 'Object';
      textPainter.text = TextSpan(
        text: label.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.greenAccent,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - textPainter.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
