import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/screens/customer/utama/tambah_ewallet_screen.dart';
import 'package:kaig/screens/customer/utama/tambah_kartu_screen.dart';

class PilihJenisPembayaranScreen extends StatelessWidget {
  final TipeMetodePembayaran tipe;
  const PilihJenisPembayaranScreen({super.key, required this.tipe});

  @override
  Widget build(BuildContext context) {
    final bool isKartu = tipe == TipeMetodePembayaran.kartuDebit;
    final String title = isKartu ? "Pilih Kartu ATM / Mobile" : "Pilih E-Wallet";
    final List<String> options = isKartu
        ? ["BCA", "BTN", "BRI", "CIMB", "BNI"]
        : ["GOPAY", "OVO", "DANA", "SHOPEE-PAY", "LINK AJA"];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final namaMetode = options[index];
          return Card(
            child: ListTile(
              // leading: Image.asset('assets/logo_$namaMetode.png'),
              leading: const Icon(Icons.wallet),
              title: Text(namaMetode),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                final Widget nextPage = isKartu
                    ? TambahKartuScreen(namaBank: namaMetode)
                    : TambahEwalletScreen(namaEwallet: namaMetode);
                Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
              },
            ),
          );
        },
      ),
    );
  }
}
