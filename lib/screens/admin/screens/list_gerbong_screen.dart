import 'package:flutter/material.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../services/admin_firestore_service.dart';
import 'form_gerbong_screen.dart';

class ListGerbongScreen extends StatelessWidget {
  const ListGerbongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminFirestoreService adminService = AdminFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Tipe Gerbong"),
      ),
      body: StreamBuilder<List<GerbongTipeModel>>(
        stream: adminService.getGerbongTipeList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data tipe gerbong."));
          }

          final gerbongList = snapshot.data!;
          return ListView.builder(
            itemCount: gerbongList.length,
            itemBuilder: (context, index) {
              final gerbong = gerbongList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.view_comfortable_outlined, size: 30),
                  title: Text(gerbong.namaTipeLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Layout: ${gerbong.tipeLayout.deskripsi}\nKapasitas: ${gerbong.jumlahKursi} kursi"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormGerbongScreen(gerbongToEdit: gerbong),
                        ),
                      );
                    },
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
            MaterialPageRoute(builder: (context) => const FormGerbongScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}