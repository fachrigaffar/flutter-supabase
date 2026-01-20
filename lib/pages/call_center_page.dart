import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallCenterPage extends StatelessWidget {
  const CallCenterPage({super.key});

  void _makeCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Hubungi Kami',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Customer Service'),
              subtitle: const Text('+62 812-3456-7890'),
              trailing: IconButton(
                icon: const Icon(Icons.call),
                onPressed: () => _makeCall('+6281234567890'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Jam Operasional:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text('Senin - Jumat: 08:00 - 17:00 WIB'),
          const Text('Sabtu: 08:00 - 14:00 WIB'),
          const Text('Minggu: Tutup'),
        ],
      ),
    );
  }
}
