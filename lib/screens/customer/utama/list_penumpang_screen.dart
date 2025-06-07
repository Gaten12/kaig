import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/passenger_model.dart'; // Pastikan path ini benar
import '../../../services/auth_service.dart'; // Untuk mengambil daftar penumpang
import 'form_penumpang_screen.dart';

class ListPenumpangScreen extends StatefulWidget {
  // Tambahkan parameter untuk membedakan mode manajemen dan mode pemilihan
  final bool isSelectionMode;

  const ListPenumpangScreen({super.key, this.isSelectionMode = false});

  @override
  State<ListPenumpangScreen> createState() => _ListPenumpangScreenState();
}

class _ListPenumpangScreenState extends State<ListPenumpangScreen> {
  final AuthService _authService = AuthService();
  Stream<List<PassengerModel>>? _penumpangStream;

  @override
  void initState() {
    super.initState();
    _refreshData(); // Panggil saat pertama kali layar dibuka
  }

  void _refreshData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        // Panggil metode getSavedPassengers yang sudah kita perbaiki
        // untuk hanya mengambil penumpang yang ditambahkan (isPrimary: false)
        _penumpangStream = _authService.getSavedPassengers(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? "Pilih Penumpang" : "Daftar Penumpang"),
      ),
      body: StreamBuilder<List<PassengerModel>>(
        stream: _penumpangStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Jika dalam mode pemilihan, tetap tampilkan tombol Tambah Penumpang Baru
            return _buildEmptyState(context, isSelectionMode: widget.isSelectionMode);
          }

          final penumpangList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: penumpangList.length,
            itemBuilder: (context, index) {
              final penumpang = penumpangList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(penumpang.namaLengkap.isNotEmpty ? penumpang.namaLengkap[0].toUpperCase() : "?"),
                  ),
                  title: Text(penumpang.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${penumpang.tipeId} - ${penumpang.nomorId}\n${penumpang.tipePenumpang}"),
                  isThreeLine: true,
                  trailing: widget.isSelectionMode
                      ? null // Tidak ada trailing jika mode pemilihan
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (widget.isSelectionMode) {
                      // Jika mode pemilihan, kembalikan data penumpang yang dipilih
                      Navigator.pop(context, penumpang);
                    } else {
                      // Jika mode manajemen, buka form edit
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormPenumpangScreen(penumpangToEdit: penumpang),
                        ),
                      ).then((result) {
                        // Refresh data jika ada perubahan (saat kembali dari form)
                        if (result == true) _refreshData();
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormPenumpangScreen()),
          ).then((result) {
            // Refresh data jika ada perubahan (saat kembali dari form)
            if (result == true) _refreshData();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text("Tambah Penumpang"),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isSelectionMode = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isSelectionMode) ...[ // Tampilkan ikon dan teks hanya jika bukan mode pemilihan
              Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "Belum Ada Penumpang Tersimpan",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Anda dapat menambahkan daftar penumpang untuk mempermudah saat pemesanan tiket.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text(
                "Tidak ada penumpang tersimpan.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Tekan tombol di bawah untuk menambahkan penumpang baru.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}