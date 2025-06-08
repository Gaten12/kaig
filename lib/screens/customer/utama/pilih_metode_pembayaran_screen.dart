import 'package:flutter/material.dart';

class PilihMetodePembayaranScreen extends StatelessWidget {
  const PilihMetodePembayaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> metodePembayaran = [
      {'kategori': 'E-Wallet', 'opsi': ['Gopay', 'Dana', 'OVO']},
      {'kategori': 'ATM / Mobile / Internet Banking', 'opsi': ['BCA', 'BRI']},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Metode Pembayaran"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: metodePembayaran.length,
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final kategori = metodePembayaran[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kategori['kategori'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(kategori['opsi'].length, (optIndex) {
                final opsi = kategori['opsi'][optIndex];
                return Card(
                  child: ListTile(
                    // leading: Image.asset('assets/logo_$opsi.png', width: 40), // Anda bisa menambahkan logo
                    leading: const Icon(Icons.wallet),
                    title: Text(opsi),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context, opsi); // Kembalikan nama metode yang dipilih
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}