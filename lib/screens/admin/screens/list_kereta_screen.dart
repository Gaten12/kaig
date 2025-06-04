import 'package:flutter/material.dart';
import '../../../models/KeretaModel.dart';
import '../services/admin_firestore_service.dart';
import 'form_kereta_screen.dart';

class ListKeretaScreen extends StatefulWidget {
  const ListKeretaScreen({super.key});

  @override
  State<ListKeretaScreen> createState() => _ListKeretaScreenState();
}

class _ListKeretaScreenState extends State<ListKeretaScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Kereta"),
      ),
      body: StreamBuilder<List<KeretaModel>>(
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
            return const Center(child: Text("Belum ada data kereta."));
          }

          final keretaList = snapshot.data!;

          return ListView.builder(
            itemCount: keretaList.length,
            itemBuilder: (context, index) {
              final kereta = keretaList[index];
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