import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/cart_provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  String _selectedShipping = 'JNE';
  String _selectedPackage = 'Reguler';
  File? _paymentProof;
  final ImagePicker _picker = ImagePicker();

  final Map<String, Map<String, int>> shippingCosts = {
    'JNE': {'Reguler': 15000, 'YES': 25000, 'OKE': 12000},
    'TIKI': {'Reguler': 14000, 'ONS': 22000, 'Economy': 10000},
    'POS': {'Reguler': 13000, 'Express': 24000, 'Paket Kilat': 18000},
    'J&T': {'Reguler': 12000, 'Express': 23000, 'Cargo': 16000},
  };

  int get totalAmount {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return cartProvider.totalAmount;
  }

  int get shippingCost => shippingCosts[_selectedShipping]![_selectedPackage]!;

  int get grandTotal => totalAmount + shippingCost;

  Future<void> _pickPaymentProof() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _paymentProof = File(image.path);
      });
    }
  }

  Future<String?> _uploadPaymentProof() async {
    if (_paymentProof == null) return null;

    try {
      final fileName = 'payment_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await supabase.storage
          .from('payment-proofs')
          .upload(fileName, _paymentProof!);

      if (response.isNotEmpty) {
        final publicUrl = supabase.storage
            .from('payment-proofs')
            .getPublicUrl(fileName);
        return publicUrl;
      }
    } catch (e) {
      debugPrint('Error uploading payment proof: $e');
    }
    return null;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap upload bukti pembayaran')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload payment proof
      final paymentProofUrl = await _uploadPaymentProof();
      if (paymentProofUrl == null) {
        throw Exception('Failed to upload payment proof');
      }

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Create order
      final orderResponse = await supabase.from('orders').insert({
        'customer_id': user.id,
        'total_amount': grandTotal,
        'shipping_cost': shippingCost,
        'status': 'pending',
        'payment_proof_url': paymentProofUrl,
      }).select().single();

      final orderId = orderResponse['id'];

      // Create order items from cart
      final orderItems = cartProvider.items.map((item) => {
        'order_id': orderId,
        'product_id': item.product['id'],
        'quantity': item.quantity,
        'price': item.price,
        'subtotal': item.subtotal,
      }).toList();

      await supabase.from('order_items').insert(orderItems);

      // Clear the cart after successful order
      cartProvider.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat!')),
        );
        Navigator.of(context).pop(); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Belanja:'),
                        Text('Rp $totalAmount'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ongkir ($_selectedShipping $_selectedPackage):'),
                        Text('Rp $shippingCost'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Bayar:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rp $grandTotal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pilih Pengiriman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedShipping,
                decoration: const InputDecoration(
                  labelText: 'Kurir',
                  border: OutlineInputBorder(),
                ),
                items: shippingCosts.keys.map((courier) {
                  return DropdownMenuItem(
                    value: courier,
                    child: Text(courier),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedShipping = value!;
                    _selectedPackage = shippingCosts[value]!.keys.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPackage,
                decoration: const InputDecoration(
                  labelText: 'Paket',
                  border: OutlineInputBorder(),
                ),
                items: shippingCosts[_selectedShipping]!.keys.map((package) {
                  final cost = shippingCosts[_selectedShipping]![package]!;
                  return DropdownMenuItem(
                    value: package,
                    child: Text('$package - Rp $cost'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPackage = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Alamat Pengiriman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Upload Bukti Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _paymentProof != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _paymentProof!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text('Belum ada gambar dipilih'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickPaymentProof,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pilih Gambar'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Pembayaran:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('BCA: 1234567890 a.n. PT. Toko Online'),
                    Text('Mandiri: 0987654321 a.n. PT. Toko Online'),
                    Text('BNI: 1122334455 a.n. PT. Toko Online'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Bayar Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
