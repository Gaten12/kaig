import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/passenger_model.dart'; // Pastikan path ini benar
import '../../../services/auth_service.dart'; // Untuk mengambil daftar penumpang
import 'form_penumpang_screen.dart';

class ListPenumpangScreen extends StatefulWidget {
  const ListPenumpangScreen({super.key});

  @override
  State<ListPenumpangScreen> createState() => _ListPenumpangScreenState();
}

class _ListPenumpangScreenState extends State<ListPenumpangScreen> {
  final AuthService _authService = AuthService(); // Atau service khusus penumpang
  Stream<List<PassengerModel>>? _penumpangStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Asumsi AuthService atau service lain memiliki metode getSavedPassengers
      // Untuk sekarang, kita buat metode dummy di AuthService atau langsung query di sini
      _penumpangStream = _authService.getSavedPassengers(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Penumpang"),
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
            return _buildEmptyState(context);
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormPenumpangScreen(penumpangToEdit: penumpang),
                      ),
                    ).then((_) => _refreshData()); // Refresh data setelah kembali dari form edit
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
          ).then((_) => _refreshData()); // Refresh data setelah kembali dari form tambah
        },
        icon: const Icon(Icons.add),
        label: const Text("Tambah Penumpang"),
      ),
    );
  }

  void _refreshData() {
    // Memuat ulang stream atau data
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        _penumpangStream = _authService.getSavedPassengers(user.uid);
      });
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            // Tombol Tambah Penumpang juga bisa diletakkan di sini jika FAB tidak terlihat
          ],
        ),
      ),
    );
  }
}