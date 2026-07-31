import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/menu_data.dart';
import '../widgets/premium_food_visual.dart';
import 'detail_page.dart';
import 'qr_scanner_page.dart';
import 'order_confirmed_page.dart';
import '../services/groq_service.dart';
import 'macha_chat_page.dart';
import '../widgets/shopping_bag_sheet.dart';

import '../widgets/container_scroll_animation.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _homeScrollController = ScrollController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final displayedItems = MenuData.items.where((item) {
      if (_selectedCategory == 'All') {
        return true;
      }
      return item['category'] == _selectedCategory;
    }).toList();


    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFD4A24C), size: 20),
            const SizedBox(width: 4),
            Text(
              'Al Safa (Table ${cart.tableNumber})',
              style: const TextStyle(
                color: Color(0xFFD4A24C),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                onPressed: () => _showCartBottomSheet(context),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4A24C),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Color(0xFF121412),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4A24C),
        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF121412)),
        label: const Text(
          'AI WAITER',
          style: TextStyle(
            color: Color(0xFF121412),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MachaChatPage()),
          );
        },
      ),
      body: SingleChildScrollView(
        controller: _homeScrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Main Sensory AR Dining Al Safa Showcase Card
              _buildFeaturedCard(context),
              const SizedBox(height: 20),
              
              // Category Title
              const Text(
                'Explore Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Category Selector (Horizontal Scroll)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'Roti / Flatbreads',
                    'Nasi Goreng / Fried Rice',
                    'Mee / Noodles',
                    'Nasi Dishes',
                    'Lauk / Sides',
                    'Other / Snacks',
                    'Hot Drinks',
                    'Cold Drinks',
                    'Specialty Drinks'
                  ].map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: _buildCategoryChip(cat, cat),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Menu Grid list
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final item = displayedItems[index];
                  return _buildMenuGridCard(context, item);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCategoryChip(String categoryId, String label) {
    final isSelected = _selectedCategory == categoryId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A24C) : const Color(0xFF142A22).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A24C) : const Color(0xFFD4A24C).withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF121412) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF142A22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4A24C).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Ambient Background Image Overlay of Al Safa Restaurant
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Opacity(
              opacity: 0.45,
              child: Image.asset(
                'assets/al_safa_restaurant.png',
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F2A1D)),
              ),
            ),
          ),
          
          // Radial Gold Glow Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  const Color(0xFF0F2A1D).withOpacity(0.4),
                  const Color(0xFF121412).withOpacity(0.85),
                ],
              ),
            ),
          ),

          // Motto Content Container
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A24C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD4A24C)),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'AL SAFA RESTAURANT',
                            style: TextStyle(
                              color: Color(0xFFD4A24C),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Main Welcome Title & Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Selamat Datang!\nWelcome to Al Safa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Serving your favorite Malaysian comfort food, hot teas & crispy rotis, cooked fresh with love every single day.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A24C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.restaurant_menu, color: Color(0xFF121412), size: 18),
                    label: const Text(
                      'EXPLORE OUR MENU',
                      style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGridCard(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(item: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF142A22).withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4A24C).withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: _hasDedicatedImage(item['id'])
                          ? Image.asset(
                              item['imagePath'],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return PremiumFoodVisual(item: item, size: double.infinity);
                              },
                            )
                          : PremiumFoodVisual(item: item, size: double.infinity),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121412).withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, color: Color(0xFFD4A24C), size: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            // Text info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM ${item['price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFD4A24C),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item['calories'],
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    showShoppingBagSheet(context);
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, color: Color(0xFFD4A24C)),
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
            icon: const Icon(Icons.center_focus_weak, color: Colors.white60),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const QrScannerPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white60),
            onPressed: () => _showCartBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white60),
            onPressed: () {},
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

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({Key? key, required this.icon, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A1D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4A24C), size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
