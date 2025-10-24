import 'package:flutter/material.dart';
import 'dart:math' as math;

// Вариант A: Однонаправленный бегущий свет
class BorderLoaderPainterA extends CustomPainter {
  final double progress;
  final Color color;

  BorderLoaderPainterA({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;
    
    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final currentLength = totalLength * progress;
    final glowPath = pathMetrics.extractPath(0, currentLength);
    canvas.drawPath(glowPath, glowPaint);
    
    // Main line with gradient
    final mainPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.4),
          color,
          color,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final extractPath = pathMetrics.extractPath(0, currentLength);
    canvas.drawPath(extractPath, mainPaint);
    
    // Leading dot
    if (progress > 0 && progress < 1) {
      final dotPosition = pathMetrics.getTangentForOffset(currentLength)?.position;
      if (dotPosition != null) {
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(dotPosition, 2.5, dotPaint);
        
        final dotGlowPaint = Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(dotPosition, 4, dotGlowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(BorderLoaderPainterA oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Вариант B: Двунаправленный gradient sweep
class BorderLoaderPainterB extends CustomPainter {
  final double progress;
  final Color color;

  BorderLoaderPainterB({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;
    
    // Двунаправленный эффект: от центра к краям
    final centerProgress = (progress * 2).clamp(0.0, 1.0);
    final halfLength = totalLength / 2;
    
    // Первая половина (по часовой)
    final length1 = halfLength * centerProgress;
    final path1 = pathMetrics.extractPath(halfLength, halfLength + length1);
    
    // Вторая половина (против часовой)
    final length2 = halfLength * centerProgress;
    final path2 = pathMetrics.extractPath(halfLength - length2, halfLength);
    
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.2),
          color,
          color.withOpacity(0.2),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(BorderLoaderPainterB oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Вариант C: Марширующий пунктир
class BorderLoaderPainterC extends CustomPainter {
  final double progress;
  final Color color;

  BorderLoaderPainterC({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;
    
    // Марширующий пунктир
    final dashLength = 10.0;
    final gapLength = 5.0;
    final offset = progress * (dashLength + gapLength);
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double distance = -offset;
    while (distance < totalLength) {
      if (distance >= 0) {
        final start = distance;
        final end = (distance + dashLength).clamp(0.0, totalLength);
        final dashPath = pathMetrics.extractPath(start, end);
        canvas.drawPath(dashPath, paint);
      }
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(BorderLoaderPainterC oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
