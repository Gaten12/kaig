import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar
import '../services/admin_firestore_service.dart'; // Pastikan path ini benar
import 'form_stasiun_screen.dart'; // Pastikan path ini benar

class ListStasiunScreen extends StatefulWidget {
  const ListStasiunScreen({super.key});

  @override
  State<ListStasiunScreen> createState() => _ListStasiunScreenState();
}

class _ListStasiunScreenState extends State<ListStasiunScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  String _searchQuery = "";
  List<StasiunModel> _allStasiun = [];
  List<StasiunModel> _filteredStasiun = [];

  final TextEditingController _searchController = TextEditingController();

  // Color Scheme - Charcoal Gray + Electric Blue
  static const Color _charcoalGray = Color(0xFF374151);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _electricBlue = Color(0xFF3B82F6);
  static const Color _lightGray = Color(0xFFF9FAFB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterStasiun();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStasiun() {
    if (_searchQuery.isEmpty) {
      _filteredStasiun = List.from(_allStasiun);
    } else {
      _filteredStasiun = _allStasiun.where((stasiun) {
        final displayNameLower = stasiun.displayName.toLowerCase();
        final kotaLower = stasiun.kota.toLowerCase();
        final searchQueryLower = _searchQuery.toLowerCase();
        return displayNameLower.contains(searchQueryLower) ||
            kotaLower.contains(searchQueryLower);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: _charcoalGray,
        title: const Text(
          "Daftar Stasiun",
          style: TextStyle(
            color: _pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: _pureWhite),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_electricBlue, Colors.blue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Header dengan search section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _pureWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _electricBlue.withAlpha((255 * 0.1).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Pencarian Stasiun",
                      hintText: "Cari berdasarkan nama atau kota...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search_rounded, color: _electricBlue),
                      filled: true,
                      fillColor: _pureWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _electricBlue, width: 2),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.grey.shade600),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Enhanced List Section
          Expanded(
            child: StreamBuilder<List<StasiunModel>>(
              stream: _adminService.getStasiunList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Error Stream Stasiun: ${snapshot.error}");
                  return _buildErrorState("Error: ${snapshot.error}");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _allStasiun = [];
                  _filterStasiun();
                  return _buildEmptyState("Belum ada data stasiun.");
                }

                if (_allStasiun != snapshot.data!) {
                  _allStasiun = snapshot.data!;
                  _filterStasiun();
                }

                if (_filteredStasiun.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildEmptyState("Stasiun tidak ditemukan.");
                }
                if (_filteredStasiun.isEmpty && _allStasiun.isEmpty) {
                  return _buildEmptyState("Belum ada data stasiun.");
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredStasiun.length,
                  itemBuilder: (context, index) {
                    final stasiun = _filteredStasiun[index];
                    return _buildStasiunCard(stasiun, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildStasiunCard(StasiunModel stasiun, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor.withAlpha((255 * 0.5).round())),
        boxShadow: [
          BoxShadow(
            color: _charcoalGray.withAlpha((255 * 0.06).round()),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dengan gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _electricBlue.withAlpha((255 * 0.05).round()),
                  _electricBlue.withAlpha((255 * 0.02).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_electricBlue, _electricBlue.withAlpha((255 * 0.8).round())],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.train_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stasiun.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: _textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _charcoalGray.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: _electricBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stasiun.kota,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: _electricBlue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FormStasiunScreen(stasiunToEdit: stasiun),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  label: "Hapus",
                  color: const Color(0xFFEF4444),
                  onPressed: () => _showDeleteDialog(stasiun),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((255 * 0.2).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [_electricBlue, _electricBlue.withAlpha((255 * 0.8).round())],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _electricBlue.withAlpha((255 * 0.4).round()),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          Get.to(() => FormStasiunScreen());
        },
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 24,
        ),
        label: const Text(
          "Tambah Stasiun",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _pureWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: _charcoalGray.withAlpha((255 * 0.1).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _electricBlue.withAlpha((255 * 0.1).round()),
                        _electricBlue.withAlpha((255 * 0.05).round())
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_electricBlue),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Memuat Data Stasiun",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Mohon tunggu sebentar...",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _pureWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: _charcoalGray.withAlpha((255 * 0.1).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _electricBlue.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.train_rounded,
                    size: 56,
                    color: _electricBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Data akan muncul di sini ketika tersedia",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _pureWhite,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: const Color(0xFFEF4444).withAlpha((255 * 0.2).round())),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withAlpha((255 * 0.1).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Terjadi Kesalahan",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(StasiunModel stasiun) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Penghapusan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Anda yakin ingin menghapus stasiun berikut?',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lightGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      stasiun.nama,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stasiun.kota,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: const Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: _borderColor),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _adminService.deleteStasiun(stasiun.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${stasiun.nama} berhasil dihapus',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: _electricBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menghapus stasiun: $e',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }
}
