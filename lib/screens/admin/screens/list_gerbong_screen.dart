import 'package:flutter/material.dart';
import '../../../models/gerbong_tipe_model.dart'; // Pastikan path ini benar
import '../services/admin_firestore_service.dart'; // Pastikan path ini benar
import 'form_gerbong_screen.dart'; // Pastikan path ini benar

class ListGerbongScreen extends StatefulWidget {
  const ListGerbongScreen({super.key});

  @override
  State<ListGerbongScreen> createState() => _ListGerbongScreenState();
}

class _ListGerbongScreenState extends State<ListGerbongScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  String _searchQuery = "";
  List<GerbongTipeModel> _allGerbong = [];
  List<GerbongTipeModel> _filteredGerbong = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterGerbong();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterGerbong() {
    if (_searchQuery.isEmpty) {
      _filteredGerbong = List.from(_allGerbong);
    } else {
      _filteredGerbong = _allGerbong.where((gerbong) {
        final namaTipeLower = gerbong.namaTipeLengkap.toLowerCase();
        final layoutLower = gerbong.tipeLayout.deskripsi.toLowerCase();
        final searchQueryLower = _searchQuery.toLowerCase();
        return namaTipeLower.contains(searchQueryLower) ||
            layoutLower.contains(searchQueryLower);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text("Kelola Tipe Gerbong",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Cari Tipe Gerbong (Nama atau Layout)",
                hintText: "Masukkan nama atau tipe layout gerbong...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GerbongTipeModel>>(
              stream: _adminService.getGerbongTipeList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Error Stream Gerbong: ${snapshot.error}");
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _allGerbong = [];
                  _filterGerbong();
                  return const Center(child: Text("Belum ada data tipe gerbong."));
                }

                // Update _allGerbong jika data dari stream berubah
                if (_allGerbong != snapshot.data!) {
                  _allGerbong = snapshot.data!;
                  _filterGerbong();
                }

                if (_filteredGerbong.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text("Tipe gerbong tidak ditemukan."));
                }
                if (_filteredGerbong.isEmpty && _allGerbong.isEmpty) {
                  return const Center(child: Text("Belum ada data tipe gerbong."));
                }

                return ListView.builder(
                  itemCount: _filteredGerbong.length,
                  itemBuilder: (context, index) {
                    final gerbong = _filteredGerbong[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.view_comfortable_outlined, size: 30),
                        title: Text(gerbong.namaTipeLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Layout: ${gerbong.tipeLayout.deskripsi}\nKapasitas: ${gerbong.jumlahKursi} kursi"),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormGerbongScreen(gerbongToEdit: gerbong),
                              ),
                            ).then((_) {
                              // Data akan otomatis di-refresh oleh StreamBuilder jika ada perubahan.
                            });
                          },
                        ),
                        // Anda bisa menambahkan tombol delete di sini jika diperlukan,
                        // seperti pada ListStasiunScreen
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
            MaterialPageRoute(builder: (context) => const FormGerbongScreen()),
          ).then((_){
            // _searchController.clear(); // Opsional
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}