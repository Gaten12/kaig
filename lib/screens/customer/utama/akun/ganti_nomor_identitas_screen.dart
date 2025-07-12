import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaig/models/passenger_model.dart';
import 'package:kaig/services/auth_service.dart';

class GantiNomorIdentitasScreen extends StatefulWidget {
  final PassengerModel passenger;
  const GantiNomorIdentitasScreen({super.key, required this.passenger});

  @override
  State<GantiNomorIdentitasScreen> createState() =>
      _GantiNomorIdentitasScreenState();
}

class _GantiNomorIdentitasScreenState extends State<GantiNomorIdentitasScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // --- PERBAIKAN 1: Pastikan semua opsi ada di sini ---
  // Menambahkan 'Lainnya' atau opsi lain yang mungkin ada di database Anda
  final List<String> _tipeIdOptions = ['KTP', 'Paspor', 'SIM', 'Lainnya'];
  late String _selectedTipeId;
  late TextEditingController _nomorIdController;

  @override
  void initState() {
    super.initState();
    _nomorIdController = TextEditingController(text: widget.passenger.nomorId);

    // --- PERBAIKAN 2: Logika inisialisasi yang lebih aman ---
    // Cek apakah tipe ID yang tersimpan ada di dalam daftar opsi.
    // Jika tidak, gunakan nilai pertama dari daftar sebagai default untuk menghindari error.
    if (_tipeIdOptions.contains(widget.passenger.tipeId)) {
      _selectedTipeId = widget.passenger.tipeId;
    } else {
      // Jika nilai dari database (misal: "ktp") tidak ada di list ['KTP', 'Paspor'],
      // maka atur nilai default untuk mencegah error.
      _selectedTipeId = _tipeIdOptions.first;
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Logika simpan tidak perlu diubah, sudah benar
      final updatedPassenger = PassengerModel(
        id: widget.passenger.id,
        tipeId: _selectedTipeId,
        nomorId: _nomorIdController.text,
        namaLengkap: widget.passenger.namaLengkap,
        tanggalLahir: widget.passenger.tanggalLahir,
        jenisKelamin: widget.passenger.jenisKelamin,
        tipePenumpang: widget.passenger.tipePenumpang,
        isPrimary: widget.passenger.isPrimary,
      );

      await _authService.updatePrimaryPassenger(updatedPassenger);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nomor identitas berhasil diperbarui.")));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Ganti Nomor Identitas"),
          backgroundColor: const Color(0xFFC50000),
          foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
                "Masukkan No identitasmu dan pastikan No Identitas yang kamu masukkan benar",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Tipe ID', border: OutlineInputBorder()),
                    value: _selectedTipeId,
                    items: _tipeIdOptions
                        .map((String value) =>
                        DropdownMenuItem<String>(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTipeId = newValue;
                          _nomorIdController.clear();
                        });
                      }
                    },
                    validator: (v) => v == null ? 'Pilih tipe' : null,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nomorIdController,
                    decoration: const InputDecoration(
                        labelText: 'No. ID', border: OutlineInputBorder()),
                    keyboardType: _selectedTipeId == 'Paspor'
                        ? TextInputType.text
                        : TextInputType.number,
                    inputFormatters: _selectedTipeId == 'Paspor'
                        ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))]
                        : [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
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