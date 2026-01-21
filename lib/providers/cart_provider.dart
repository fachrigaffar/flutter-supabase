import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addItem(Map<String, dynamic> product, int quantity) {
    final existingIndex = _items.indexWhere((item) => item.product['id'] == product['id']);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        price: product['price'],
      ));
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product['id'] == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product['id'] == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
