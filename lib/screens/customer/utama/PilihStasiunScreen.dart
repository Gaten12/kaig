import 'package:flutter/material.dart';
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar
import '../../admin/services/admin_firestore_service.dart'; // Sesuaikan path jika perlu

class PilihStasiunScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const PilihStasiunScreen({super.key, this.initialSearchQuery});

  @override
  State<PilihStasiunScreen> createState() => _PilihStasiunScreenState();
}

class _PilihStasiunScreenState extends State<PilihStasiunScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AdminFirestoreService _firestoreService = AdminFirestoreService(); // Instance service

  List<StasiunModel> _semuaStasiunMaster = []; // Menyimpan semua stasiun dari Firestore
  List<StasiunModel> _hasilPencarian = [];
  List<StasiunModel> _stasiunFavorit = []; // Untuk sementara, masih dikelola lokal
  List<StasiunModel> _terakhirDicari = []; // Untuk sementara, masih dikelola lokal

  Stream<List<StasiunModel>>? _stasiunStream;

  @override
  void initState() {
    super.initState();
    _stasiunStream = _firestoreService.getStasiunList(); // Ambil stream stasiun

    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      // Filter akan dilakukan oleh listener atau saat data stream masuk
    }

    _searchController.addListener(() {
      // Filter dilakukan pada _semuaStasiunMaster saat data stream sudah ada
      _filterStasiunDariMaster(_searchController.text);
    });
  }

  // Memfilter dari data master yang sudah diambil dari stream
  void _filterStasiunDariMaster(String query) {
    if (!mounted) return;
    List<StasiunModel> filtered;
    if (query.isEmpty) {
      filtered = _semuaStasiunMaster;
    } else {
      final queryLower = query.toLowerCase();
      filtered = _semuaStasiunMaster.where((stasiun) {
        final namaLower = stasiun.nama.toLowerCase();
        final kodeLower = stasiun.kode.toLowerCase();
        final kotaLower = stasiun.kota.toLowerCase();
        final deskripsiLower = stasiun.deskripsiTambahan.toLowerCase();
        return namaLower.contains(queryLower) ||
            kodeLower.contains(queryLower) ||
            kotaLower.contains(queryLower) ||
            deskripsiLower.contains(queryLower);
      }).toList();
    }
    setState(() {
      _hasilPencarian = filtered;
    });
  }

  void _pilihStasiun(StasiunModel stasiun) {
    // TODO: Implementasi logika persisten untuk "Terakhir dicari"
    // Contoh sederhana (hanya di memori sesi ini):
    if (mounted) {
      setState(() {
        if (!_terakhirDicari.any((s) => s.id == stasiun.id)) {
          _terakhirDicari.insert(0, stasiun);
          if (_terakhirDicari.length > 5) _terakhirDicari.removeLast();
        }
      });
    }
    Navigator.pop(context, stasiun);
  }

  void _toggleFavorit(StasiunModel stasiun) {
    if (!mounted) return;
    setState(() {
      stasiun.isFavorit = !stasiun.isFavorit;
      if (stasiun.isFavorit) {
        if (!_stasiunFavorit.any((s) => s.id == stasiun.id)) {
          _stasiunFavorit.add(stasiun);
        }
      } else {
        _stasiunFavorit.removeWhere((s) => s.id == stasiun.id);
      }
      // TODO: Simpan status favorit ke penyimpanan persisten (Firestore user data atau SharedPreferences)
    });
    print("Stasiun ${stasiun.nama} favorit: ${stasiun.isFavorit}");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari stasiun atau kota...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
            suffixIcon: isSearching
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            )
                : null,
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 17),
        ),
      ),
      body: StreamBuilder<List<StasiunModel>>(
        stream: _stasiunStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error Stream Stasiun: ${snapshot.error}");
            return Center(child: Text("Error memuat stasiun: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada data stasiun."));
          }

          // Simpan data dari stream ke _semuaStasiunMaster untuk filtering
          // Hanya update jika data stream berbeda untuk menghindari loop setState
          if (_semuaStasiunMaster != snapshot.data!) { // Perbandingan referensi list
            _semuaStasiunMaster = snapshot.data!;
            // Panggil filter setelah _semuaStasiunMaster diupdate dengan data baru dari stream
            // Ini penting agar _hasilPencarian selalu berdasarkan data terbaru
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _filterStasiunDariMaster(_searchController.text);
            });
          }

          // Logika untuk "Difavoritkan" dan "Terakhir dicari" masih menggunakan list lokal
          // yang di-filter dari _semuaStasiunMaster atau diisi manual untuk contoh.
          // Untuk implementasi nyata, ini perlu data persisten.
          // Untuk sementara, kita filter dari _semuaStasiunMaster jika perlu.
          _stasiunFavorit = _semuaStasiunMaster.where((s) => s.isFavorit).toList();
          // _terakhirDicari di-manage oleh _pilihStasiun


          // Tampilkan UI berdasarkan _hasilPencarian (yang sudah di-filter)
          // dan section favorit/terakhir dicari
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSearching && _stasiunFavorit.isNotEmpty) ...[
                _buildSectionTitle("Difavoritkan"),
                _buildFavoritList(),
              ],
              if (!isSearching && _terakhirDicari.isNotEmpty) ...[
                _buildSectionTitle("Terakhir dicari"),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _terakhirDicari.length,
                  itemBuilder: (context, index) {
                    final stasiun = _terakhirDicari[index];
                    return _buildStasiunListItem(stasiun);
                  },
                ),
              ],

              if (_hasilPencarian.isNotEmpty || isSearching)
                _buildSectionTitle(isSearching ? "Hasil Pencarian" : "Semua Stasiun"),

              Expanded(
                child: _hasilPencarian.isEmpty
                    ? Center(child: Text(isSearching ? "Stasiun tidak ditemukan." : "Tidak ada data stasiun."))
                    : ListView.builder(
                  itemCount: _hasilPencarian.length,
                  itemBuilder: (context, index) {
                    final stasiun = _hasilPencarian[index];
                    if (!isSearching && _searchController.text.isEmpty) {
                      bool sudahAdaDiFavorit = _stasiunFavorit.any((s) => s.id == stasiun.id);
                      bool sudahAdaDiTerakhirDicari = _terakhirDicari.any((s) => s.id == stasiun.id);
                      if (sudahAdaDiFavorit || sudahAdaDiTerakhirDicari) {
                        return const SizedBox.shrink();
                      }
                    }
                    return _buildStasiunListItem(stasiun);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildFavoritList() {
    // Menggunakan _stasiunFavorit yang sudah di-filter dari _semuaStasiunMaster
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        itemCount: _stasiunFavorit.length,
        itemBuilder: (context, index) {
          final stasiun = _stasiunFavorit[index];
          return _buildFavoritCard(stasiun);
        },
      ),
    );
  }

  Widget _buildFavoritCard(StasiunModel stasiun) {
    return SizedBox(
      width: 160,
      child: Card(
        color: Colors.amber.shade50,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () => _pilihStasiun(stasiun),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stasiun.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  stasiun.displayArea,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStasiunListItem(StasiunModel stasiun) {
    return ListTile(
      title: Text(stasiun.displayName),
      subtitle: Text(stasiun.displayArea),
      trailing: IconButton(
        icon: Icon(
          stasiun.isFavorit ? Icons.star : Icons.star_border_outlined,
          color: stasiun.isFavorit ? Colors.amber.shade700 : Colors.grey,
        ),
        onPressed: () => _toggleFavorit(stasiun),
      ),
      onTap: () => _pilihStasiun(stasiun),
    );
  }
}
