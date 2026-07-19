import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../providers/cart_provider.dart';
import '../widgets/premium_food_visual.dart';
import 'order_confirmed_page.dart';

class ArSimulatorPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ArSimulatorPage({Key? key, required this.item}) : super(key: key);

  @override
  State<ArSimulatorPage> createState() => _ArSimulatorPageState();
}

class _ArSimulatorPageState extends State<ArSimulatorPage> {
  // Common states
  double _scale = 1.0;
  double _rotationAngle = 0.0;
  bool _showIngredients = false;
  bool _is3dMode = true;

  // Customization States (preloaded from detail page)
  double _iceLevel = 0.5;
  double _sweetness = 0.5;
  bool _addEgg = false;
  bool _addCheese = false;
  bool _extraMilk = false;
  String _spicyLevel = 'Medium';
  String _gravyStyle = 'Normal';
  String _activeCallout = '';

  // Camera States
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isLiveCamera = false;
  bool _isCameraLoading = false;

  String _getModelPath(String itemId, String category) {
    if (category.contains('Drink')) {
      return 'https://github.com/KhronosGroup/glTF-Sample-Assets/raw/main/Models/Teacup/glTF-Binary/Teacup.glb';
    } else if (itemId.contains('avocado')) {
      return 'https://github.com/KhronosGroup/glTF-Sample-Assets/raw/main/Models/Avocado/glTF-Binary/Avocado.glb';
    } else {
      return 'assets/food_base.glb';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.item['custom_options'] != null) {
      final opts = widget.item['custom_options'] as Map<String, dynamic>;
      _iceLevel = opts['ice'] ?? 0.5;
      _sweetness = opts['sweetness'] ?? 0.5;
      _addEgg = opts['egg'] ?? false;
      _addCheese = opts['cheese'] ?? false;
      _extraMilk = opts['milk'] ?? false;
      _spicyLevel = opts['spicy'] ?? 'Medium';
      _gravyStyle = opts['gravy'] ?? 'Normal';
    }
  }

  Future<void> _toggleCamera() async {
    if (_isLiveCamera) {
      setState(() {
        _isLiveCamera = false;
      });
      return;
    }

    if (_isCameraInitialized) {
      setState(() {
        _isLiveCamera = true;
      });
      return;
    }

    setState(() {
      _isCameraLoading = true;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showCameraError('No cameras found on this device.');
        return;
      }

      CameraDescription? targetCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          targetCamera = camera;
          break;
        }
      }
      targetCamera ??= cameras.first;

