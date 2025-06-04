import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Jadwal Kereta"),
      ),
      body: StreamBuilder<List<JadwalModel>>(
        stream: _adminService.getJadwalList(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error Stream Jadwal: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data jadwal."));
          }

          final jadwalList = snapshot.data!;

          return ListView.builder(
            itemCount: jadwalList.length,
            itemBuilder: (context, index) {
              final jadwal = jadwalList[index];
              String tanggalBerangkatFormatted = DateFormat('EEE, dd MMM yyyy HH:mm', 'id_ID').format(jadwal.tanggalBerangkat.toDate());
              String jamTibaFormatted = DateFormat('HH:mm', 'id_ID').format(jadwal.jamTiba.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: ListTile(
                  title: Text("${jadwal.namaKereta} (${jadwal.idKereta})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Rute: ${jadwal.idStasiunAsal} ❯ ${jadwal.idStasiunTujuan}\n"
                        "Berangkat: $tanggalBerangkatFormatted\n"
                        "Tiba: $jamTibaFormatted (${DateFormat('dd MMM', 'id_ID').format(jadwal.jamTiba.toDate())})\n"
                        "Kelas Tersedia: ${jadwal.daftarKelasHarga.length} jenis",
                  ),
                  isThreeLine: true, // Mungkin perlu true jika subtitle panjang
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
                            builder: (BuildContext context) { /* ... Dialog konfirmasi hapus ... */
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