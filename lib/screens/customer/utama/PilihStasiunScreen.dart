import 'package:flutter/material.dart';
import '../../../models/stasiun_model.dart';
import '../../admin/services/admin_firestore_service.dart';

class PilihStasiunScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const PilihStasiunScreen({super.key, this.initialSearchQuery});

  @override
  State<PilihStasiunScreen> createState() => _PilihStasiunScreenState();
}

class _PilihStasiunScreenState extends State<PilihStasiunScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<StasiunModel> _semuaStasiunMaster = [];
  List<StasiunModel> _hasilPencarian = [];
  List<StasiunModel> _stasiunFavorit = [];
  List<StasiunModel> _terakhirDicari = [];

  Stream<List<StasiunModel>>? _stasiunStream;

  // Tema Warna Kereta Elegan
  static const Color primaryRed = Color(0xFFC50000);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color lightRed = Color(0xFFFFEBEE);
  static const Color warmGray = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color cardShadow = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _fadeController.forward();

    _stasiunStream = _firestoreService.getStasiunList();

    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }

    _searchController.addListener(() {
      _filterStasiunDariMaster(_searchController.text);
    });
  }

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
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: warmGray,
      appBar: _buildElegantAppBar(isSearching),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<StasiunModel>>(
          stream: _stasiunStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            if (_semuaStasiunMaster != snapshot.data!) {
              _semuaStasiunMaster = snapshot.data!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _filterStasiunDariMaster(_searchController.text);
              });
            }

            _stasiunFavorit =
                _semuaStasiunMaster.where((s) => s.isFavorit).toList();

            return _buildMainContent(isSearching);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildElegantAppBar(bool isSearching) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: lightRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: primaryRed, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Container(
        height: 48,
        decoration: BoxDecoration(
          color: warmGray,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryRed.withOpacity(0.2), width: 1.5),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari stasiun atau kota...',
            hintStyle: TextStyle(color: textSecondary, fontSize: 16),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.search_rounded, color: primaryRed, size: 24),
            ),
            suffixIcon: isSearching
                ? Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () => _searchController.clear(),
                    ),
                  )
                : null,
          ),
          style: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildMainContent(bool isSearching) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSearching && _stasiunFavorit.isNotEmpty) ...[
            _buildSectionTitle("✨ Stasiun Favorit", Icons.star_rounded),
            const SizedBox(height: 8),
            _buildFavoritList(),
            const SizedBox(height: 24),
          ],
          if (!isSearching && _terakhirDicari.isNotEmpty) ...[
            _buildSectionTitle("🕒 Terakhir Dicari", Icons.history_rounded),
            const SizedBox(height: 8),
            _buildTerakhirDicariList(),
            const SizedBox(height: 24),
          ],
          if (_hasilPencarian.isNotEmpty || isSearching) ...[
            _buildSectionTitle(
                isSearching ? "🔍 Hasil Pencarian" : "🚉 Semua Stasiun",
                isSearching ? Icons.search_rounded : Icons.train_rounded),
            const SizedBox(height: 8),
            _buildStasiunList(isSearching),
          ] else if (!isSearching) ...[
            _buildSectionTitle("🚉 Semua Stasiun", Icons.train_rounded),
            const SizedBox(height: 8),
            _buildStasiunList(isSearching),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryRed.withOpacity(0.1), lightRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryRed.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryRed, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stasiunFavorit.length,
        itemBuilder: (context, index) {
          final stasiun = _stasiunFavorit[index];
          return _buildFavoritCard(stasiun);
        },
      ),
    );
  }

  Widget _buildTerakhirDicariList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _terakhirDicari.length,
        separatorBuilder: (context, index) =>
            Divider(color: warmGray, height: 1),
        itemBuilder: (context, index) {
          final stasiun = _terakhirDicari[index];
          return _buildStasiunListItem(stasiun, showTrailing: false);
        },
      ),
    );
  }

  Widget _buildFavoritCard(StasiunModel stasiun) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shadowColor: cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, lightRed.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: primaryRed.withOpacity(0.2), width: 1),
          ),
          child: InkWell(
            onTap: () => _pilihStasiun(stasiun),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stasiun.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stasiun.displayArea,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stasiun.kode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStasiunList(bool isSearching) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: _hasilPencarian.isEmpty
          ? Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    isSearching
                        ? Icons.search_off_rounded
                        : Icons.train_outlined,
                    size: 64,
                    color: textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSearching
                        ? "Stasiun tidak ditemukan"
                        : "Tidak ada data stasiun",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSearching
                        ? "Coba kata kunci lain"
                        : "Silakan coba lagi nanti",
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hasilPencarian.length,
              separatorBuilder: (context, index) =>
                  Divider(color: warmGray, height: 1),
              itemBuilder: (context, index) {
                final stasiun = _hasilPencarian[index];
                if (!isSearching && _searchController.text.isEmpty) {
                  bool sudahAdaDiFavorit =
                      _stasiunFavorit.any((s) => s.id == stasiun.id);
                  bool sudahAdaDiTerakhirDicari =
                      _terakhirDicari.any((s) => s.id == stasiun.id);
                  if (sudahAdaDiFavorit || sudahAdaDiTerakhirDicari) {
                    return const SizedBox.shrink();
                  }
                }
                return _buildStasiunListItem(stasiun);
              },
            ),
    );
  }

  Widget _buildStasiunListItem(StasiunModel stasiun,
      {bool showTrailing = true}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryRed.withOpacity(0.1), lightRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryRed.withOpacity(0.3), width: 1),
        ),
        child: const Icon(Icons.train_rounded, color: primaryRed, size: 24),
      ),
      title: Text(
        stasiun.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            stasiun.displayArea,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stasiun.kode,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryRed,
              ),
            ),
          ),
        ],
      ),
      trailing: showTrailing
          ? Container(
              decoration: BoxDecoration(
                color: stasiun.isFavorit
                    ? Colors.amber.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  stasiun.isFavorit
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: stasiun.isFavorit ? Colors.amber : Colors.grey,
                  size: 28,
                ),
                onPressed: () => _toggleFavorit(stasiun),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.access_time_rounded,
                  color: accentBlue, size: 20),
            ),
      onTap: () => _pilihStasiun(stasiun),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lightRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
                color: primaryRed, strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text(
            "Memuat stasiun...",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              "Terjadi Kesalahan",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "Error: $error",
              style: TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Coba Lagi",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.train_outlined, size: 64, color: textSecondary),
            const SizedBox(height: 16),
            const Text(
              "Belum Ada Data Stasiun",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "Data stasiun belum tersedia saat ini",
              style: TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
