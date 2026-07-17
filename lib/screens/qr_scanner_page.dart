import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import '../providers/cart_provider.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Simulate automatic successful scan after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _simulateScanSuccess();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _simulateScanSuccess() {
    setState(() {
      _isScanning = false;
    });
    
    // Set table context (Mamak Table 12, Al Safa Perling)
    Provider.of<CartProvider>(context, listen: false).setTable('12', 'Al Safa Perling');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Table #12 Unlocked! Welcome to Al Safa.'),
        backgroundColor: Color(0xFFD4A24C),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to Home Page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.location_on, color: Color(0xFFD4A24C)),
        title: const Text(
          'Al Safa',
          style: TextStyle(
            color: Color(0xFFD4A24C),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Simulated Camera Background showing the table stand
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/qr_stand.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Camera Blur Backdrop and instruction overlays
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // Main scan instructions and framing
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Scan to view AR Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Position the QR code within the frame to unlock the sensory experience.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const Spacer(),

              // Scanner framing box
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer square container representing scanner boundary
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                    ),
                    
                    // Golden corner marks
                    ..._buildCornerBorders(),

                    // Pulse scan line
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: 10 + (_animationController.value * 260),
                            child: Container(
                              width: 260,
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4A24C),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4A24C).withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Circular Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleButton(Icons.flashlight_on),
                  const SizedBox(width: 24),
                  _buildCircleButton(Icons.history),
                  const SizedBox(width: 24),
                  _buildCircleButton(Icons.help_outline),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCircleButton(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF142A22).withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () {
          if (icon == Icons.flashlight_on) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Flashlight Toggled (Simulation)')),
            );
          } else {
            _simulateScanSuccess();
          }
        },
      ),
    );
  }

  List<Widget> _buildCornerBorders() {
    const double size = 30;
    const double thickness = 4;
    const Color color = Color(0xFFD4A24C);

    return [
      // Top Left Corner
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),

      // Top Right Corner
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),

      // Bottom Left Corner
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),

      // Bottom Right Corner
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
    ];
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF121412),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4A24C).withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white60),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, color: Color(0xFFD4A24C)),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A24C),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white60),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white60),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
