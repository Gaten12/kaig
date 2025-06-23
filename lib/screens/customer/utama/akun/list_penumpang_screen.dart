import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/passenger_model.dart'; // Pastikan path ini benar
import '../../../../services/auth_service.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000), // Warna merah
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isSelectionMode ? "Pilih Penumpang" : "Daftar Penumpang",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 18 : 20),
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
            return _buildEmptyState(context, isSmallScreen);
          }

          final penumpangList = snapshot.data!;

          // Tampilan ketika ada daftar penumpang
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 8.0 : 12.0),
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
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12.0 : 16.0),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isSmallScreen ? 20 : 25, // Responsive radius
                              backgroundColor: const Color(0xFFC50000), // Warna merah
                              foregroundColor: Colors.white,
                              child: Text(
                                // Cek apakah namaLengkap tidak kosong, jika ya, ambil huruf pertama
                                // Jika kosong, tampilkan "?" sebagai default
                                penumpang.namaLengkap.isNotEmpty
                                    ? penumpang.namaLengkap[0].toUpperCase()
                                    : '?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 18 : 22), // Responsive font size
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dewasa", // Anda bisa mengganti dengan `penumpang.tipePenumpang` jika ada
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 12, // Responsive font size
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    penumpang.namaLengkap,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 14 : 16, // Responsive font size
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: isSmallScreen ? 14 : 16, color: Colors.grey), // Responsive icon size
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateAndRefresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF304FFE), // Warna biru
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16), // Responsive padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Tambah Penumpang",
                      style: TextStyle(fontSize: isSmallScreen ? 15 : 16, color: Colors.white),
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
  Widget _buildEmptyState(BuildContext context, bool isSmallScreen) {
    return SingleChildScrollView( // Added SingleChildScrollView
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20.0 : 24.0, vertical: isSmallScreen ? 20.0 : 40.0), // Responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40), // Responsive spacing
            Icon(
              Icons.assignment, // Icon sesuai gambar
              size: isSmallScreen ? 80 : 100, // Responsive icon size
              color: const Color(0xFF0000CD), // Warna biru
            ),
            SizedBox(height: isSmallScreen ? 20 : 24), // Responsive spacing
            Text(
              "Belum Ada Penumpang Tersimpan",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18, // Responsive font size
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
            Text(
              "Anda dapat menambahkan daftar penumpang untuk mempermudah saat pemesanan tiket",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14, // Responsive font size
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 40 : 60), // Responsive spacing
            Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 12.0 : 16.0), // Responsive bottom padding
              child: ElevatedButton(
                onPressed: _navigateAndRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF304FFE), // Warna biru
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16), // Responsive padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Tambah Penumpang",
                  style: TextStyle(fontSize: isSmallScreen ? 15 : 16, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 16), // Ensure content is not too close to the screen edge
          ],
        ),
      ),
    );
  }
}