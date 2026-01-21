import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'product_detail_page.dart';
import 'call_center_page.dart';
import 'sms_center_page.dart';
import 'location_page.dart';
import 'update_profile_page.dart';
import 'payment_page.dart';
import 'order_history_page.dart';
import '../providers/cart_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;
  late Future<List<dynamic>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      debugPrint('Products response: $response');
      return response as List<dynamic>;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      rethrow;
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Center'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CallCenterPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.blue),
                title: const Text('SMS Center'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SmsCenterPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.red),
                title: const Text('Lokasi/Maps'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.purple),
                title: const Text('Riwayat Belanja'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.orange),
                title: const Text('Update User & Password'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdateProfilePage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToCart(BuildContext context, Map<String, dynamic> product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(product, 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ditambahkan ke keranjang'),
        action: SnackBarAction(
          label: 'Lihat Keranjang',
          onPressed: () => _showCart(context),
        ),
      ),
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Keranjang Belanja',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: cartProvider.items.isEmpty
                        ? const Center(child: Text('Keranjang kosong'))
                        : ListView.builder(
                            itemCount: cartProvider.items.length,
                            itemBuilder: (context, index) {
                              final item = cartProvider.items[index];
                              return Card(
                                child: ListTile(
                                  title: Text(item.product['name']),
                                  subtitle: Text('Rp ${item.subtotal}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          cartProvider.updateQuantity(
                                            item.product['id'],
                                            item.quantity - 1,
                                          );
                                        },
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          cartProvider.updateQuantity(
                                            item.product['id'],
                                            item.quantity + 1,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          cartProvider.removeItem(item.product['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (cartProvider.items.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rp ${cartProvider.totalAmount}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showPaymentForm(context),
                        child: const Text('Bayar Sekarang'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentForm(BuildContext context) {
    // Navigate to payment form
    Navigator.pop(context); // Close cart
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => _showCart(context),
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenu(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text('Belum ada produk'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _addToCart(context, product),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              product['image_url'] != null
                                  ? Image.network(
                                      product['image_url'],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image,
                                        size: 60,
                                      ),
                                    ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Tap to Buy',
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(product: product),
                                ),
                              );
                            },
                            child: Text(
                              product['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${product['price']}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
