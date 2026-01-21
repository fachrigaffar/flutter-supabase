import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final supabase = Supabase.instance.client;
  late Future<List<dynamic>> customersFuture;

  @override
  void initState() {
    super.initState();
    customersFuture = fetchCustomers();
  }

  Future<List<dynamic>> fetchCustomers() async {
    final response = await supabase
        .from('customers')
        .select()
        .order('created_at', ascending: false);

    return response as List<dynamic>;
  }

  Future<void> _refreshCustomers() async {
    setState(() {
      customersFuture = fetchCustomers();
    });
  }

  void _showCustomerDialog([Map<String, dynamic>? customer]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerDialog(
          customer: customer,
          onSave: _refreshCustomers,
        );
      },
    );
  }

  Future<void> _deleteCustomer(String customerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus konsumen ini?'),
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
        await supabase.from('customers').delete().eq('id', customerId);
        _refreshCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konsumen berhasil dihapus')),
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
        title: const Text('Kelola Konsumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCustomerDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada konsumen',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      customer['name']?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    customer['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['email'] ?? ''),
                      Text(customer['phone'] ?? 'No phone'),
                      if (customer['address'] != null && customer['address'].isNotEmpty)
                        Text(
                          customer['address'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCustomerDialog(customer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCustomer(customer['id']),
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

class CustomerDialog extends StatefulWidget {
  final Map<String, dynamic>? customer;
  final VoidCallback onSave;

  const CustomerDialog({super.key, this.customer, required this.onSave});

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _fullNameController.text = widget.customer!['name'] ?? '';
      _emailController.text = widget.customer!['email'] ?? '';
      _phoneController.text = widget.customer!['phone'] ?? '';
      _addressController.text = widget.customer!['address'] ?? '';
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customerData = {
        'name': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      };

      if (widget.customer != null) {
        // Update existing customer
        await supabase
            .from('customers')
            .update(customerData)
            .eq('id', widget.customer!['id']);
      } else {
        // For new customers, we might need to create a user account first
        // This is a simplified version - in a real app, you'd handle user registration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Untuk konsumen baru, gunakan fitur registrasi aplikasi')),
        );
        return;
      }

      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konsumen berhasil diperbarui')),
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
      title: Text(widget.customer != null ? 'Edit Konsumen' : 'Tambah Konsumen'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nama lengkap wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email wajib diisi';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value!)) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
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
          onPressed: _isLoading ? null : _saveCustomer,
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
