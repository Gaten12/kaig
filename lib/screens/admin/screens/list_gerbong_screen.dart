import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../services/admin_firestore_service.dart';
import 'form_gerbong_screen.dart';

class ListGerbongController extends GetxController {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController searchController = TextEditingController();

  final _searchQuery = ''.obs;
  final _allGerbong = <GerbongTipeModel>[].obs;
  final _filteredGerbong = <GerbongTipeModel>[].obs;
  final _isLoading = true.obs; // Mulai dengan true untuk menampilkan loading awal

  String get searchQuery => _searchQuery.value;
  List<GerbongTipeModel> get filteredGerbong => _filteredGerbong;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();

    _allGerbong.bindStream(_adminService.getGerbongTipeList());

    // Listener untuk text field pencarian
    searchController.addListener(() {
      _searchQuery.value = searchController.text;
    });

    ever(_allGerbong, (_) => _filterGerbong());
    ever(_searchQuery, (_) => _filterGerbong());


    debounce(_allGerbong, (_) => _isLoading.value = false, time: const Duration(milliseconds: 500));
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _filterGerbong() {
    final gerbongList = _allGerbong;
    if (_searchQuery.value.isEmpty) {
      _filteredGerbong.value = List.from(gerbongList);
    } else {
      final searchQueryLower = _searchQuery.value.toLowerCase();
      _filteredGerbong.value = gerbongList.where((gerbong) {
        return gerbong.namaTipeLengkap.toLowerCase().contains(searchQueryLower) ||
            gerbong.tipeLayout.deskripsi.toLowerCase().contains(searchQueryLower);
      }).toList();
    }
  }

  void clearSearch() {
    searchController.clear();
  }

  Future<void> deleteGerbong(String id, String namaGerbong) async {
    final bool? isConfirmed = await Get.defaultDialog<bool>(
      title: "Konfirmasi Hapus",
      middleText: "Apakah Anda yakin ingin menghapus tipe gerbong '$namaGerbong'?\n\nTindakan ini tidak dapat dibatalkan.",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (isConfirmed == true) {
      try {
        await _adminService.deleteGerbongTipe(id);
        Get.snackbar("Berhasil", "Tipe gerbong '$namaGerbong' telah dihapus.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.snackbar("Gagal Menghapus", "Error: $e", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }
}

class ListGerbongScreen extends StatelessWidget {
  const ListGerbongScreen({super.key});

  // Color constants
  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {

    final controller = Get.put(ListGerbongController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchSection(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return _buildLoadingState();
              }
              if (controller.filteredGerbong.isEmpty) {
                return _buildEmptyState(controller.searchQuery.isNotEmpty
                    ? "Tipe gerbong tidak ditemukan"
                    : "Belum ada data tipe gerbong");
              }
              return _buildGerbongListView(controller);
            }),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      toolbarHeight: 80,
      backgroundColor: charcoalGray,
      title: const Text("Kelola Tipe Gerbong", style: TextStyle(color: pureWhite, fontSize: 24, fontWeight: FontWeight.w600)),
      iconTheme: const IconThemeData(color: pureWhite),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [electricBlue, Colors.blue]))),
      ),
    );
  }

  Widget _buildSearchSection(ListGerbongController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: pureWhite, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          labelText: "Cari Tipe Gerbong",
          hintText: "Masukkan nama atau tipe layout...",
          prefixIcon: const Icon(Icons.search_rounded, color: electricBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey[50],
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: electricBlue, width: 2)),
          suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
              ? IconButton(icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600), onPressed: controller.clearSearch)
              : const SizedBox.shrink()),
        ),
      ),
    );
  }

  Widget _buildGerbongListView(ListGerbongController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.filteredGerbong.length,
      itemBuilder: (context, index) {
        final gerbong = controller.filteredGerbong[index];
        return _buildGerbongCard(context, gerbong, controller);
      },
    );
  }

  Widget _buildGerbongCard(BuildContext context, GerbongTipeModel gerbong, ListGerbongController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToForm(context, gerbong),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: electricBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.view_comfortable_outlined, color: electricBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gerbong.namaTipeLengkap, style: const TextStyle(color: charcoalGray, fontSize: 18, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.dashboard_outlined, "Layout: ${gerbong.tipeLayout.deskripsi}"),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.event_seat_outlined, "Kapasitas: ${gerbong.jumlahKursi} kursi"),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _buildActionButton(icon: Icons.edit_outlined, color: electricBlue, onPressed: () => _navigateToForm(context, gerbong), tooltip: 'Edit'),
                  _buildActionButton(icon: Icons.delete_outline_rounded, color: Colors.red.shade400, onPressed: () => controller.deleteGerbong(gerbong.id, gerbong.namaTipeLengkap), tooltip: 'Hapus'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed, required String tooltip}) {
    return SizedBox(
      width: 44, height: 44,
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToForm(context, null),
      backgroundColor: electricBlue,
      icon: const Icon(Icons.add_rounded, color: pureWhite),
      label: const Text("Tambah Gerbong", style: TextStyle(color: pureWhite, fontWeight: FontWeight.w600)),
    );
  }
  void _navigateToForm(BuildContext context, GerbongTipeModel? gerbong) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormTipeGerbongScreen(tipeToEdit: gerbong)),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: electricBlue));
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.train_outlined, color: Colors.grey.shade300, size: 80),
          const SizedBox(height: 20),
          Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }
}