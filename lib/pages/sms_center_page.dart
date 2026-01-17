import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsCenterPage extends StatelessWidget {
  const SmsCenterPage({super.key});

  void _sendSms(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Kirim SMS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sms, color: Colors.green),
              title: const Text('Customer Service'),
              subtitle: const Text('+62 812-3456-7890'),
              trailing: IconButton(
                icon: const Icon(Icons.message),
                onPressed: () => _sendSms('+6281234567890'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sms, color: Colors.blue),
              title: const Text('Technical Support'),
              subtitle: const Text('+62 812-3456-7891'),
              trailing: IconButton(
                icon: const Icon(Icons.message),
                onPressed: () => _sendSms('+6281234567891'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sms, color: Colors.orange),
              title: const Text('Sales'),
              subtitle: const Text('+62 812-3456-7892'),
              trailing: IconButton(
                icon: const Icon(Icons.message),
                onPressed: () => _sendSms('+6281234567892'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Format SMS:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'KOMPLAIN: [Pesan komplain Anda]\n\n'
              'PERTANYAAN: [Pertanyaan Anda]\n\n'
              'PESANAN: [Detail pesanan Anda]',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
