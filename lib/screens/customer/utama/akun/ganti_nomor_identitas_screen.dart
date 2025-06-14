import 'package:flutter/material.dart';
import 'package:kaig/models/passenger_model.dart';
import 'package:kaig/screens/customer/utama/keranjang/auth_service.dart';

class GantiNomorIdentitasScreen extends StatefulWidget {
  final PassengerModel passenger;
  const GantiNomorIdentitasScreen({super.key, required this.passenger});

  @override
  State<GantiNomorIdentitasScreen> createState() => _GantiNomorIdentitasScreenState();
}

class _GantiNomorIdentitasScreenState extends State<GantiNomorIdentitasScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final List<String> _tipeIdOptions = ['KTP', 'Paspor', 'SIM'];
  late String _selectedTipeId;
  late TextEditingController _nomorIdController;

  @override
  void initState() {
    super.initState();
    _selectedTipeId = widget.passenger.tipeId;
    _nomorIdController = TextEditingController(text: widget.passenger.nomorId);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updatedPassenger = PassengerModel(
        id: widget.passenger.id,
        tipeId: _selectedTipeId,
        nomorId: _nomorIdController.text,
        namaLengkap: widget.passenger.namaLengkap, // Data lama tidak diubah
        tanggalLahir: widget.passenger.tanggalLahir,
        jenisKelamin: widget.passenger.jenisKelamin,
        tipePenumpang: widget.passenger.tipePenumpang,
        isPrimary: widget.passenger.isPrimary,
      );

      await _authService.updatePrimaryPassenger(updatedPassenger);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nomor identitas berhasil diperbarui.")));
        Navigator.of(context).pop();
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ganti Nomor Identitas"), backgroundColor: const Color(0xFFC50000), foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Masukkan No identitasmu dan pastikan No Identitas yang kamu masukkan benar", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipe ID', border: OutlineInputBorder()),
                    value: _selectedTipeId,
                    items: _tipeIdOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                    onChanged: (newValue) => setState(() => _selectedTipeId = newValue!),
                    validator: (v) => v == null ? 'Pilih tipe' : null,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nomorIdController,
                    decoration: const InputDecoration(labelText: 'No. ID', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF304FFE),
                minimumSize: const Size(double.infinity, 50)),
              child: const Text("SIMPAN"),
            )
          ],
        ),
      ),
    );
  }
}