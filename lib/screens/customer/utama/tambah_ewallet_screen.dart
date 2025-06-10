import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/services/metode_pembayaran_service.dart';

class TambahEwalletScreen extends StatefulWidget {
  final String namaEwallet;
  const TambahEwalletScreen({super.key, required this.namaEwallet});

  @override
  State<TambahEwalletScreen> createState() => _TambahEwalletScreenState();
}

class _TambahEwalletScreenState extends State<TambahEwalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorController = TextEditingController();
  final MetodePembayaranService _service = MetodePembayaranService();

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final metode = MetodePembayaranModel(
      namaMetode: widget.namaEwallet,
      tipe: TipeMetodePembayaran.ewallet,
      nomor: _nomorController.text,
    );

    await _service.tambahMetodePembayaran(user.uid, metode);

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tambah ${widget.namaEwallet}"),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("Nomor E-Wallet"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomorController,
              decoration: const InputDecoration(hintText: "0812 3456 7890", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _simpan,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF0000CD)
              ),
              child: const Text("Tambah E-Wallet", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}