import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart'; // Pastikan casing nama file ini konsisten
import '../services/admin_firestore_service.dart';
import 'form_jadwal_screen.dart';

class ListJadwalScreen extends StatefulWidget {
  const ListJadwalScreen({super.key});

  @override
  State<ListJadwalScreen> createState() => _ListJadwalScreenState();
}

class _ListJadwalScreenState extends State<ListJadwalScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  String _searchQuery = "";
  List<JadwalModel> _allJadwal = [];
  List<JadwalModel> _filteredJadwal = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterJadwal();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterJadwal() {
    if (_searchQuery.isEmpty) {
      _filteredJadwal = List.from(_allJadwal);
    } else {
      _filteredJadwal = _allJadwal.where((jadwal) {
        final namaKeretaLower = jadwal.namaKereta.toLowerCase();
        final idKeretaLower = jadwal.idKereta.toLowerCase();
        final stasiunAsalLower = jadwal.idStasiunAsal.toLowerCase();
        final stasiunTujuanLower = jadwal.idStasiunTujuan.toLowerCase();
        final searchQueryLower = _searchQuery.toLowerCase();

        // Anda bisa menambahkan kriteria pencarian lain jika perlu,
        // misalnya berdasarkan tanggal atau kelas
        return namaKeretaLower.contains(searchQueryLower) ||
            idKeretaLower.contains(searchQueryLower) ||
            stasiunAsalLower.contains(searchQueryLower) ||
            stasiunTujuanLower.contains(searchQueryLower);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text("Daftar Jadwal Kereta",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w200,
            )),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Cari Jadwal (Nama/ID Kereta, Rute)",
                hintText: "Masukkan nama/ID kereta, stasiun asal/tujuan...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
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
            child: StreamBuilder<List<JadwalModel>>(
              stream: _adminService.getJadwalList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print(
                      "[ListJadwalScreen] STREAMBUILDER ERROR: ${snapshot.error}");
                  return Center(
                      child: Text(
                          "Terjadi Error: ${snapshot.error.toString()}\nPastikan Indeks Firestore sudah dibuat."));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _allJadwal = [];
                  _filterJadwal(); // Panggil filter untuk menampilkan pesan yang sesuai
                  return const Center(
                      child: Text(
                          "Belum ada data jadwal. Silakan tambahkan jadwal baru."));
                }

                // Update _allJadwal jika data dari stream berubah
                if (_allJadwal != snapshot.data!) {
                  _allJadwal = snapshot.data!;
                  _filterJadwal();
                }

                if (_filteredJadwal.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text("Jadwal tidak ditemukan."));
                }
                if (_filteredJadwal.isEmpty && _allJadwal.isEmpty) {
                  return const Center(child: Text("Belum ada data jadwal. Silakan tambahkan jadwal baru."));
                }


                return ListView.builder(
                  itemCount: _filteredJadwal.length,
                  itemBuilder: (context, index) {
                    final jadwal = _filteredJadwal[index];
                    String tanggalBerangkatFormatted = "N/A";
                    String jamTibaFormatted = "N/A";
                    String tanggalTibaFormattedSimple = "N/A";

                    try {
                      tanggalBerangkatFormatted = DateFormat(
                          'EEE, dd MMM yy HH:mm', 'id_ID')
                          .format(jadwal.tanggalBerangkatUtama.toDate());
                      jamTibaFormatted = DateFormat('HH:mm', 'id_ID')
                          .format(jadwal.tanggalTibaUtama.toDate());
                      tanggalTibaFormattedSimple =
                          DateFormat('dd MMM', 'id_ID')
                              .format(jadwal.tanggalTibaUtama.toDate());
                    } catch (e) {
                      print(
                          "Error formatting date for jadwal ID ${jadwal.id}: $e");
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text(
                            "${jadwal.namaKereta} (${jadwal.idKereta})",
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "Rute: ${jadwal.idStasiunAsal} ❯ ${jadwal.idStasiunTujuan}\n"
                              "Berangkat: $tanggalBerangkatFormatted\n"
                              "Tiba: $jamTibaFormatted ($tanggalTibaFormattedSimple)\n"
                              "Kelas Tersedia: ${jadwal.daftarKelasHarga.length} jenis",
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_off_outlined,
                                  color: Colors.grey.shade400),
                              tooltip:
                              "Fitur Edit Jadwal belum tersedia untuk arsitektur ini.",
                              onPressed: null, // Menonaktifkan tombol
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Colors.red.shade700),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Konfirmasi Hapus'),
                                      content: Text(
                                          'Anda yakin ingin menghapus jadwal ${jadwal.namaKereta} (${jadwal.idStasiunAsal}-${jadwal.idStasiunTujuan})?'),
                                      actions: <Widget>[
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('Batal')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Hapus',
                                                style: TextStyle(
                                                    color: Colors.red))),
                                      ],
                                    );
                                  },
                                );
                                if (confirm == true) {
                                  try {
                                    await _adminService.deleteJadwal(jadwal.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(
                                              'Jadwal ${jadwal.namaKereta} berhasil dihapus.')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(
                                              'Gagal menghapus jadwal: $e')));
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
            MaterialPageRoute(builder: (context) => const FormJadwalScreen()),
          ).then((_) {
            // Opsional: Anda bisa memutuskan apakah ingin membersihkan query pencarian
            // setelah kembali dari halaman form.
            // _searchController.clear();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}