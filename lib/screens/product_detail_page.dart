import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product['image_url'],
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              product['name'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${product['price']}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product['description'] ?? 'Tidak ada deskripsi',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
