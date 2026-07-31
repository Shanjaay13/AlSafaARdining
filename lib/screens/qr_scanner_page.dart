import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'home_page.dart';
import '../providers/cart_provider.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onQrScanned(String rawCode) {
    if (_hasScanned) return;
    setState(() {
      _hasScanned = true;
    });

    // Parse table number from scanned QR string
    String tableNum = '12'; // Default fallback table number
    final String codeLower = rawCode.toLowerCase();

    if (codeLower.contains('table')) {
      final RegExp matchDigits = RegExp(r'\d+');
      final match = matchDigits.firstMatch(codeLower);
      if (match != null) {
        tableNum = match.group(0)!;
      }
    } else if (RegExp(r'^\d+$').hasMatch(rawCode.trim())) {
      tableNum = rawCode.trim();
    } else if (rawCode.trim().isNotEmpty) {
      // Use short hash or sanitized text if string is non-numeric
      tableNum = rawCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      if (tableNum.length > 5) tableNum = tableNum.substring(0, 5);
    }

    // Set Table context in CartProvider
    Provider.of<CartProvider>(context, listen: false).setTable(tableNum, 'Al Safa Perling');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Table #$tableNum Unlocked! Welcome to Al Safa.'),
        backgroundColor: const Color(0xFFD4A24C),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to Home Page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _showManualTableInput() {
    final TextEditingController controller = TextEditingController(text: "12");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF142A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter Table Number', style: TextStyle(color: Color(0xFFD4A24C), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. 05, 12, 18',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4A24C))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A24C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _onQrScanned("Table ${controller.text.trim()}");
              }
            },
            child: const Text('ASSIGN TABLE', style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121412),
        elevation: 0,
        leading: const Icon(Icons.location_on, color: Color(0xFFD4A24C)),
        title: const Text(
          'Al Safa AR Dining',
          style: TextStyle(
            color: Color(0xFFD4A24C),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit, color: Color(0xFFD4A24C), size: 16),
            label: const Text('TABLE', style: TextStyle(color: Color(0xFFD4A24C), fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _showManualTableInput,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Real Camera Viewport
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? rawValue = barcode.rawValue;
                  if (rawValue != null && rawValue.isNotEmpty) {
                    _onQrScanned(rawValue);
                    break;
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off, color: Colors.white38, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Camera Preview Unavailable',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A24C)),
                        onPressed: _showManualTableInput,
                        child: const Text('Enter Table Manually', style: TextStyle(color: Color(0xFF121412))),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 2. Camera Overlay Shade
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // 3. Scan Instructions and Scanner Frame
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Scan Table QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Point your camera at the QR code on your table stand.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                    ),

                    // Golden corner marks
                    ..._buildCornerBorders(),

                    // Pulse scan line
                    if (!_hasScanned)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: 10 + (_animationController.value * 240),
                            child: Container(
                              width: 240,
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

              // Actual Working Real Camera Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Real Flashlight Toggle
                  GestureDetector(
                    onTap: () {
                      _scannerController.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isTorchOn ? const Color(0xFFD4A24C) : const Color(0xFF142A22).withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.4), width: 1.5),
                      ),
                      child: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? const Color(0xFF121412) : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Real Switch Camera Toggle
                  GestureDetector(
                    onTap: () {
                      _scannerController.switchCamera();
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF142A22).withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.4), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Quick Demo Table Assign Button
                  GestureDetector(
                    onTap: () => _onQrScanned("Table 12"),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF142A22).withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.4), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: Color(0xFFD4A24C),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  List<Widget> _buildCornerBorders() {
    const double size = 30;
    const double thickness = 4;
    const Color color = Color(0xFFD4A24C);

    return [
      Positioned(top: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(top: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
    ];
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 64,
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
              const Icon(Icons.qr_code_scanner, color: Color(0xFFD4A24C)),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
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
