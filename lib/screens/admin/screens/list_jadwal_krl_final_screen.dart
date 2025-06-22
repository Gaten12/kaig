import 'package:flutter/material.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import 'package:kaig/screens/admin/screens/form_jadwal_krl_final_screen.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';

class ListJadwalKrlFinalScreen extends StatelessWidget {
  const ListJadwalKrlFinalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminFirestoreService firestoreService = AdminFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Jadwal KRL"),
      ),
      body: StreamBuilder<List<JadwalKrlModel>>(
        stream: firestoreService.getJadwalKrlList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada jadwal KRL yang ditambahkan."));
          }

          final jadwalList = snapshot.data!;
          // Urutkan berdasarkan nomor KA untuk tampilan yang lebih rapi
          jadwalList.sort((a, b) => a.nomorKa.compareTo(b.nomorKa));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: jadwalList.length,
            itemBuilder: (context, index) {
              final jadwal = jadwalList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      jadwal.nomorKa,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  title: Text(jadwal.relasi, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Hari: ${jadwal.tipeHari} - Harga: Rp ${jadwal.harga}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      // Tampilkan dialog konfirmasi sebelum menghapus
                      final bool? konfirmasiHapus = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi Hapus'),
                          content: Text('Apakah Anda yakin ingin menghapus jadwal KA ${jadwal.nomorKa} relasi ${jadwal.relasi}?'),
                          actions: [
                            TextButton(
                              child: const Text('Batal'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                      );

                      if (konfirmasiHapus == true) {
                        await firestoreService.deleteJadwalKrl(jadwal.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Jadwal berhasil dihapus.'))
                        );
                      }
                    },
                  ),
                  onTap: () {
                    // Navigasi ke form edit dengan membawa data jadwal yang dipilih
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormJadwalKrlFinalScreen(jadwal: jadwal),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke form untuk menambah jadwal baru
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormJadwalKrlFinalScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

