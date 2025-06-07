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
  String _searchQuery = "";
  List<KeretaModel> _allKereta = [];
  List<KeretaModel> _filteredKereta = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterKereta();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterKereta() {
    if (_searchQuery.isEmpty) {
      _filteredKereta = List.from(_allKereta);
    } else {
      _filteredKereta = _allKereta.where((kereta) {
        final namaLower = kereta.nama.toLowerCase();
        // Anda bisa menambahkan field lain untuk dicari, misalnya kelasUtama
        final kelasUtamaLower = kereta.kelasUtama.toLowerCase();
        final searchQueryLower = _searchQuery.toLowerCase();

        return namaLower.contains(searchQueryLower) ||
            kelasUtamaLower.contains(searchQueryLower);
        // Jika hanya ingin mencari berdasarkan nama:
        // return namaLower.contains(searchQueryLower);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text("Daftar Kereta",
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
                labelText: "Cari Kereta (Nama atau Kelas)", // Sesuaikan label
                hintText: "Masukkan nama atau kelas kereta...", // Sesuaikan hint
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
            child: StreamBuilder<List<KeretaModel>>(
              stream: _adminService.getKeretaList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Error Stream Kereta: ${snapshot.error}");
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _allKereta = [];
                  _filterKereta();
                  return const Center(child: Text("Belum ada data kereta."));
                }

                if (_allKereta != snapshot.data!) {
                  _allKereta = snapshot.data!;
                  _filterKereta();
                }

                if (_filteredKereta.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text("Kereta tidak ditemukan."));
                }
                if (_filteredKereta.isEmpty && _allKereta.isEmpty) {
                  return const Center(child: Text("Belum ada data kereta."));
                }

                return ListView.builder(
                  itemCount: _filteredKereta.length,
                  itemBuilder: (context, index) {
                    final kereta = _filteredKereta[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text(kereta.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Kelas Utama: ${kereta.kelasUtama}\nJumlah Kursi: ${kereta.jumlahKursi}"),
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
                                    await _adminService.deleteKereta(kereta.id);
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${kereta.nama} berhasil dihapus.')),
                                      );
                                    }
                                  } catch (e) {
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal menghapus kereta: $e')),
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
            MaterialPageRoute(builder: (context) => const FormKeretaScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}