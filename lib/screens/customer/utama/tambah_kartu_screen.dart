import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/services/metode_pembayaran_service.dart';

class TambahKartuScreen extends StatefulWidget {
  final String namaBank;
  const TambahKartuScreen({super.key, required this.namaBank});

  @override
  State<TambahKartuScreen> createState() => _TambahKartuScreenState();
}

class _TambahKartuScreenState extends State<TambahKartuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorController = TextEditingController();
  final _masaBerlakuController = TextEditingController();
  final MetodePembayaranService _service = MetodePembayaranService();

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final metode = MetodePembayaranModel(
      namaMetode: widget.namaBank,
      tipe: TipeMetodePembayaran.kartuDebit,
      nomor: _nomorController.text,
      masaBerlaku: _masaBerlakuController.text,
    );

    await _service.tambahMetodePembayaran(user.uid, metode);

    if (mounted) {
      // Kembali 3 layar sekaligus ke halaman utama Metode Pembayaran
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tambah Kartu ${widget.namaBank}"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("Nomor Kartu"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomorController,
              decoration: const InputDecoration(hintText: "1234 5678 9012 3456", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 16),
            const Text("Masa Berlaku"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _masaBerlakuController,
              decoration: const InputDecoration(hintText: "MM/YY", border: OutlineInputBorder()),
              keyboardType: TextInputType.datetime,
              validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _simpan,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue
              ),
              child: const Text("Tambah Kartu Baru", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}