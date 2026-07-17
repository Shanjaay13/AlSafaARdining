import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imagePath;
  int quantity;
  String? notes;
  String portionSize;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    this.quantity = 1,
    this.notes,
    this.portionSize = 'Standard',
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String _tableNumber = '12';
  String _location = 'Al Safa Perling';

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  String get tableNumber => _tableNumber;
  String get location => _location;

  void setTable(String table, String loc) {
    _tableNumber = table;
    _location = loc;
    notifyListeners();
  }

  void addItem({
    required String id,
    required String name,
    required double price,
    required String imagePath,
    String portionSize = 'Standard',
    String? notes,
  }) {
    final itemKey = '${id}_$portionSize';
    if (_items.containsKey(itemKey)) {
      _items[itemKey]!.quantity++;
    } else {
      _items[itemKey] = CartItem(
        id: id,
        name: name,
        price: price,
        imagePath: imagePath,
        portionSize: portionSize,
        notes: notes,
      );
    }
    notifyListeners();
  }

  void removeItem(String key) {
    if (!_items.containsKey(key)) return;
    if (_items[key]!.quantity > 1) {
      _items[key]!.quantity--;
    } else {
      _items.remove(key);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
