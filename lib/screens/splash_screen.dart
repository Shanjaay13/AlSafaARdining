import 'dart:async';
import 'package:flutter/material.dart';
import 'qr_scanner_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _shutterController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  final String _brandName = "AL SAFA";

  @override
  void initState() {
    super.initState();

    _shutterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _shutterController, curve: Curves.easeOutCubic),
    );

    _shutterController.forward();
    _fadeController.forward();

    // Auto navigate after 3.2 seconds
    _timer = Timer(const Duration(milliseconds: 3200), _navigateToQrScanner);
  }

  void _navigateToQrScanner() {
    if (!mounted) return;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => const QrScannerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shutterController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characters = _brandName.split('');

    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      body: GestureDetector(
        onTap: _navigateToQrScanner,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Radial Glow
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      const Color(0xFF0F2A1D).withOpacity(0.6),
                      const Color(0xFF121412),
                    ],
                  ),
                ),
              ),
            ),

            // Subtle Background Crest / Ornament
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4A24C), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 140, color: Color(0xFFD4A24C)),
                  ),
                ),
              ),
            ),

            // Content Column
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Top Decorative Line
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 30, height: 1, color: const Color(0xFFD4A24C).withOpacity(0.5)),
                        const SizedBox(width: 10),
                        const Text(
                          "EST. 1992",
                          style: TextStyle(
                            color: Color(0xFFD4A24C),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 30, height: 1, color: const Color(0xFFD4A24C).withOpacity(0.5)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Shutter Text Effect Component
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(characters.length, (index) {
                      final char = characters[index];
                      if (char == ' ') {
                        return const SizedBox(width: 16);
                      }
                      return _ShutterLetter(
                        character: char,
                        index: index,
                        totalLength: characters.length,
                        controller: _shutterController,
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle Label
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      "AUGMENTED REALITY DINING",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Tap to skip prompt
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "TAP ANYWHERE TO ENTER",
                            style: TextStyle(
                              color: Color(0xFFD4A24C),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFD4A24C)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliced Shutter Letter Component recreating Framer Motion top/middle/bottom shutter slice glitch effects
class _ShutterLetter extends StatelessWidget {
  final String character;
  final int index;
  final int totalLength;
  final AnimationController controller;

  const _ShutterLetter({
    Key? key,
    required this.character,
    required this.index,
    required this.totalLength,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double delay = (index * 0.08).clamp(0.0, 0.6);

    // Staggered slice animations
    final topSlice = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay, (delay + 0.35).clamp(0.0, 1.0), curve: Curves.easeInOut),
      ),
    );

    final midSlice = Tween<double>(begin: 1.0, end: -1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay + 0.08, (delay + 0.43).clamp(0.0, 1.0), curve: Curves.easeInOut),
      ),
    );

    final botSlice = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay + 0.16, (delay + 0.51).clamp(0.0, 1.0), curve: Curves.easeInOut),
      ),
    );

    final mainOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay + 0.2, (delay + 0.6).clamp(0.0, 1.0), curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main Character Text (Gold & White Glow)
              Opacity(
                opacity: mainOpacity.value,
                child: Text(
                  character,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    shadows: [
                      Shadow(color: Color(0xFFD4A24C), blurRadius: 16),
                    ],
                  ),
                ),
              ),

              // Top Slice Layer (Emerald / Gold shimmer)
              if (topSlice.value > -0.99 && topSlice.value < 0.99)
                Transform.translate(
                  offset: Offset(topSlice.value * 35, 0),
                  child: ClipRect(
                    clipper: _SliceClipper(top: 0.0, bottom: 0.35),
                    child: Text(
                      character,
                      style: const TextStyle(
                        color: Color(0xFFD4A24C),
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ),

              // Middle Slice Layer (Dark Shimmer)
              if (midSlice.value > -0.99 && midSlice.value < 0.99)
                Transform.translate(
                  offset: Offset(midSlice.value * 35, 0),
                  child: ClipRect(
                    clipper: _SliceClipper(top: 0.35, bottom: 0.65),
                    child: Text(
                      character,
                      style: const TextStyle(
                        color: Color(0xFF0F2A1D),
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ),

              // Bottom Slice Layer (Gold shimmer)
              if (botSlice.value > -0.99 && botSlice.value < 0.99)
                Transform.translate(
                  offset: Offset(botSlice.value * 35, 0),
                  child: ClipRect(
                    clipper: _SliceClipper(top: 0.65, bottom: 1.0),
                    child: Text(
                      character,
                      style: const TextStyle(
                        color: Color(0xFFD4A24C),
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SliceClipper extends CustomClipper<Rect> {
  final double top;
  final double bottom;

  _SliceClipper({required this.top, required this.bottom});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, size.height * top, size.width, size.height * bottom);
  }

  @override
  bool shouldReclip(covariant _SliceClipper oldClipper) {
    return oldClipper.top != top || oldClipper.bottom != bottom;
  }
}
