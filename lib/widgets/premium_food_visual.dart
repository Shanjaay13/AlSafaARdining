import 'dart:math' as math;
import 'package:flutter/material.dart';

class PremiumFoodVisual extends StatelessWidget {
  final Map<String, dynamic> item;
  final double size;

  const PremiumFoodVisual({Key? key, required this.item, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemId = item['id'] ?? '';
    final name = item['name'] ?? '';
    final category = item['category'] ?? '';

    // Determine the base high-quality dining photography asset for perfect visual consistency
    String baseImagePath = 'assets/satay.png';
    if (category.contains('Roti') || name.contains('Roti') || name.contains('Bakar') || name.contains('John')) {
      if (name.contains('Tisu')) {
        baseImagePath = 'assets/roti_tisu.png';
      } else {
        baseImagePath = 'assets/roti_canai.png';
      }
    } else if (category.contains('Drink')) {
      if (itemId.contains('bandung')) {
        baseImagePath = 'assets/sirap_bandung.png';
      } else if (itemId.contains('milo_dinosaur')) {
        baseImagePath = 'assets/milo_dinosaur.png';
      } else {
        baseImagePath = 'assets/teh_tarik.png';
      }
    } else if (category.contains('Nasi') || category.contains('Mee') || category.contains('Lauk')) {
      if (itemId.contains('nasi_lemak')) {
        baseImagePath = 'assets/nasi_lemak.png';
      } else if (itemId.contains('nasi_kandar')) {
        baseImagePath = 'assets/nasi_kandar.png';
      } else if (itemId.contains('maggi_goreng')) {
        baseImagePath = 'assets/maggi_goreng.png';
      } else {
        baseImagePath = 'assets/mee_goreng.png';
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF121412),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. High-fidelity realistic base dining photograph
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                baseImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Final recovery fallback in case files are missing
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F2A1D), Color(0xFF121412)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.local_dining, color: Color(0xFFD4A24C), size: 48),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // 2. Translucent vignetting to integrate text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),

          // 3. Topping overlays drawn directly on top of the realistic photo base
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: ToppingOverlayPainter(
                  itemId: itemId,
                  name: name,
                  category: category,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ToppingOverlayPainter extends CustomPainter {
  final String itemId;
  final String name;
  final String category;

  ToppingOverlayPainter({
    required this.itemId,
    required this.name,
    required this.category,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Apply specific toppings directly over the realistic photo canvas coordinates
    if (category.contains('Roti') || name.contains('Roti')) {
      _paintRotiToppings(canvas, center, radius);
    } else if (category.contains('Drink')) {
      _paintDrinkToppings(canvas, center, radius);
    } else if (category.contains('Nasi') || category.contains('Mee')) {
      _paintMainToppings(canvas, center, radius);
    }
  }

  void _paintRotiToppings(Canvas canvas, Offset center, double radius) {
    final rand = math.Random(name.length);

    // 1. Egg yolk topping paste
    if (name.contains('Telur') || name.contains('Jantan') || name.contains('Tampal') || name.contains('John')) {
      final eggPaint = Paint()
        ..color = const Color(0xFFFFB300) // Deep yellow yolk
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - radius * 0.05, center.dy + radius * 0.05), radius * 0.16, eggPaint);
      
      final yolkShine = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - radius * 0.09, center.dy + radius * 0.01), radius * 0.04, yolkShine);
    }

    // 2. Melted cheese slice grid
    if (name.contains('Cheese') || name.contains('Keju')) {
      final cheesePaint = Paint()
        ..color = Colors.amber.withOpacity(0.65)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(Offset(center.dx - radius * 0.35, center.dy - radius * 0.15), Offset(center.dx + radius * 0.35, center.dy + radius * 0.15), cheesePaint);
      canvas.drawLine(Offset(center.dx - radius * 0.15, center.dy - radius * 0.35), Offset(center.dx + radius * 0.15, center.dy + radius * 0.35), cheesePaint);
    }

    // 3. Condensed milk drizzle lines
    if (name.contains('Susu') || name.contains('Tisu') || name.contains('Bom') || name.contains('Boom')) {
      final milkPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(center.dx - radius * 0.4, center.dy);
      path.quadraticBezierTo(center.dx - radius * 0.2, center.dy - radius * 0.2, center.dx, center.dy - radius * 0.05);
      path.quadraticBezierTo(center.dx + radius * 0.2, center.dy + radius * 0.1, center.dx + radius * 0.4, center.dy - radius * 0.15);
      canvas.drawPath(path, milkPaint);
    }

    // 4. Cocoa powder sprinkles
    if (name.contains('Milo')) {
      final miloPaint = Paint()
        ..color = const Color(0xFF4A2B0F)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 24; i++) {
        final double x = center.dx - radius * 0.3 + rand.nextDouble() * radius * 0.6;
        final double y = center.dy - radius * 0.3 + rand.nextDouble() * radius * 0.6;
        canvas.drawCircle(Offset(x, y), 2.2, miloPaint);
      }
    }

    // 5. Banana slices
    if (name.contains('Pisang')) {
      final bananaPaint = Paint()
        ..color = const Color(0xFFFDE910)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = const Color(0xFFD4A24C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (int i = 0; i < 3; i++) {
        final double x = center.dx - radius * 0.2 + (i * radius * 0.2);
        final double y = center.dy + radius * 0.1 - (i * radius * 0.05);
        canvas.drawCircle(Offset(x, y), radius * 0.07, bananaPaint);
        canvas.drawCircle(Offset(x, y), radius * 0.07, borderPaint);
      }
    }
  }

  void _paintDrinkToppings(Canvas canvas, Offset center, double radius) {
    // Modify cup overlays for Milo Dinosaur or speciality drinks
    if (name.contains('Dinosaur') || name.contains('Tarik')) {
      final foamPaint = Paint()
        ..color = const Color(0xFFF5DEB3).withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.05), width: radius * 0.5, height: radius * 0.15), foamPaint);
    }
  }

  void _paintMainToppings(Canvas canvas, Offset center, double radius) {
    final rand = math.Random(name.length);

    // 1. Sunny side fried egg overlay on noodles/rice
    if (name.contains('Pattaya') || name.contains('Telur') || name.contains('Special') || name.contains('John')) {
      final eggWhite = Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx + radius * 0.1, center.dy + radius * 0.1), radius * 0.22, eggWhite);
      
      final eggYolk = Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx + radius * 0.1, center.dy + radius * 0.1), radius * 0.1, eggYolk);
    }

    // 2. Red chili rings
    if (name.contains('Goreng') || name.contains('Mamak') || name.contains('Kampung') || name.contains('Special') || name.contains('Paprik')) {
      final chiliPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      for (int i = 0; i < 4; i++) {
        final double x = center.dx - radius * 0.35 + rand.nextDouble() * radius * 0.7;
        final double y = center.dy - radius * 0.35 + rand.nextDouble() * radius * 0.7;
        canvas.drawCircle(Offset(x, y), 6.5, chiliPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
