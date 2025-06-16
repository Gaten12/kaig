import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/passenger_model.dart';
import '../services/auth_service.dart';
import '../screens/customer/utama/tiket/form_penumpang_screen.dart';

class PilihPenumpangBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  // Parameter ini menerima daftar penumpang yang sudah dipilih di form sebelumnya
  // agar tidak bisa dipilih lagi.
  final List<PassengerModel> penumpangSudahDipilih;

  const PilihPenumpangBottomSheet({
    super.key,
    required this.scrollController,
    required this.penumpangSudahDipilih, // Pastikan parameter ini ada
  });

  @override
  State<PilihPenumpangBottomSheet> createState() => _PilihPenumpangBottomSheetState();
}

class _PilihPenumpangBottomSheetState extends State<PilihPenumpangBottomSheet> {
  final AuthService _authService = AuthService();
  Stream<List<PassengerModel>>? _penumpangTersimpanStream;
  PassengerModel? _primaryPassenger;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _penumpangTersimpanStream = _authService.getSavedPassengers(user.uid);
      _loadPrimaryPassenger(user.uid);
    }
  }

  Future<void> _loadPrimaryPassenger(String uid) async {
    final passenger = await _authService.getPrimaryPassenger(uid);
    if(mounted) setState(() => _primaryPassenger = passenger);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Informasi Penumpang",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Tambah Penumpang Baru"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                // Tutup bottom sheet dulu, lalu buka FormPenumpangScreen
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormPenumpangScreen()),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text("atau, pilih dari daftar penumpang tersimpan", style: TextStyle(color: Colors.grey)),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<PassengerModel>>(
              stream: _penumpangTersimpanStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting && _primaryPassenger == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final penumpangLain = snapshot.data ?? [];

                List<PassengerModel> semuaPenumpang = [];
                if (_primaryPassenger != null) {
                  semuaPenumpang.add(_primaryPassenger!);
                }
                semuaPenumpang.addAll(penumpangLain);

                if (semuaPenumpang.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Tidak ada penumpang tersimpan.", style: TextStyle(color: Colors.grey)),
                  ));
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: semuaPenumpang.length,
                  itemBuilder: (context, index) {
                    final penumpang = semuaPenumpang[index];
                    // Cek apakah penumpang ini sudah dipilih di form pemesanan
                    final bool isAlreadySelected = widget.penumpangSudahDipilih
                        .any((p) => p.id == penumpang.id);

                    return ListTile(
                      enabled: !isAlreadySelected,
                      leading: CircleAvatar(
                        backgroundColor: isAlreadySelected ? Colors.grey.shade300 : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        child: Text(penumpang.namaLengkap.isNotEmpty ? penumpang.namaLengkap[0].toUpperCase() : "?"),
                      ),
                      title: Text(
                          penumpang.namaLengkap,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isAlreadySelected ? Colors.grey : Colors.black87
                          )
                      ),
                      subtitle: Text(
                        "${penumpang.tipeId} - ${penumpang.nomorId}",
                        style: TextStyle(color: isAlreadySelected ? Colors.grey : Colors.black54),
                      ),
                      trailing: penumpang.isPrimary == true ? Icon(Icons.star, color: Colors.amber.shade600, size: 20) : null,
                      onTap: isAlreadySelected ? null : () {
                        // Kembalikan PassengerModel yang dipilih
                        Navigator.pop(context, penumpang);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
