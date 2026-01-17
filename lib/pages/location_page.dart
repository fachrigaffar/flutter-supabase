import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  void _openMaps(String location) async {
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$location');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi/Maps'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Lokasi Toko Kami',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Toko Pusat Jakarta'),
              subtitle: const Text('Jl. Sudirman No. 123, Jakarta Pusat'),
              trailing: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _openMaps('Jl.+Sudirman+No.+123,+Jakarta+Pusat'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Cabang Bandung'),
              subtitle: const Text('Jl. Braga No. 45, Bandung'),
              trailing: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _openMaps('Jl.+Braga+No.+45,+Bandung'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text('Cabang Surabaya'),
              subtitle: const Text('Jl. Tunjungan No. 67, Surabaya'),
              trailing: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _openMaps('Jl.+Tunjungan+No.+67,+Surabaya'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text('Cabang Medan'),
              subtitle: const Text('Jl. Ahmad Yani No. 89, Medan'),
              trailing: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _openMaps('Jl.+Ahmad+Yani+No.+89,+Medan'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Jam Operasional Toko:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Senin - Jumat: 09:00 - 21:00 WIB'),
                Text('• Sabtu - Minggu: 10:00 - 22:00 WIB'),
                Text('• Hari Libur Nasional: 10:00 - 18:00 WIB'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
