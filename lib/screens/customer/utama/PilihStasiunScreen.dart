import 'package:flutter/material.dart';
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar

class PilihStasiunScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const PilihStasiunScreen({super.key, this.initialSearchQuery});

  @override
  State<PilihStasiunScreen> createState() => _PilihStasiunScreenState();
}

class _PilihStasiunScreenState extends State<PilihStasiunScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StasiunModel> _semuaStasiun = [];
  List<StasiunModel> _hasilPencarian = [];
  List<StasiunModel> _stasiunFavorit = [];
  List<StasiunModel> _terakhirDicari = [];

  @override
  void initState() {
    super.initState();
    _loadStasiunDummy(); // Memuat data stasiun (dummy atau dari sumber data)

    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      _filterStasiun(widget.initialSearchQuery!);
    } else {
      // Jika tidak ada query awal, _filterStasiun akan menangani _hasilPencarian
      _filterStasiun('');
    }

    _searchController.addListener(() {
      _filterStasiun(_searchController.text);
    });
  }

  void _loadStasiunDummy() {
    // Nantinya data ini idealnya dari Firestore atau API
    // Pastikan StasiunModel memiliki parameter 'isFavorit' dan 'deskripsiTambahan' di konstruktornya
    _semuaStasiun = [
      StasiunModel(id: "1", nama: "BANDUNG", kode: "BD", kota: "BANDUNG", isFavorit: true),
      StasiunModel(id: "2", nama: "CIPEUNDEUY", kode: "CPD", kota: "KABUPATEN GARUT", isFavorit: true),
      StasiunModel(id: "3", nama: "KOTA SOLO", kode: "SLO", kota: "KOTA SOLO", deskripsiTambahan: "SEMUA STASIUN DI KOTA SOLO", isFavorit: true),
      StasiunModel(id: "4", nama: "KOTA YOGYAKARTA", kode: "YK", kota: "KOTA YOGYAKARTA", deskripsiTambahan: "SEMUA STASIUN DI KOTA YOGYAKARTA", isFavorit: true),
      StasiunModel(id: "5", nama: "BANJAR", kode: "BJR", kota: "KOTA BANJAR"),
      StasiunModel(id: "6", nama: "KROYA", kode: "KYA", kota: "KABUPATEN CILACAP"),
      StasiunModel(id: "7", nama: "KOTA TASIKMALAYA", kode: "TSM", kota: "KOTA TASIKMALAYA", deskripsiTambahan: "SEMUA STASIUN DI KOTA TASIKMALAYA"),
      StasiunModel(id: "8", nama: "GAMBIR", kode: "GMR", kota: "JAKARTA PUSAT", isFavorit: true), // Menambahkan isFavorit
      StasiunModel(id: "9", nama: "PASAR SENEN", kode: "PSE", kota: "JAKARTA PUSAT"),
      StasiunModel(id: "10", nama: "SURABAYA GUBENG", kode: "SGU", kota: "SURABAYA"),
      StasiunModel(id: "11", nama: "SURABAYA PASAR TURI", kode: "SBI", kota: "SURABAYA"),
      StasiunModel(id: "12", nama: "MALANG", kode: "ML", kota: "MALANG"),
    ];

    _stasiunFavorit = _semuaStasiun.where((s) => s.isFavorit).toList();
    _terakhirDicari = _semuaStasiun.where((s) => s.id == "1" || s.id == "3" || s.id == "8").toList();

    _filterStasiun(_searchController.text); // Panggil setelah semua list diinisialisasi
  }

  void _filterStasiun(String query) {
    List<StasiunModel> filtered;
    if (query.isEmpty) {
      filtered = _semuaStasiun;
    } else {
      final queryLower = query.toLowerCase();
      filtered = _semuaStasiun.where((stasiun) {
        final namaLower = stasiun.nama.toLowerCase();
        final kodeLower = stasiun.kode.toLowerCase();
        final kotaLower = stasiun.kota.toLowerCase();
        // Pastikan stasiun.deskripsiTambahan ada di StasiunModel Anda
        final deskripsiLower = stasiun.deskripsiTambahan.toLowerCase();
        return namaLower.contains(queryLower) ||
            kodeLower.contains(queryLower) ||
            kotaLower.contains(queryLower) ||
            deskripsiLower.contains(queryLower);
      }).toList();
    }
    if (mounted) {
      setState(() {
        _hasilPencarian = filtered;
      });
    }
  }

  void _pilihStasiun(StasiunModel stasiun) {
    Navigator.pop(context, stasiun);
  }

  void _toggleFavorit(StasiunModel stasiun) {
    if (!mounted) return;
    setState(() {
      stasiun.isFavorit = !stasiun.isFavorit; // Membutuhkan field 'isFavorit' di StasiunModel
      if (stasiun.isFavorit) {
        if (!_stasiunFavorit.any((s) => s.id == stasiun.id)) {
          _stasiunFavorit.add(stasiun);
        }
      } else {
        _stasiunFavorit.removeWhere((s) => s.id == stasiun.id);
      }
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
      body: Column(
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
                        stasiun.displayName, // Membutuhkan getter 'displayName' di StasiunModel
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  stasiun.displayArea, // Membutuhkan getter 'displayArea' di StasiunModel
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
      title: Text(stasiun.displayName), // Membutuhkan getter 'displayName' di StasiunModel
      subtitle: Text(stasiun.displayArea), // Membutuhkan getter 'displayArea' di StasiunModel
      trailing: IconButton(
        icon: Icon(
          stasiun.isFavorit ? Icons.star : Icons.star_border_outlined, // Membutuhkan field 'isFavorit'
          color: stasiun.isFavorit ? Colors.amber.shade700 : Colors.grey,
        ),
        onPressed: () => _toggleFavorit(stasiun),
      ),
      onTap: () => _pilihStasiun(stasiun),
    );
  }
}