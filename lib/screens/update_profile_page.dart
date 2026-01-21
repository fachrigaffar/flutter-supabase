import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isPasswordLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('customers')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _fullNameController.text = response['name'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['phone'] ?? '';
          _addressController.text = response['address'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('customers').update({
          'name': _fullNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
        }).eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _isPasswordLoading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    } finally {
      setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update User & Password'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Full name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            child: const Text('Update Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPasswordLoading ? null : _updatePassword,
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
