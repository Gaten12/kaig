import 'package:flutter/material.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';

class JadwalKrlViewerScreen extends StatefulWidget {
  const JadwalKrlViewerScreen({super.key});

  @override
  _JadwalKrlViewerScreenState createState() => _JadwalKrlViewerScreenState();
}

class _JadwalKrlViewerScreenState extends State<JadwalKrlViewerScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  List<String> _uniqueRelasi = [];
  String? _selectedRelasi;
  String _selectedTipeHari = 'Weekday';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUniqueRelasi();
  }

  // Mengambil semua jadwal sekali untuk mendapatkan daftar relasi yang unik
  Future<void> _fetchUniqueRelasi() async {
    setState(() { _isLoading = true; });
    try {
      final jadwalList = await _firestoreService.getJadwalKrlList().first;
      if (mounted) {
        // Ambil semua nilai 'relasi' dan buat menjadi list yang unik
        final allRelasi = jadwalList.map((j) => j.relasi).toSet().toList();
        setState(() {
          _uniqueRelasi = allRelasi;
          if (_uniqueRelasi.isNotEmpty) {
            _selectedRelasi = _uniqueRelasi.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat data relasi: $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal KRL Commuter Line"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Pilihan
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRelasi,
                    decoration: const InputDecoration(labelText: "Pilih Relasi", border: OutlineInputBorder()),
                    items: _uniqueRelasi.map((relasi) => DropdownMenuItem(value: relasi, child: Text(relasi))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRelasi = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTipeHari,
                    decoration: const InputDecoration(labelText: "Tipe Hari", border: OutlineInputBorder()),
                    items: ['Weekday', 'Weekend'].map((hari) => DropdownMenuItem(value: hari, child: Text(hari))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTipeHari = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tampilan Jadwal
            Expanded(
              child: _selectedRelasi == null
                  ? const Center(child: Text("Silakan pilih relasi untuk melihat jadwal."))
                  : StreamBuilder<List<JadwalKrlModel>>(
                // Gunakan stream yang sudah ada dan filter di client
                stream: _firestoreService.getJadwalKrlList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Tidak ada jadwal tersedia."));
                  }

                  // Filter jadwal berdasarkan relasi dan tipe hari yang dipilih
                  final jadwalList = snapshot.data!.where((j) =>
                  j.relasi == _selectedRelasi && j.tipeHari == _selectedTipeHari
                  ).toList();

                  if (jadwalList.isEmpty) {
                    return const Center(child: Text("Tidak ada jadwal untuk pilihan ini."));
                  }

                  // Urutkan berdasarkan jam berangkat stasiun pertama
                  jadwalList.sort((a,b) {
                    final jamA = a.perhentian.first.jamBerangkat ?? "99:99";
                    final jamB = b.perhentian.first.jamBerangkat ?? "99:99";
                    return jamA.compareTo(jamB);
                  });

                  return ListView.builder(
                    itemCount: jadwalList.length,
                    itemBuilder: (context, index) {
                      final jadwal = jadwalList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(child: Text(jadwal.nomorKa, style: const TextStyle(fontSize: 10))),
                          title: Text("KA ${jadwal.nomorKa} | ${jadwal.relasi}"),
                          subtitle: Text("Berangkat Awal: ${jadwal.perhentian.first.jamBerangkat ?? '-'}"),
                          children: [
                            // Tampilkan detail perhentian di dalam ExpansionTile
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Table(
                                border: TableBorder.all(color: Colors.grey.shade300),
                                columnWidths: const {
                                  0: FlexColumnWidth(3),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                },
                                children: [
                                  const TableRow(
                                      decoration: BoxDecoration(color: Colors.black12),
                                      children: [
                                        Padding(padding: EdgeInsets.all(8.0), child: Text("Stasiun", style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(8.0), child: Text("Datang", style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(8.0), child: Text("Berangkat", style: TextStyle(fontWeight: FontWeight.bold))),
                                      ]
                                  ),
                                  // Map setiap perhentian ke dalam baris tabel
                                  ...jadwal.perhentian.map((p) => TableRow(
                                      children: [
                                        Padding(padding: const EdgeInsets.all(8.0), child: Text(p.namaStasiun)),
                                        Padding(padding: const EdgeInsets.all(8.0), child: Text(p.jamDatang ?? "-")),
                                        Padding(padding: const EdgeInsets.all(8.0), child: Text(p.jamBerangkat ?? "-")),
                                      ]
                                  )).toList(),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
