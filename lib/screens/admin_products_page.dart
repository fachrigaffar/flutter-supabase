import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final supabase = Supabase.instance.client;
  late Future<List<dynamic>> productsFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    final response = await supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return response as List<dynamic>;
  }

  Future<void> _refreshProducts() async {
    setState(() {
      productsFuture = fetchProducts();
    });
  }

  void _showProductDialog([Map<String, dynamic>? product]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductDialog(
          product: product,
          onSave: _refreshProducts,
        );
      },
    );
  }

  Future<void> _deleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await supabase.from('products').delete().eq('id', productId);
        _refreshProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada produk',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: product['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product['image_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, size: 30),
                        ),
                  title: Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rp ${product['price']}'),
                      Text('Stok: ${product['stock']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductDialog(product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSave;

  const ProductDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _stockController.text = widget.product!['stock']?.toString() ?? '';
      _imageUrlController.text = widget.product!['image_url'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrlController.text;

    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await supabase.storage
          .from('products')
          .upload(fileName, _selectedImage!);

      if (response.isNotEmpty) {
        final publicUrl = supabase.storage
            .from('products')
            .getPublicUrl(fileName);
        return publicUrl;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage();
      if (imageUrl == null && _selectedImage != null) {
        throw Exception('Failed to upload image');
      }

      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': int.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'image_url': imageUrl,
      };

      if (widget.product != null) {
        // Update existing product
        await supabase
            .from('products')
            .update(productData)
            .eq('id', widget.product!['id']);
      } else {
        // Create new product
        await supabase.from('products').insert(productData);
      }

      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null
                  ? 'Produk berhasil diperbarui'
                  : 'Produk berhasil ditambahkan'
            ),
          ),
        );
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
    return AlertDialog(
      title: Text(widget.product != null ? 'Edit Produk' : 'Tambah Produk'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Harga wajib diisi';
                  if (int.tryParse(value!) == null) return 'Harga harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Stok wajib diisi';
                  if (int.tryParse(value!) == null) return 'Stok harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: _pickImage,
                    tooltip: 'Pilih dari galeri',
                  ),
                ],
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}
