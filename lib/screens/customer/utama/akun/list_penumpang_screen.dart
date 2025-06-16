import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/passenger_model.dart'; // Pastikan path ini benar
import '../../../login/auth_service.dart';
import '../tiket/form_penumpang_screen.dart'; // Untuk mengambil daftar penumpang


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

   void _navigateAndRefresh() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormPenumpangScreen()),
    ).then((result) {
      if (result == true) {
        _refreshData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000), // Warna merah
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isSelectionMode ? "Pilih Penumpang" : "Daftar Penumpang",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<PassengerModel>>(
        stream: _penumpangStream,
        builder: (context, snapshot) {
          //
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final penumpangList = snapshot.data!;

          // Tampilan ketika ada daftar penumpang
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: penumpangList.length,
                  itemBuilder: (context, index) {
                    final penumpang = penumpangList[index];
                    return GestureDetector(
                      onTap: () {
                        if (widget.isSelectionMode) {
                          Navigator.pop(context, penumpang);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormPenumpangScreen(penumpangToEdit: penumpang),
                            ),
                          ).then((result) {
                            if (result == true) _refreshData();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                                backgroundColor: const Color(0xFFC50000), // Warna merah
                                foregroundColor: Colors.white,
                                child: Text(
                                  // Cek apakah namaLengkap tidak kosong, jika ya, ambil huruf pertama
                                  // Jika kosong, tampilkan "?" sebagai default
                                  penumpang.namaLengkap.isNotEmpty
                                      ? penumpang.namaLengkap[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dewasa", // Anda bisa mengganti dengan `penumpang.tipePenumpang` jika ada
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    penumpang.namaLengkap,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateAndRefresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0000CD), // Warna biru
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Tambah Penumpang",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    //
    );
  }

  // Widget untuk tampilan saat daftar penumpang kosong
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(
            Icons.assignment, // Icon sesuai gambar
            size: 100,
            color: Color(0xFF0000CD), // Warna biru
          ),
          const SizedBox(height: 24),
          Text(
            "Belum Ada Penumpang Tersimpan",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Anda dapat menambahkan daftar penumpang untuk mempermudah saat pemesanan tiket",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton(
              onPressed: _navigateAndRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0000CD), // Warna biru
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Tambah Penumpang",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}