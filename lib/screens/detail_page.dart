import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/premium_food_visual.dart';
import 'ar_simulator_page.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const DetailPage({Key? key, required this.item}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String _selectedPortion = 'Standard';
  bool _isLiked = false;

  // Customization States
  double _sweetnessLevel = 0.5;
  double _iceLevel = 0.5;
  bool _addEgg = false;
  bool _addCheese = false;
  bool _extraMilk = false;
  String _spicyLevel = 'Medium';
  String _gravyStyle = 'Normal';

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final tags = widget.item['tags'] as List<String>;
    final category = widget.item['category'];

    final double basePrice = _selectedPortion == 'Standard' 
        ? widget.item['price'] 
        : widget.item['price'] + 8.0;
    
    double extraCharges = 0.0;
    if (category == 'Roti / Flatbreads') {
      if (_addEgg) extraCharges += 1.50;
      if (_addCheese) extraCharges += 2.00;
      if (_extraMilk) extraCharges += 1.00;
    }
    
    final currentTotalPrice = basePrice + extraCharges;

    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      body: Stack(
        children: [
          // Background food image cover at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Stack(
              children: [
                _hasDedicatedImage(widget.item['id'])
                    ? Image.asset(
                        widget.item['imagePath'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return PremiumFoodVisual(item: widget.item, size: double.infinity);
                        },
                      )
                    : PremiumFoodVisual(item: widget.item, size: double.infinity),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        const Color(0xFF121412),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Top Header
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
                      color: const Color(0xFF121412).withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Column(
                  children: [
                    const Text(
                      'AL SAFA',
                      style: TextStyle(
                        color: Color(0xFFD4A24C),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'EST. 1992',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121412).withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: const Color(0xFFD4A24C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Content (Scrollable)
          Positioned.fill(
            top: 280,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF121412),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle / Category Label
                    Text(
                      category.toString().toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFD4A24C),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dish Title & Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Text(
                          'RM ${currentTotalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFD4A24C),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Ingredient/Warning Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) => _buildTagChip(tag)).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Description Section with vertical bar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 3,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4A24C),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'A Malaysian Heritage Classic',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.item['description'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Portion Size Selection
                    const Text(
                      'SELECT PORTION SIZE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPortionButton('Standard', 'Single serving portion'),
                        const SizedBox(width: 16),
                        _buildPortionButton('Share Platter', 'Ideal for 2-3 pax (+RM 8.00)'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category-Specific Options Form
                    _buildCategoryCustomizer(category),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar Actions
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Row(
              children: [
                // Add to Bag Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Compile customizable order note
                      String note = '';
                      if (category == 'Hot Drinks' || category == 'Cold Drinks' || category == 'Specialty Drinks') {
                        if (category == 'Hot Drinks') {
                          note = 'Sweetness: ${( _sweetnessLevel * 100).round()}%';
                        } else {
                          note = 'Ice: ${( _iceLevel * 100).round()}%, Sweetness: ${( _sweetnessLevel * 100).round()}%';
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
                        price: currentTotalPrice,
                        imagePath: widget.item['imagePath'],
                        portionSize: _selectedPortion,
                        notes: note.isNotEmpty ? note : null,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.item['name']} added to shopping bag!'),
                          backgroundColor: const Color(0xFF0F2A1D),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4A24C),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: Color(0xFFD4A24C), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'ADD TO BAG',
                            style: TextStyle(
                              color: Color(0xFFD4A24C),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // View in AR Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArSimulatorPage(item: {
                            ...widget.item,
                            'basePrice': basePrice,
                            'portionSize': _selectedPortion,
                            'custom_options': {
                              'sweetness': _sweetnessLevel,
                              'ice': _iceLevel,
                              'egg': _addEgg,
                              'cheese': _addCheese,
                              'milk': _extraMilk,
                              'spicy': _spicyLevel,
                              'gravy': _gravyStyle,
                            }
                          }),
                        ),
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3C06B),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF3C06B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.view_in_ar, color: Color(0xFF121412), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'VIEW IN AR',
                            style: TextStyle(
                              color: Color(0xFF121412),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPortionButton(String title, String subtitle) {
    final isSelected = _selectedPortion == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPortion = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF142A22).withOpacity(0.6) 
                : const Color(0xFF121412),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFFD4A24C) 
                  : const Color(0xFFD4A24C).withOpacity(0.15),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFD4A24C) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCustomizer(String category) {
    final isDrink = category == 'Hot Drinks' || category == 'Cold Drinks' || category == 'Specialty Drinks';
    final hasIce = category == 'Cold Drinks' || category == 'Specialty Drinks';

    if (isDrink) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DRINK CUSTOMIZATION',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          if (hasIce) ...[
            Row(
              children: [
                const Icon(Icons.ac_unit, color: Color(0xFFD4A24C), size: 18),
                const SizedBox(width: 10),
                const Text('Ice Level', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: _iceLevel,
                    activeColor: const Color(0xFFD4A24C),
                    inactiveColor: Colors.white10,
                    onChanged: (val) => setState(() => _iceLevel = val),
                  ),
                ),
                Text('${(_iceLevel * 100).round()}%', style: const TextStyle(color: Color(0xFFD4A24C), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(Icons.local_cafe, color: Color(0xFFD4A24C), size: 18),
              const SizedBox(width: 10),
              Text(widget.item['id'] == 'milo_dinosaur' ? 'Milo Powder' : 'Sweetness', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _sweetnessLevel,
                  activeColor: const Color(0xFFD4A24C),
                  inactiveColor: Colors.white10,
                  onChanged: (val) => setState(() => _sweetnessLevel = val),
                ),
              ),
              Text('${(_sweetnessLevel * 100).round()}%', style: const TextStyle(color: Color(0xFFD4A24C), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      );
    } else if (category == 'Roti / Flatbreads') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROTI CUSTOMIZATION',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          _buildAddonCard(
            title: 'Fried Egg (Telur)',
            subtitle: 'Classic sunny-side-up egg cooked inside',
            priceTag: '+RM 1.50',
            imagePath: 'assets/addons/fried_egg.png',
            value: _addEgg,
            onChanged: (val) => setState(() => _addEgg = val ?? false),
          ),
          _buildAddonCard(
            title: 'Melted Cheese (Keju)',
            subtitle: 'Rich mozzarella & cheddar cheese pulls',
            priceTag: '+RM 2.00',
            imagePath: 'assets/addons/melted_cheese.png',
            value: _addCheese,
            onChanged: (val) => setState(() => _addCheese = val ?? false),
          ),
          _buildAddonCard(
            title: 'Extra Condensed Milk (Susu)',
            subtitle: 'Drizzles of sweet, creamy condensed milk',
            priceTag: '+RM 1.00',
            imagePath: 'assets/addons/condensed_milk.png',
            value: _extraMilk,
            onChanged: (val) => setState(() => _extraMilk = val ?? false),
          ),
        ],
      );
    } else if (category == 'Nasi Goreng / Fried Rice' || category == 'Mee / Noodles') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SPICINESS CUSTOMIZATION',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mild', 'Medium', 'Extra Hot'].map((lvl) {
              final isSel = _spicyLevel == lvl;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _spicyLevel = lvl),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFD4A24C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4A24C), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        lvl,
                        style: TextStyle(
                          color: isSel ? const Color(0xFF121412) : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    } else if (category == 'Lauk / Sides') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GRAVY OPTIONS (KUAH)',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Dry', 'Normal', 'Banjir (Curry Flood)'].map((gvy) {
              final isSel = _gravyStyle == gvy;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gravyStyle = gvy),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFD4A24C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4A24C), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        gvy,
                        style: TextStyle(
                          color: isSel ? const Color(0xFF121412) : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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

  Widget _buildAddonCard({
    required String title,
    required String subtitle,
    required String priceTag,
    required String imagePath,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? const Color(0xFFD4A24C) : const Color(0xFFD4A24C).withOpacity(0.1),
          width: value ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.white10,
                        child: const Icon(Icons.broken_image, color: Colors.white30),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceTag,
                        style: const TextStyle(
                          color: Color(0xFFD4A24C),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: value,
                    activeColor: const Color(0xFFD4A24C),
                    checkColor: const Color(0xFF121412),
                    side: const BorderSide(color: Colors.white30, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasDedicatedImage(String id) {
    return true;
  }
}
