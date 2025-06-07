import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart'; // Impor JadwalModel Anda
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
        final stasiunAsalLower = jadwal.idStasiunAsal.toLowerCase();
        final stasiunTujuanLower = jadwal.idStasiunTujuan.toLowerCase();
        // Anda juga bisa mencari berdasarkan ID Kereta jika itu adalah string dan relevan
        // final idKeretaLower = jadwal.idKereta.toLowerCase();
        final searchQueryLower = _searchQuery.toLowerCase();

        return namaKeretaLower.contains(searchQueryLower) ||
            stasiunAsalLower.contains(searchQueryLower) ||
            stasiunTujuanLower.contains(searchQueryLower);
        // || idKeretaLower.contains(searchQueryLower);
      }).toList();
    }
    // Setelah filtering, panggil print untuk debug jika perlu
    // print("[ListJadwalScreen] _filterJadwal: _filteredJadwal count = ${_filteredJadwal.length} for query '$_searchQuery'");
  }


  @override
  Widget build(BuildContext context) {
    print("[ListJadwalScreen] Build method dipanggil. Query: '$_searchQuery'");
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text("Daftar Jadwal Kereta",
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
                labelText: "Cari Jadwal (Nama Kereta, Stasiun Asal/Tujuan)",
                hintText: "Masukkan nama kereta, stasiun...",
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
            child: StreamBuilder<List<JadwalModel>>(
              stream: _adminService.getJadwalList(), // Pastikan stream ini mengembalikan data yang benar
              builder: (context, snapshot) {
                print("[ListJadwalScreen] StreamBuilder: ConnectionState = ${snapshot.connectionState}");

                if (snapshot.hasError) {
                  print("------------------------------------------------------------");
                  print("[ListJadwalScreen] STREAMBUILDER ERROR DETECTED!");
                  print("Error: ${snapshot.error}");
                  print("StackTrace: ${snapshot.stackTrace}");
                  print("------------------------------------------------------------");
                  return Center(child: Text("Terjadi Error: ${snapshot.error.toString()}\nSilakan cek konsol debug untuk detail dan pastikan Firestore Index sudah dibuat jika diperlukan oleh query."));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  print("[ListJadwalScreen] StreamBuilder: Menunggu data...");
                  // Jangan update _allJadwal atau _filteredJadwal di sini
                  return const Center(child: CircularProgressIndicator());
                }

                // Hanya proses jika ada data dan tidak null
                if (snapshot.hasData && snapshot.data != null) {
                  print("[ListJadwalScreen] StreamBuilder: Data diterima dari stream, jumlah item mentah = ${snapshot.data!.length}");
                  // Update _allJadwal HANYA jika data dari stream berubah
                  // Ini penting untuk mencegah loop filter yang tidak perlu
                  if (_allJadwal != snapshot.data!) {
                    _allJadwal = snapshot.data!;
                    print("[ListJadwalScreen] _allJadwal diperbarui, jumlah item = ${_allJadwal.length}");
                    _filterJadwal(); // Selalu filter setelah _allJadwal diperbarui
                  }
                } else {
                  // Jika tidak ada data atau data null (misalnya stream error atau koleksi kosong)
                  print("[ListJadwalScreen] StreamBuilder: Tidak ada data (snapshot.hasData: ${snapshot.hasData}, snapshot.data: ${snapshot.data}).");
                  _allJadwal = []; // Kosongkan list jika tidak ada data
                  _filterJadwal(); // Filter akan menghasilkan list kosong
                  // Pesan akan ditampilkan di bawah berdasarkan kondisi _filteredJadwal.isEmpty
                }


                if (_filteredJadwal.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    print("[ListJadwalScreen] Tidak ada jadwal ditemukan untuk query '$_searchQuery'.");
                    return const Center(child: Text("Jadwal tidak ditemukan."));
                  } else if (_allJadwal.isEmpty && snapshot.connectionState == ConnectionState.active) {
                    // Kondisi ini berarti stream aktif, tidak ada query, tapi _allJadwal (data dari stream) memang kosong
                    print("[ListJadwalScreen] Belum ada data jadwal tersedia dari stream (dan tidak ada query).");
                    return const Center(child: Text("Belum ada data jadwal. Silakan tambahkan jadwal baru."));
                  } else if (snapshot.connectionState != ConnectionState.waiting) {
                    // Fallback jika _filteredJadwal kosong tapi bukan karena query atau stream kosong (misal, setelah delete terakhir)
                    // Atau jika stream awalnya punya data, lalu jadi kosong
                    print("[ListJadwalScreen] Tidak ada jadwal untuk ditampilkan (filtered kosong, bukan waiting, query mungkin kosong atau tidak).");
                    return const Center(child: Text("Tidak ada data jadwal tersedia saat ini."));
                  }
                  // Jika masih waiting, indicator sudah ditampilkan di atas.
                }

                print("[ListJadwalScreen] Membangun ListView dengan ${_filteredJadwal.length} item.");
                return ListView.builder(
                  itemCount: _filteredJadwal.length,
                  itemBuilder: (context, index) {
                    final jadwal = _filteredJadwal[index];
                    // print("[ListJadwalScreen] Membangun item untuk Jadwal ID: ${jadwal.id}, Nama Kereta: ${jadwal.namaKereta}"); // Bisa di-uncomment untuk debug item individual
                    String tanggalBerangkatFormatted = "N/A";
                    String jamTibaFormatted = "N/A";
                    String tanggalTibaFormattedSimple = "N/A";

                    try {
                      if (jadwal.tanggalBerangkatUtama != null) {
                        tanggalBerangkatFormatted = DateFormat('EEE, dd MMM yy HH:mm', 'id_ID').format(jadwal.tanggalBerangkatUtama.toDate());
                      }
                      if (jadwal.tanggalTibaUtama != null) {
                        jamTibaFormatted = DateFormat('HH:mm', 'id_ID').format(jadwal.tanggalTibaUtama.toDate());
                        tanggalTibaFormattedSimple = DateFormat('dd MMM', 'id_ID').format(jadwal.tanggalTibaUtama.toDate());
                      }
                    } catch (e, s) {
                      print("Error formatting date for jadwal ID ${jadwal.id}: $e");
                      print("StackTrace for date formatting error: $s");
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text("${jadwal.namaKereta} (${jadwal.idKereta})", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FormJadwalScreen(jadwalToEdit: jadwal),
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
                                      content: Text('Anda yakin ingin menghapus jadwal ${jadwal.namaKereta} (${jadwal.idStasiunAsal}-${jadwal.idStasiunTujuan})?'),
                                      actions: <Widget>[
                                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
                                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                      ],
                                    );
                                  },
                                );
                                if (confirm == true) {
                                  try {
                                    await _adminService.deleteJadwal(jadwal.id);
                                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jadwal ${jadwal.namaKereta} berhasil dihapus.')));
                                    // Data akan di-refresh oleh StreamBuilder, dan filter akan diterapkan
                                  } catch (e) {
                                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus jadwal: $e')));
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
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}