class CartItem {
  final Map<String, dynamic> product;
  int quantity;
  final int price;

  CartItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  int get subtotal => quantity * price;
}
