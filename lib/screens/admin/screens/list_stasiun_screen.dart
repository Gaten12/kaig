import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Hanya untuk contoh jika ada error di service
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar
import '../services/admin_firestore_service.dart'; // Pastikan path ini benar
import 'form_stasiun_screen.dart'; // Pastikan path ini benar

class ListStasiunScreen extends StatefulWidget {
  const ListStasiunScreen({super.key});

  @override
  State<ListStasiunScreen> createState() => _ListStasiunScreenState();
}

class _ListStasiunScreenState extends State<ListStasiunScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  String _searchQuery = "";
  List<StasiunModel> _allStasiun = [];
  List<StasiunModel> _filteredStasiun = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterStasiun();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStasiun() {
    if (_searchQuery.isEmpty) {
      _filteredStasiun = List.from(_allStasiun);
    } else {
      _filteredStasiun = _allStasiun.where((stasiun) {
        final displayNameLower = stasiun.displayName.toLowerCase();
        final kotaLower = stasiun.kota.toLowerCase();
        final searchQueryLower = _searchQuery.toLowerCase();
        return displayNameLower.contains(searchQueryLower) ||
            kotaLower.contains(searchQueryLower);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text("Daftar Stasiun",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Cari Stasiun (Nama atau Kota)",
                hintText: "Masukkan nama atau kota stasiun...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                // Tambahkan tombol clear jika ada teks
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // setState akan dipicu oleh listener _searchController
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StasiunModel>>(
              stream: _adminService.getStasiunList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Error Stream Stasiun: ${snapshot.error}");
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _allStasiun = [];
                  _filterStasiun(); // Panggil filter untuk menampilkan pesan yang sesuai
                  return const Center(child: Text("Belum ada data stasiun."));
                }

                // Update _allStasiun jika data dari stream berubah
                // Ini penting agar _allStasiun selalu sinkron dengan data terbaru
                if (_allStasiun != snapshot.data!) {
                  _allStasiun = snapshot.data!;
                  // Panggil _filterStasiun setelah _allStasiun diinisialisasi/diperbarui.
                  // Ini memastikan bahwa jika pengguna sudah mengetik query,
                  // filter diterapkan pada data terbaru.
                  _filterStasiun();
                }


                if (_filteredStasiun.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text("Stasiun tidak ditemukan."));
                }
                // Kondisi ini bisa terjadi jika stream awalnya ada data, lalu jadi kosong,
                // dan query juga kosong.
                if (_filteredStasiun.isEmpty && _allStasiun.isEmpty) {
                  return const Center(child: Text("Belum ada data stasiun."));
                }


                return ListView.builder(
                  itemCount: _filteredStasiun.length,
                  itemBuilder: (context, index) {
                    final stasiun = _filteredStasiun[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text(stasiun.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Kota: ${stasiun.kota}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FormStasiunScreen(stasiunToEdit: stasiun),
                                  ),
                                ).then((_) {
                                  // Tidak perlu clear search di sini agar pengguna bisa
                                  // melanjutkan pencarian jika mau.
                                  // Data akan otomatis di-refresh oleh StreamBuilder jika ada perubahan.
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Konfirmasi Hapus'),
                                      content: Text('Anda yakin ingin menghapus stasiun ${stasiun.nama}?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirm == true) {
                                  try {
                                    await _adminService.deleteStasiun(stasiun.id);
                                    // StreamBuilder akan otomatis mengupdate UI.
                                    // _allStasiun dan _filteredStasiun akan diperbarui
                                    // ketika snapshot baru dari stream diterima.
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${stasiun.nama} berhasil dihapus.')),
                                      );
                                    }
                                  } catch (e) {
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal menghapus stasiun: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormStasiunScreen()),
          ).then((_){
            // _searchController.clear(); // Opsional, bisa dihapus jika tidak ingin clear search
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}