import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/menu_data.dart';
import '../services/groq_service.dart';
import '../screens/order_confirmed_page.dart';

void showShoppingBagSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF142A22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Consumer<CartProvider>(
          builder: (context, cart, child) {
            final cartItems = cart.items.values.toList();
            final cartKeys = cart.items.keys.toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle pill indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Color(0xFFD4A24C)),
                        const SizedBox(width: 8),
                        Text(
                          'Your Shopping Bag (${cart.itemCount})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cart Items List
                if (cartItems.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Your shopping bag is empty.',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 20),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final key = cartKeys[index];

                        return Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                item.imagePath,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white10,
                                  width: 56,
                                  height: 56,
                                  child: const Icon(Icons.fastfood, color: Color(0xFFD4A24C)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.portionSize} - RM ${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                                  ),
                                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.notes!,
                                      style: const TextStyle(
                                        color: Color(0xFFD4A24C),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFD4A24C), size: 22),
                                  onPressed: () => cart.removeItem(key),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4A24C), size: 22),
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
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Smart Combo Suggestion Panel
                  CartComboPanel(cartItems: cartItems),

                  const Divider(color: Colors.white24, height: 24),
                  
                  // Summary & Checkout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'RM ${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFD4A24C),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A24C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
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
                        'CONFIRM ORDER & PAY',
                        style: TextStyle(
                          color: Color(0xFF121412),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    },
  );
}

class CartComboPanel extends StatefulWidget {
  final List<CartItem> cartItems;

  const CartComboPanel({Key? key, required this.cartItems}) : super(key: key);

  @override
  State<CartComboPanel> createState() => _CartComboPanelState();
}

class _CartComboPanelState extends State<CartComboPanel> {
  bool _loading = false;
  Map<String, dynamic>? _recommendation;

  @override
  void initState() {
    super.initState();
    _fetchCombo();
  }

  @override
  void didUpdateWidget(covariant CartComboPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIds = widget.cartItems.map((e) => e.id).toList()..sort();
    final oldIds = oldWidget.cartItems.map((e) => e.id).toList()..sort();

    if (newIds.join(',') != oldIds.join(',')) {
      _fetchCombo();
    }
  }

  Future<void> _fetchCombo() async {
    if (widget.cartItems.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final ids = widget.cartItems.map((e) => e.id).toList();
    final rec = await GroqService.getSmartComboRecommendation(ids);

    if (mounted) {
      setState(() {
        _recommendation = rec;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cartItems.isEmpty || _recommendation == null) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(color: Color(0xFFD4A24C), strokeWidth: 1.5),
          ),
        ),
      );
    }

    final items = _recommendation!['items'] as List?;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    final recItem = items.first;
    final id = recItem['id'];

    final menuMatch = MenuData.items.firstWhere(
      (m) => m['id'] == id,
      orElse: () => <String, dynamic>{},
    );

    if (menuMatch.isEmpty) return const SizedBox.shrink();

    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A1D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              menuMatch['imagePath'],
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.white10, width: 42, height: 42),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFFD4A24C), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'MACHA\'S PAIRING',
                      style: TextStyle(color: Color(0xFFD4A24C), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${menuMatch['name']} (RM ${menuMatch['price'].toStringAsFixed(2)})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A24C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: () {
              cart.addItem(
                id: id,
                name: menuMatch['name'],
                price: menuMatch['price'],
                imagePath: menuMatch['imagePath'],
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${menuMatch['name']} combo to bag!'),
                  backgroundColor: const Color(0xFF0F2A1D),
                ),
              );
            },
            child: const Text(
              'ADD',
              style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
