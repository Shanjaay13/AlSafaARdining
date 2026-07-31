import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/menu_data.dart';
import '../widgets/premium_food_visual.dart';
import 'detail_page.dart';
import 'qr_scanner_page.dart';
import 'order_confirmed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'All';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Premium Showcase Card (resembling screen copy 15.png)
              _buildFeaturedCard(context),
              const SizedBox(height: 24),
              
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
    return GestureDetector(
      onTap: () {
        // Direct link to Satay item
        final satayItem = MenuData.items.firstWhere((element) => element['id'] == 'satay');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(item: satayItem),
          ),
        );
      },
      child: Container(
        height: 420,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4A24C).withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Image Cover Background
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/satay.png',
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // Top Bar of the card
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  const Icon(Icons.local_dining, color: Color(0xFFD4A24C), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Al Safa Special',
                    style: TextStyle(
                      color: const Color(0xFFD4A24C).withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Glassmorphic details like screen copy 15.png
            // Price tag floating
            Positioned(
              left: 20,
              top: 140,
              child: _buildGlassTag('RM 28.90'),
            ),

            // Calories tag floating
            Positioned(
              right: 20,
              top: 240,
              child: _buildGlassTag('550 Kcal'),
            ),

            // Title Ribbon and Order Button at bottom
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  // Green & Gold Ribbon for item name
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2A1D).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4A24C).withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F2A1D).withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Text(
                      'Premium Satay',
                      style: TextStyle(
                        color: Color(0xFFD4A24C),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // "Order Now" button
                  Container(
                    width: 140,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4A24C), width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Order Now',
                        style: TextStyle(
                          color: Color(0xFFD4A24C),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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

  Widget _buildGlassTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF142A22).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4A24C).withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD4A24C),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF142A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<CartProvider>(
          builder: (context, cart, child) {
            final cartItems = cart.items.values.toList();
            final cartKeys = cart.items.keys.toList();
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Shopping Bag',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (cartItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Your bag is empty.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else ...[
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final key = cartKeys[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    item.imagePath,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${item.portionSize} - RM ${item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.notes!,
                                          style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 10, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFD4A24C)),
                                      onPressed: () => cart.removeItem(key),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4A24C)),
                                      onPressed: () => cart.addItem(
                                        id: item.id,
                                        name: item.name,
                                        price: item.price,
                                        imagePath: item.imagePath,
                                        portionSize: item.portionSize,
                                        notes: item.notes,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RM ${cart.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFD4A24C),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A24C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Clear cart and checkout
                          cart.clearCart();
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrderConfirmedPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Place Order (Table 12)',
                          style: TextStyle(
                            color: Color(0xFF121412),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            );
          },
        );
      },
    );
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