      _cameraController = CameraController(
        targetCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLiveCamera = true;
          _isCameraLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraLoading = false;
        });
      }
      _showCameraError('Could not access camera: $e');
    }
  }

  void _showCameraError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final itemId = widget.item['id'];
    final category = widget.item['category'];

    final isDrink = category == 'Hot Drinks' || category == 'Cold Drinks' || category == 'Specialty Drinks';
    final isRoti = category == 'Roti / Flatbreads';
    final isNoodleRice = category == 'Nasi Goreng / Fried Rice' || category == 'Mee / Noodles';
    final isLauk = category == 'Lauk / Sides';

    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      body: Stack(
        children: [
          // 1. Simulated / Live Camera View (Background)
          Positioned.fill(
            child: _isLiveCamera && _isCameraInitialized && _cameraController != null
                ? Container(
                    color: Colors.black,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize?.height ?? 1080,
                        height: _cameraController!.value.previewSize?.width ?? 1920,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/restaurant_bg.png',
                    fit: BoxFit.cover,
                  ),
          ),
          
          // Camera Loading Indicator Overlay
          if (_isCameraLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A24C)),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Initializing camera...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Flashing LIVE AR camera tracking indicator
          if (_isLiveCamera && _isCameraInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE CAMERA AR',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Subtle camera grid/scanlines overlay to enhance AR realism
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_isLiveCamera ? 0.15 : 0.35),
              ),
              child: CustomPaint(
                painter: ArScanOverlayPainter(),
              ),
            ),
          ),

          // 2. Interactive Food Model (Centered in the viewport)
          Center(
            child: _is3dMode
                ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.65,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ModelViewer(
                      src: _getModelPath(itemId, category),
                      alt: widget.item['name'],
                      ar: true,
                      arModes: const ['webxr', 'scene-viewer', 'quick-look'],
                      autoRotate: true,
                      cameraControls: true,
                      disableZoom: false,
                    ),
                  )
                : GestureDetector(
                    onScaleUpdate: (details) {
                      setState(() {
                        _scale = details.scale.clamp(0.6, 1.8);
                        _rotationAngle = details.rotation;
                      });
                    },
                    child: Transform.rotate(
                      angle: _rotationAngle,
                      child: Transform.scale(
                        scale: _scale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Food Image with interactive styling based on custom sliders
                            _buildFoodVisual(itemId, category),

                            // Interactive Callout Pins (only for Nasi Lemak AR)
                            if (itemId == 'nasi_lemak_biasa' || itemId == 'nasi_lemak') ..._buildNasiLemakCallouts(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          // 3. Floating Sidebar Panel (Nutrition/Ingredients for solid items)
          if (!isDrink && !_is3dMode) _buildNutritionSidebar(itemId),

          // 4. Custom Drink / Food Customizer Sliders
          if (!_is3dMode) _buildCustomizerDock(category),

          // 5. Nasi Lemak Callout Overlay Details
          if (!_is3dMode && (itemId == 'nasi_lemak_biasa' || itemId == 'nasi_lemak') && _activeCallout.isNotEmpty)
            _buildCalloutDetailOverlay(),

          // 6. Header Overlays
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121412).withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A1D).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_is3dMode ? Icons.threed_rotation : Icons.view_in_ar, color: const Color(0xFFD4A24C), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _is3dMode ? '${widget.item['name']} 3D' : '${widget.item['name']} AR',
                        style: const TextStyle(
                          color: Color(0xFFD4A24C),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode Toggle Button (3D vs 2D)
                    IconButton(
                      icon: Icon(
                        _is3dMode ? Icons.tune : Icons.threed_rotation,
                        color: Colors.white,
                      ),
                      tooltip: _is3dMode ? 'Switch to 2D Customizer' : 'Switch to 3D Viewer',
                      onPressed: () {
                        setState(() {
                          _is3dMode = !_is3dMode;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isLiveCamera ? Icons.videocam : Icons.videocam_off,
                        color: _isLiveCamera ? const Color(0xFFD4A24C) : Colors.white,
                      ),
                      tooltip: _isLiveCamera ? 'Switch to Simulated View' : 'Switch to Live AR Camera',
                      onPressed: _toggleCamera,
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pinch to scale, drag to position or rotate in AR.'),
                            backgroundColor: Color(0xFF142A22),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 7. Zoom Slider (for 3D models)
          if (!isDrink)
            Positioned(
              bottom: 180,
              left: 30,
              right: 30,
              child: _buildZoomSlider(),
            ),

          // 8. Bottom Action Dock
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _buildBottomActionDock(context, cart, isDrink, category),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodVisual(String itemId, String category) {
    Widget baseImage = _hasDedicatedImage(itemId)
        ? Image.asset(
            widget.item['imagePath'],
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return PremiumFoodVisual(item: widget.item, size: 300);
            },
          )
        : PremiumFoodVisual(item: widget.item, size: 300);

    // Apply real-time overlays based on category/customization
    if (category == 'Roti / Flatbreads') {
      return Stack(
        alignment: Alignment.center,
        children: [
          baseImage,
          // Egg Overlay
          if (_addEgg)
            Positioned(
              top: 100,
              child: Container(
                width: 70,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          // Cheese Overlay
          if (_addCheese)
            Positioned.fill(
              child: Opacity(
                opacity: 0.75,
                child: CustomPaint(
                  painter: CheeseOverlayPainter(),
                ),
              ),
            ),
          // Condensed Milk Overlay
          if (_extraMilk)
            Positioned.fill(
              child: Opacity(
                opacity: 0.85,
                child: CustomPaint(
                  painter: CondensedMilkOverlayPainter(),
                ),
              ),
            ),
        ],
      );
    } else if (category == 'Nasi Goreng / Fried Rice' || category == 'Mee / Noodles') {
      return Stack(
        alignment: Alignment.center,
        children: [
          baseImage,
          // Chili Rings Overlay based on spiciness
          if (_spicyLevel == 'Medium') ..._buildChiliRings(3),
          if (_spicyLevel == 'Extra Hot') ...[
            ..._buildChiliRings(7),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ]
        ],
      );
    } else if (category == 'Lauk / Sides') {
      return Stack(
        alignment: Alignment.center,
        children: [
          baseImage,
          // Curry Flood overlay
          if (_gravyStyle == 'Normal')
            Positioned(
              bottom: 40,
              child: Container(
                width: 140,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFC6641A).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
          if (_gravyStyle == 'Banjir (Curry Flood)')
            Positioned(
              bottom: 30,
              child: Container(
                width: 190,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFC6641A).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(95),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF904000).withOpacity(0.4), blurRadius: 10),
                  ],
                ),
              ),
            ),
        ],
      );
    } else if (itemId == 'teh_tarik') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/teh_tarik.png',
            width: 280,
            height: 380,
            fit: BoxFit.contain,
          ),
          Positioned(
            bottom: 60,
            child: Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity((1.0 - _sweetness) * 0.15),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
            ),
          ),
          _buildIceOverlay(),
        ],
      );
    } else if (itemId == 'milo_dinosaur') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/milo_dinosaur.png',
            width: 280,
            height: 340,
            fit: BoxFit.contain,
          ),
          Positioned(
            top: 60,
            child: Opacity(
              opacity: _sweetness.clamp(0.1, 1.0),
              child: Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E2C0E).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          _buildIceOverlay(),
        ],
      );
    } else if (itemId == 'sirap_bandung') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/sirap_bandung.png',
            width: 280,
            height: 340,
            fit: BoxFit.contain,
          ),
          Positioned(
            bottom: 50,
            child: Container(
              width: 130,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(_sweetness * 0.12),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
            ),
          ),
          _buildIceOverlay(),
        ],
      );
    }

    return baseImage;
  }

  Widget _buildIceOverlay() {
    if (_iceLevel <= 0.2) return const SizedBox.shrink();
    return Positioned(
      top: 130,
      child: Opacity(
        opacity: _iceLevel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            (_iceLevel * 5).round().clamp(1, 4),
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChiliRings(int count) {
    final random = math.Random(42); // Seeded random for consistent visual positioning
    return List.generate(count, (index) {
      final double top = 90.0 + random.nextDouble() * 110.0;
      final double left = 80.0 + random.nextDouble() * 120.0;
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 3.5),
          ),
        ),
      );
    });
  }

  List<Widget> _buildNasiLemakCallouts() {
    return [
      _buildPin(top: 120, left: 150, id: 'rice', label: 'Fragrant Coconut Rice'),
      _buildPin(top: 210, left: 200, id: 'sambal', label: 'House-made Sambal'),
      _buildPin(top: 220, left: 90, id: 'anchovies', label: 'Crispy Ikan Bilis'),
      _buildPin(top: 130, left: 220, id: 'chicken', label: 'Spiced Fried Chicken'),
    ];
  }

  Widget _buildPin({required double top, required double left, required String id, required String label}) {
    final isActive = _activeCallout == id;
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeCallout = isActive ? '' : id;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFD4A24C) : const Color(0xFF142A22).withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4A24C), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A24C).withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(
            Icons.location_searching,
            color: isActive ? const Color(0xFF121412) : const Color(0xFFD4A24C),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCalloutDetailOverlay() {
    String detailText = '';
    switch (_activeCallout) {
      case 'rice':
        detailText = 'Basmati rice infused with fresh coconut milk, pandan leaves, lemongrass, and ginger. Steamed traditional style.';
        break;
      case 'sambal':
        detailText = 'Our signature sweet & spicy sambal, slow-cooked for 6 hours with caramelized onions and premium dried chilies.';
        break;
      case 'anchovies':
        detailText = 'Perfectly fried crispy anchovies and split peanuts tossed in a pinch of sea salt.';
        break;
      case 'chicken':
        detailText = 'Fresh chicken marinated in a secret recipe of 12 Indian-Muslim spices, deep-fried to crispy golden excellence.';
        break;
    }

    return Positioned(
      bottom: 120,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF142A22).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.4)),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Color(0xFFD4A24C), size: 18),
                const SizedBox(width: 8),
                Text(
                  _activeCallout.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD4A24C),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              detailText,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizerDock(String category) {
    final isDrink = category == 'Hot Drinks' || category == 'Cold Drinks' || category == 'Specialty Drinks';
    final isRoti = category == 'Roti / Flatbreads';
    final isNoodleRice = category == 'Nasi Goreng / Fried Rice' || category == 'Mee / Noodles';
    final isLauk = category == 'Lauk / Sides';

    return Positioned(
      left: 24,
      right: 24,
      bottom: 110,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2A1D).withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            if (isDrink) ...[
              // Ice Slider (if not purely hot drink)
              if (category != 'Hot Drinks') ...[
                Row(
                  children: [
                    const Icon(Icons.ac_unit, color: Color(0xFFD4A24C), size: 18),
                    const SizedBox(width: 12),
                    const Text('ICE LEVEL', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _iceLevel,
                        activeColor: const Color(0xFFD4A24C),
                        inactiveColor: Colors.white12,
                        onChanged: (val) => setState(() => _iceLevel = val),
                      ),
                    ),
                    Text('${(_iceLevel * 100).round()}%', style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Sweetness / Powder Slider
              Row(
                children: [
                  Icon(widget.item['id'] == 'milo_dinosaur' ? Icons.grain : Icons.local_cafe, color: const Color(0xFFD4A24C), size: 18),
                  const SizedBox(width: 12),
                  Text(widget.item['id'] == 'milo_dinosaur' ? 'MILO POWDER' : 'SWEETNESS', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: _sweetness,
                      activeColor: const Color(0xFFD4A24C),
                      inactiveColor: Colors.white12,
                      onChanged: (val) => setState(() => _sweetness = val),
                    ),
                  ),
                  Text('${(_sweetness * 100).round()}%', style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ] else if (isRoti) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniToggle('EGG', _addEgg, (val) => setState(() => _addEgg = val)),
                  _buildMiniToggle('CHEESE', _addCheese, (val) => setState(() => _addCheese = val)),
                  _buildMiniToggle('MILK', _extraMilk, (val) => setState(() => _extraMilk = val)),
                ],
              ),
            ] else if (isNoodleRice) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SPICY LEVEL:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  Row(
                    children: ['Mild', 'Medium', 'Extra Hot'].map((lvl) {
                      final isSel = _spicyLevel == lvl;
                      return GestureDetector(
                        onTap: () => setState(() => _spicyLevel = lvl),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFD4A24C) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD4A24C)),
                          ),
                          child: Text(
                            lvl,
                            style: TextStyle(
                              color: isSel ? const Color(0xFF121412) : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ] else if (isLauk) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GRAVY (KUAH):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  Row(
                    children: ['Dry', 'Normal', 'Banjir'].map((gvy) {
                      final isSel = _gravyStyle == (gvy == 'Banjir' ? 'Banjir (Curry Flood)' : gvy);
                      return GestureDetector(
                        onTap: () => setState(() => _gravyStyle = gvy == 'Banjir' ? 'Banjir (Curry Flood)' : gvy),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFD4A24C) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD4A24C)),
                          ),
                          child: Text(
                            gvy,
                            style: TextStyle(
                              color: isSel ? const Color(0xFF121412) : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMiniToggle(String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFD4A24C) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4A24C)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: value ? const Color(0xFF121412) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionSidebar(String itemId) {
    String nutritionText = '550 kcal\n28g Protein\n62g Carbs';
    String ingredientsText = '• Wheat Flour\n• Curry Spices\n• Dhal Lentils\n• Salt & Oil';

    // Roti custom descriptions
    if (itemId.contains('roti')) {
      if (itemId == 'roti_tisu') {
        nutritionText = '480 kcal\n6g Protein\n78g Carbs';
        ingredientsText = '• Flour\n• Margarine\n• Condensed Milk\n• Sugar';
      }
    } else if (itemId.contains('goreng') || itemId.contains('mee')) {
      nutritionText = '610 kcal\n15g Protein\n82g Carbs';
      ingredientsText = '• Yellow Noodles\n• Tofu Fritters\n• Bean Sprouts\n• Eggs\n• Sweet Soy Sauce';
    } else if (itemId.contains('kandar')) {
      nutritionText = '920 kcal\n42g Protein\n110g Carbs';
      ingredientsText = '• Steamed Rice\n• Spiced Chicken\n• Okra\n• Salted Egg\n• Mixed Gravy (Banjir)';
    }

    return Positioned(
      top: 120,
      right: 16,
      width: 110,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2A1D).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NUTRITION',
              style: TextStyle(
                color: Color(0xFFD4A24C),
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nutritionText,
              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
            ),
            const Divider(color: Colors.white24, height: 16),
            const Text(
              'INGREDIENTS',
              style: TextStyle(
                color: Color(0xFFD4A24C),
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showIngredients = !_showIngredients;
                });
              },
              child: Row(
                children: [
                  Text(
                    _showIngredients ? 'Hide List' : 'Show List',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    _showIngredients ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
            if (_showIngredients) ...[
              const SizedBox(height: 6),
              Text(
                ingredientsText,
                style: const TextStyle(color: Colors.white54, fontSize: 9, height: 1.4),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildZoomSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF142A22).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Text('Zoom', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Slider(
              value: _scale.clamp(0.6, 1.8),
              min: 0.6,
              max: 1.8,
              activeColor: const Color(0xFFD4A24C),
              inactiveColor: Colors.white12,
              onChanged: (val) {
                setState(() {
                  _scale = val.clamp(0.6, 1.8);
                });
              },
            ),
          ),
          // 3D Rotate Button
          GestureDetector(
            onTap: () {
              setState(() {
                _rotationAngle += math.pi / 4;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFD4A24C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rotate_right, color: Color(0xFF121412), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionDock(BuildContext context, CartProvider cart, bool isDrink, String category) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _rotationAngle = 0.0;
                  _scale = 1.0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AR Object Recalibrated!')),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF142A22).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.2)),
                ),
                child: const Center(
                  child: Text(
                    'RECENTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Add to order button
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Compile custom note
                String? note;
                if (isDrink) {
                  if (widget.item['id'] == 'milo_dinosaur') {
                    note = 'Ice: ${(_iceLevel * 100).round()}%, Milo Powder: ${(_sweetness * 100).round()}%';
                  } else {
                    note = 'Ice: ${(_iceLevel * 100).round()}%, Sweetness: ${(_sweetness * 100).round()}%';
                  }
                } else if (category == 'Roti / Flatbreads') {
                  List<String> options = [];
                  if (_addEgg) options.add('Add Egg');
                  if (_addCheese) options.add('Add Cheese');
                  if (_extraMilk) options.add('Extra Milk');
                  note = options.isEmpty ? 'No extra toppings' : options.join(', ');
                } else if (category == 'Nasi Goreng / Fried Rice' || category == 'Mee / Noodles') {
                  note = 'Spiciness: $_spicyLevel';
                } else if (category == 'Lauk / Sides') {
                  note = 'Gravy Style: $_gravyStyle';
                }

                cart.addItem(
                  id: widget.item['id'],
                  name: widget.item['name'],
                  price: widget.item['price'],
                  imagePath: widget.item['imagePath'],
                  portionSize: 'Standard',
                  notes: note,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.item['name']} added to order!'),
                    backgroundColor: const Color(0xFFD4A24C),
                    action: SnackBarAction(
                      label: 'CHECKOUT',
                      textColor: const Color(0xFF121412),
                      onPressed: () {
                        cart.clearCart();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const OrderConfirmedPage()),
                        );
                      },
                    ),
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A24C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A24C).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_shopping_cart, color: Color(0xFF121412), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'ADD TO ORDER',
                      style: TextStyle(
                        color: Color(0xFF121412),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Roti / Flatbreads':
        return Icons.flatware;
      case 'Nasi Goreng / Fried Rice':
      case 'Nasi Dishes':
        return Icons.rice_bowl;
      case 'Mee / Noodles':
        return Icons.restaurant;
      case 'Lauk / Sides':
        return Icons.kebab_dining_outlined;
      case 'Other / Snacks':
        return Icons.cookie;
      case 'Hot Drinks':
        return Icons.coffee;
      case 'Cold Drinks':
      case 'Specialty Drinks':
        return Icons.local_drink;
      default:
        return Icons.local_dining;
    }
  }

  bool _hasDedicatedImage(String id) {
    return true;
  }
}

// Painters for programmatic overlays
class CheeseOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    // Draw diagonal cheese slice strips across the center
    canvas.drawLine(Offset(center.dx - 40, center.dy - 30), Offset(center.dx + 40, center.dy + 30), paint);
    canvas.drawLine(Offset(center.dx - 10, center.dy - 40), Offset(center.dx + 50, center.dy + 20), paint);
    canvas.drawLine(Offset(center.dx - 50, center.dy - 20), Offset(center.dx + 10, center.dy + 40), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CondensedMilkOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    // Draw white condensed milk loops
    path.moveTo(center.dx - 50, center.dy - 10);
    path.quadraticBezierTo(center.dx - 20, center.dy - 60, center.dx + 10, center.dy - 20);
    path.quadraticBezierTo(center.dx + 40, center.dy + 20, center.dx - 10, center.dy + 40);
    path.quadraticBezierTo(center.dx - 60, center.dy - 10, center.dx + 30, center.dy + 10);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ArScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A24C).withOpacity(0.06)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final markerPaint = Paint()
      ..color = const Color(0xFFD4A24C).withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.85,
      height: size.width * 0.85,
    );

    canvas.drawRect(rect, markerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
