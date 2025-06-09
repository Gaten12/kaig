import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/passenger_model.dart';
import 'package:kaig/services/auth_service.dart';

class GantiInformasiPribadiScreen extends StatefulWidget {
  final PassengerModel passenger;
  const GantiInformasiPribadiScreen({super.key, required this.passenger});

  @override
  State<GantiInformasiPribadiScreen> createState() => _GantiInformasiPribadiScreenState();
}

class _GantiInformasiPribadiScreenState extends State<GantiInformasiPribadiScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  late TextEditingController _namaController;
  late DateTime _selectedTanggalLahir;
  late String _selectedJenisKelamin;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.passenger.namaLengkap);
    _selectedTanggalLahir = widget.passenger.tanggalLahir.toDate();
    _selectedJenisKelamin = widget.passenger.jenisKelamin;
  }

  Future<void> _pilihTanggalLahir(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalLahir,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedTanggalLahir) {
      setState(() => _selectedTanggalLahir = picked);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updatedPassenger = PassengerModel(
        id: widget.passenger.id,
        namaLengkap: _namaController.text,
        tanggalLahir: Timestamp.fromDate(_selectedTanggalLahir),
        jenisKelamin: _selectedJenisKelamin,
        tipeId: widget.passenger.tipeId, // Data lama tidak diubah
        nomorId: widget.passenger.nomorId, // Data lama tidak diubah
        tipePenumpang: widget.passenger.tipePenumpang,
        isPrimary: widget.passenger.isPrimary,
      );

      await _authService.updatePrimaryPassenger(updatedPassenger);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informasi pribadi berhasil diperbarui.")));
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
      appBar: AppBar(title: const Text("Informasi Diri"), backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Tanggal Lahir',
                hintText: DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedTanggalLahir),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () => _pilihTanggalLahir(context),
            ),
            const SizedBox(height: 16),
            const Text("Jenis Kelamin", style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Expanded(child: RadioListTile<String>(
                  title: const Text('Laki-laki'), value: 'Laki-laki', groupValue: _selectedJenisKelamin,
                  onChanged: (value) => setState(() => _selectedJenisKelamin = value!),
                )),
                Expanded(child: RadioListTile<String>(
                  title: const Text('Perempuan'), value: 'Perempuan', groupValue: _selectedJenisKelamin,
                  onChanged: (value) => setState(() => _selectedJenisKelamin = value!),
                )),
              ],
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