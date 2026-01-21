import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final supabase = Supabase.instance.client;

  Future<void> _generateSalesReport() async {
    try {
      final response = await supabase
          .from('orders')
          .select('*, order_items(*), customers(*)')
          .order('created_at', ascending: false);

      final orders = response as List<dynamic>;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Laporan Penjualan BlangKis',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                'Tanggal: ${DateTime.now().toString().split(' ')[0]}',
                style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Order ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Tanggal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...orders.map((order) => pw.TableRow(
                        children: [
                          pw.Text('#${order['id']}'),
                          pw.Text(order['customers']?['full_name'] ?? 'Unknown'),
                          pw.Text(_formatDate(order['created_at'])),
                          pw.Text(order['status'] ?? 'Unknown'),
                          pw.Text('Rp ${order['total_amount']}'),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Pesanan: ${orders.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Total Pendapatan: Rp ${orders.fold(0, (sum, order) => sum + (int.tryParse(order['total_amount'].toString()) ?? 0))}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil diekspor ke PDF')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
      ),
      body: GridView.count(
        crossAxisCount: 1,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        children: [
          _buildReportCard(
            icon: Icons.analytics,
            title: 'Laporan Global',
            subtitle: 'Laporan penjualan keseluruhan dengan export PDF',
            color: Colors.blue,
            onTap: _generateSalesReport,
          ),
          _buildReportCard(
            icon: Icons.calendar_today,
            title: 'Laporan Periodik',
            subtitle: 'Laporan berdasarkan periode waktu',
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur laporan periodik akan segera hadir')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
