import 'package:flutter/material.dart';
import 'package:kaig/services/auth_service.dart';

class GantiNomorTeleponScreen extends StatefulWidget {
  final String nomorTeleponSaatIni;
  const GantiNomorTeleponScreen({super.key, required this.nomorTeleponSaatIni});

  @override
  State<GantiNomorTeleponScreen> createState() => _GantiNomorTeleponScreenState();
}

class _GantiNomorTeleponScreenState extends State<GantiNomorTeleponScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nomorTeleponSaatIni);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.updateNomorTelepon(_controller.text);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nomor telepon berhasil diperbarui.")));
        Navigator.of(context).pop(); // Kembali ke halaman info data diri
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ganti Nomor Telepon"), backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("Masukkan No. Teleponmu dan pastikan No. Telepon yang kamu masukkan benar", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "No. Telepon", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _simpan,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("SIMPAN"),
            )
          ],
        ),
      ),
    );
  }
}