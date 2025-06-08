import 'package:flutter/material.dart';
import '../../../models/KeretaModel.dart'; // Pastikan path ini benar
import '../services/admin_firestore_service.dart'; // Pastikan path ini benar
import 'form_kereta_screen.dart'; // Pastikan path ini benar

class ListKeretaScreen extends StatefulWidget {
  const ListKeretaScreen({super.key});

  @override
  State<ListKeretaScreen> createState() => _ListKeretaScreenState();
}

class _ListKeretaScreenState extends State<ListKeretaScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController _searchController = TextEditingController();

  // Menggunakan StreamBuilder secara langsung lebih sederhana untuk daftar real-time
  // State lokal untuk filter tidak lagi diperlukan jika StreamBuilder menangani data

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Panggil setState untuk memicu rebuild dengan query baru
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Kereta"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Cari Nama Kereta",
                hintText: "Masukkan nama kereta...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<KeretaModel>>(
              stream: _adminService.getKeretaList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada data kereta."));
                }

                List<KeretaModel> allKereta = snapshot.data!;
                List<KeretaModel> filteredKereta = allKereta;

                if (_searchQuery.isNotEmpty) {
                  filteredKereta = allKereta
                      .where((kereta) => kereta.nama.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (filteredKereta.isEmpty) {
                  return Center(child: Text(_searchQuery.isNotEmpty ? "Kereta tidak ditemukan." : "Belum ada data kereta."));
                }

                return ListView.builder(
                  itemCount: filteredKereta.length,
                  itemBuilder: (context, index) {
                    final kereta = filteredKereta[index];

                    // Menampilkan informasi dari model baru yang sudah diperbaiki
                    String ruteDisplay = kereta.templateRute.isNotEmpty
                        ? "${kereta.templateRute.first.stasiunId} ❯ ${kereta.templateRute.last.stasiunId}"
                        : "Rute belum diatur";
                    // PERBAIKAN: Menggunakan kereta.rangkaian.length
                    String rangkaianDisplay = "Rangkaian: ${kereta.rangkaian.length} gerbong";
                    String kursiDisplay = "Kapasitas: ${kereta.totalKursi} kursi";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text(kereta.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$ruteDisplay\n$rangkaianDisplay, $kursiDisplay"),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FormKeretaScreen(keretaToEdit: kereta),
                                  ),
                                );
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
                                      content: Text('Anda yakin ingin menghapus kereta ${kereta.nama}?'),
                                      actions: <Widget>[
                                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
                                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                      ],
                                    );
                                  },
                                );
                                if (confirm == true) {
                                  try {
                                    await _adminService.deleteKereta(kereta.id);
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${kereta.nama} berhasil dihapus.')));
                                    }
                                  } catch (e) {
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus kereta: $e')));
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
            MaterialPageRoute(builder: (context) => const FormKeretaScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}