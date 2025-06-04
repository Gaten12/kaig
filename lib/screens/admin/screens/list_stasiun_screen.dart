import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Hanya untuk contoh jika ada error
import '../../../models/stasiun_model.dart';
import '../services/admin_firestore_service.dart';
import 'form_stasiun_screen.dart';

class ListStasiunScreen extends StatefulWidget {
  const ListStasiunScreen({super.key});

  @override
  State<ListStasiunScreen> createState() => _ListStasiunScreenState();
}

class _ListStasiunScreenState extends State<ListStasiunScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Stasiun"),
      ),
      body: StreamBuilder<List<StasiunModel>>(
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
            return const Center(child: Text("Belum ada data stasiun."));
          }

          final stasiunList = snapshot.data!;

          return ListView.builder(
            itemCount: stasiunList.length,
            itemBuilder: (context, index) {
              final stasiun = stasiunList[index];
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
                              // Jika ID adalah kode stasiun, gunakan stasiun.kode
                              // Jika ID adalah documentID, gunakan stasiun.id
                              // Asumsi stasiun.id adalah documentID yang benar
                              await _adminService.deleteStasiun(stasiun.id);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormStasiunScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
