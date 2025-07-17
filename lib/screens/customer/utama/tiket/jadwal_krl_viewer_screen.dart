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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUniqueRelasi();
  }

  Future<void> _fetchUniqueRelasi() async {
    setState(() { _isLoading = true; });
    try {
      final jadwalList = await _firestoreService.getJadwalKrlList().first;
      if (mounted) {
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Jadwal KRL Commuter Line",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filter Pilihan Rute
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedRelasi,
              decoration: InputDecoration(
                labelText: "Pilih Rute Perjalanan",
                prefixIcon: const Icon(Icons.route_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _uniqueRelasi.map((relasi) => DropdownMenuItem(value: relasi, child: Text(relasi))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRelasi = value;
                });
              },
            ),
          ),

          // Tampilan Jadwal
          Expanded(
            child: _selectedRelasi == null
                ? const Center(child: Text("Silakan pilih rute untuk melihat jadwal."))
                : StreamBuilder<List<JadwalKrlModel>>(
              stream: _firestoreService.getJadwalKrlList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada jadwal tersedia."));
                }

                // 1. Filter jadwal berdasarkan relasi yang dipilih
                final jadwalList = snapshot.data!.where((j) => j.relasi == _selectedRelasi).toList();

                if (jadwalList.isEmpty) {
                  return const Center(child: Text("Tidak ada jadwal untuk rute ini."));
                }

                // 2. Urutkan berdasarkan jam berangkat stasiun pertama
                jadwalList.sort((a,b) {
                  final jamA = a.perhentian.isNotEmpty ? a.perhentian.first.jamBerangkat ?? "99:99" : "99:99";
                  final jamB = b.perhentian.isNotEmpty ? b.perhentian.first.jamBerangkat ?? "99:99" : "99:99";
                  return jamA.compareTo(jamB);
                });

                // 3. Bangun daftar
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jadwalList.length,
                  itemBuilder: (context, index) {
                    final jadwal = jadwalList[index];
                    return _buildJadwalCard(context, jadwal);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk membangun kartu jadwal yang informatif.
  Widget _buildJadwalCard(BuildContext context, JadwalKrlModel jadwal) {
    final perhentian = jadwal.perhentian;
    final bool isWeekend = jadwal.tipeHari == 'Weekend';

    String stasiunAwal = perhentian.isNotEmpty ? perhentian.first.namaStasiun : 'N/A';
    String jamBerangkat = perhentian.isNotEmpty ? perhentian.first.jamBerangkat ?? '--:--' : '--:--';
    String stasiunAkhir = perhentian.length > 1 ? perhentian.last.namaStasiun : 'N/A';
    String jamTiba = perhentian.length > 1 ? perhentian.last.jamDatang ?? '--:--' : '--:--';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isWeekend ? Colors.orange.shade200 : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "KA ${jadwal.nomorKa}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (isWeekend)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Weekend",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildTimeColumn(context, Icons.departure_board, jamBerangkat, stasiunAwal),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20),
                ),
                _buildTimeColumn(context, Icons.departure_board, jamTiba, stasiunAkhir),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showStopsDialog(context, jadwal),
                child: const Text("Lihat Perhentian"),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Helper untuk membangun kolom waktu (Berangkat/Tiba).
  Widget _buildTimeColumn(BuildContext context, IconData icon, String time, String station) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  station,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog bottom sheet dengan daftar lengkap perhentian.
  void _showStopsDialog(BuildContext context, JadwalKrlModel jadwal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Rute Perhentian KA ${jadwal.nomorKa}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Table(
                          border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          children: [
                            const TableRow(
                                children: [
                                  Padding(padding: EdgeInsets.all(8.0), child: Text("Stasiun", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(8.0), child: Text("Tiba", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(8.0), child: Text("Berangkat", style: TextStyle(fontWeight: FontWeight.bold))),
                                ]
                            ),
                            ...jadwal.perhentian.map((p) => TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(p.namaStasiun)),
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(p.jamDatang ?? "-")),
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(p.jamBerangkat ?? "-")),
                                ]
                            )).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
