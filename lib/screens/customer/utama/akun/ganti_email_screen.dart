import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/keranjang/auth_service.dart';

class GantiEmailScreen extends StatefulWidget {
  final String emailSaatIni;
  const GantiEmailScreen({super.key, required this.emailSaatIni});

  @override
  State<GantiEmailScreen> createState() => _GantiEmailScreenState();
}

class _GantiEmailScreenState extends State<GantiEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.updateEmail(_controller.text);
      if(mounted) {
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Verifikasi Email Baru"),
              content: Text("Link verifikasi telah dikirim ke ${_controller.text}. Silakan cek email Anda untuk menyelesaikan perubahan."),
              actions: [TextButton(onPressed: (){
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              }, child: const Text("OK"))],
            )
        );
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
      appBar: AppBar(title: const Text("Ganti Email"), backgroundColor: const Color(0xFFC50000), foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("Masukkan Email baru dan pastikan Email yang kamu masukkan benar", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Text("Email Saat Ini: ${widget.emailSaatIni}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Masukkan Email Baru", border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return "Wajib diisi";
                if (!v.contains('@') || !v.contains('.')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF304FFE),
                minimumSize: const Size(double.infinity, 50)),
              child: const Text("SELESAI"),
            )
          ],
        ),
      ),
    );
  }
}