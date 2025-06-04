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

  @override
  Widget build(BuildContext context) {
    print("[ListJadwalScreen] Build method dipanggil.");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Jadwal Kereta"),
      ),
      body: StreamBuilder<List<JadwalModel>>(
        stream: _adminService.getJadwalList(),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            print("[ListJadwalScreen] StreamBuilder: Tidak ada data (snapshot.hasData: ${snapshot.hasData}, snapshot.data: ${snapshot.data}). Ini bisa berarti koleksi kosong atau masalah pada query/model/rules/index.");
            return const Center(child: Text("Tidak ada data jadwal tersedia saat ini."));
          }

          final jadwalList = snapshot.data!;
          print("[ListJadwalScreen] StreamBuilder: Data diterima, jumlah item = ${jadwalList.length}");

          if (jadwalList.isEmpty) {
            print("[ListJadwalScreen] StreamBuilder: Daftar jadwal kosong. Pastikan ada data di Firestore, filter query (jika ada) sudah benar, dan indeks Firestore sudah dibuat untuk query orderBy.");
            return const Center(child: Text("Belum ada data jadwal. Silakan tambahkan jadwal baru."));
          }

          return ListView.builder(
            itemCount: jadwalList.length,
            itemBuilder: (context, index) {
              final jadwal = jadwalList[index];
              print("[ListJadwalScreen] Membangun item untuk Jadwal ID: ${jadwal.id}, Nama Kereta: ${jadwal.namaKereta}");
              String tanggalBerangkatFormatted = "N/A";
              String jamTibaFormatted = "N/A";
              String tanggalTibaFormattedSimple = "N/A";

              try {
                // Menggunakan getter baru dari JadwalModel
                if (jadwal.tanggalBerangkatUtama != null) {
                  tanggalBerangkatFormatted = DateFormat('EEE, dd MMM yy HH:mm', 'id_ID').format(jadwal.tanggalBerangkatUtama.toDate());
                } else {
                  print("[ListJadwalScreen] Peringatan: jadwal.tanggalBerangkatUtama null untuk ID ${jadwal.id}");
                }
                if (jadwal.tanggalTibaUtama != null) { // Menggunakan getter tanggalTibaUtama
                  jamTibaFormatted = DateFormat('HH:mm', 'id_ID').format(jadwal.tanggalTibaUtama.toDate());
                  tanggalTibaFormattedSimple = DateFormat('dd MMM', 'id_ID').format(jadwal.tanggalTibaUtama.toDate());
                } else {
                  print("[ListJadwalScreen] Peringatan: jadwal.tanggalTibaUtama null untuk ID ${jadwal.id}");
                }

              } catch (e, s) { // Menangkap error dan stack trace
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
