// lib/src/pembelian_tiket/screens/pilih_stasiun_screen.dart (buat file baru)
import 'package:flutter/material.dart';
import '../../models/stasiun_model.dart'; // Impor model stasiun

class PilihStasiunScreen extends StatefulWidget {
  final String? initialSearchQuery; // Opsional, jika ingin membawa query dari layar sebelumnya

  const PilihStasiunScreen({super.key, this.initialSearchQuery});

  @override
  State<PilihStasiunScreen> createState() => _PilihStasiunScreenState();
}

class _PilihStasiunScreenState extends State<PilihStasiunScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StasiunModel> _semuaStasiun = [];
  List<StasiunModel> _hasilPencarian = [];
  List<StasiunModel> _stasiunFavorit = [];
  List<StasiunModel> _terakhirDicari = []; // Untuk kesederhanaan, kita isi manual dulu

  @override
  void initState() {
    super.initState();
    _loadStasiunDummy();
    _hasilPencarian = _semuaStasiun; // Awalnya tampilkan semua
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
      _filterStasiun(widget.initialSearchQuery!);
    }
    _searchController.addListener(() {
      _filterStasiun(_searchController.text);
    });
  }

  void _loadStasiunDummy() {
    // Nantinya data ini dari Firestore atau API
    _semuaStasiun = [
      StasiunModel(id: "1", nama: "BANDUNG", kode: "BD", kota: "BANDUNG", isFavorit: true),
      StasiunModel(id: "2", nama: "CIPEUNDEUY", kode: "CPD", kota: "KABUPATEN GARUT", isFavorit: true),
      StasiunModel(id: "3", nama: "KOTA SOLO", kode: "SLO", kota: "KOTA SOLO", deskripsiTambahan: "SEMUA STASIUN DI KOTA SOLO", isFavorit: true),
      StasiunModel(id: "4", nama: "KOTA YOGYAKARTA", kode: "YK", kota: "KOTA YOGYAKARTA", deskripsiTambahan: "SEMUA STASIUN DI KOTA YOGYAKARTA", isFavorit: true),
      StasiunModel(id: "5", nama: "BANJAR", kode: "BJR", kota: "KOTA BANJAR"),
      StasiunModel(id: "6", nama: "KROYA", kode: "KYA", kota: "KABUPATEN CILACAP"),
      StasiunModel(id: "7", nama: "KOTA TASIKMALAYA", kode: "TSM", kota: "KOTA TASIKMALAYA", deskripsiTambahan: "SEMUA STASIUN DI KOTA TASIKMALAYA"),
      StasiunModel(id: "8", nama: "GAMBIR", kode: "GMR", kota: "JAKARTA PUSAT"),
      StasiunModel(id: "9", nama: "PASAR SENEN", kode: "PSE", kota: "JAKARTA PUSAT"),
      StasiunModel(id: "10", nama: "SURABAYA GUBENG", kode: "SGU", kota: "SURABAYA"),
      StasiunModel(id: "11", nama: "SURABAYA PASAR TURI", kode: "SBI", kota: "SURABAYA"),
      StasiunModel(id: "12", nama: "MALANG", kode: "ML", kota: "MALANG"),
    ];

    _stasiunFavorit = _semuaStasiun.where((s) => s.isFavorit && (s.nama == "BANDUNG" || s.nama == "CIPEUNDEUY")).toList(); // Contoh favorit
    _terakhirDicari = _semuaStasiun.where((s) => s.id == "1" || s.id == "2" || s.id == "3" || s.id == "4").toList(); // Contoh terakhir dicari

    // Awalnya, hasil pencarian adalah semua stasiun jika tidak ada filter dari search bar
    _filterStasiun(_searchController.text);
  }

  void _filterStasiun(String query) {
    if (query.isEmpty) {
      // Jika query kosong, tampilkan favorit dan terakhir dicari, lalu sisanya.
      // Untuk simplisitas, kita tampilkan semua dulu jika tidak ada query.
      // Atau kita bisa build UI yang lebih kompleks sesuai screenshot.
      // Untuk saat ini, kita gabungkan dulu.
      setState(() {
        _hasilPencarian = _semuaStasiun;
      });
      return;
    }
    List<StasiunModel> filtered = _semuaStasiun.where((stasiun) {
      final namaLower = stasiun.nama.toLowerCase();
      final kodeLower = stasiun.kode.toLowerCase();
      final kotaLower = stasiun.kota.toLowerCase();
      final queryLower = query.toLowerCase();
      return namaLower.contains(queryLower) ||
          kodeLower.contains(queryLower) ||
          kotaLower.contains(queryLower);
    }).toList();
    setState(() {
      _hasilPencarian = filtered;
    });
  }

  void _pilihStasiun(StasiunModel stasiun) {
    // TODO: Tambahkan logika untuk 'Terakhir dicari' jika perlu
    Navigator.pop(context, stasiun); // Kembalikan stasiun yang dipilih
  }

  void _toggleFavorit(StasiunModel stasiun) {
    setState(() {
      stasiun.isFavorit = !stasiun.isFavorit;
      // Update juga di _stasiunFavorit dan _terakhirDicari jika stasiun ada di sana
      // Untuk data dummy, ini cukup. Untuk data asli, perlu update ke DB.
      if (stasiun.isFavorit && !_stasiunFavorit.any((s) => s.id == stasiun.id)) {
        _stasiunFavorit.add(stasiun);
      } else if (!stasiun.isFavorit) {
        _stasiunFavorit.removeWhere((s) => s.id == stasiun.id);
      }
      // Refresh hasil pencarian agar status bintang terupdate
      _filterStasiun(_searchController.text);
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
        titleSpacing: 0, // Menghilangkan spasi default sebelum title
        title: TextField(
          controller: _searchController,
          autofocus: true, // Langsung fokus ke search bar
          decoration: InputDecoration(
            hintText: 'Cari stasiun atau kota...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            )
                : null,
          ),
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 17),
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
          ],
          // Jika sedang mencari, atau tidak ada favorit/terakhir dicari, langsung tampilkan hasil
          // Atau tampilkan semua jika tidak ada query di _filterStasiun
          Expanded(
            child: ListView.builder(
              itemCount: _hasilPencarian.length,
              itemBuilder: (context, index) {
                final stasiun = _hasilPencarian[index];
                // Jangan tampilkan lagi jika sudah ada di "Terakhir dicari" & tidak sedang search
                if (!isSearching && _terakhirDicari.any((s) => s.id == stasiun.id) && !_stasiunFavorit.any((s)=> s.id == stasiun.id)) {
                  // Jika item ini adalah bagian dari _terakhirDicari dan tidak di favorit, tampilkan di sectionnya
                  if (_terakhirDicari.indexOf(stasiun) == index && index < _terakhirDicari.length) {
                    // this logic for displaying "Terakhir Dicari" needs refinement to avoid duplicates.
                    // For now, we simplify by just showing all search results or specific sections if not searching.
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
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildFavoritList() {
    return SizedBox(
      height: 100, // Sesuaikan tinggi
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
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
      width: 150, // Lebar kartu favorit
      child: Card(
        color: Colors.yellow.shade100,
        margin: const EdgeInsets.only(right: 8.0, bottom: 8.0, top: 4.0),
        child: InkWell(
          onTap: () => _pilihStasiun(stasiun),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          stasiun.isFavorit ? Icons.star : Icons.star_border,
          color: stasiun.isFavorit ? Colors.amber.shade700 : Colors.grey,
        ),
        onPressed: () => _toggleFavorit(stasiun),
      ),
      onTap: () => _pilihStasiun(stasiun),
    );
  }
}