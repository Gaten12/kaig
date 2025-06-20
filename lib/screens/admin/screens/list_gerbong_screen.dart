import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../services/admin_firestore_service.dart';
import 'form_gerbong_screen.dart';

// Controller untuk mengelola state dengan GetX
class ListGerbongController extends GetxController {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController searchController = TextEditingController();

  final _searchQuery = ''.obs;
  final _allGerbong = <GerbongTipeModel>[].obs;
  final _filteredGerbong = <GerbongTipeModel>[].obs;
  final _isLoading = false.obs;

  String get searchQuery => _searchQuery.value;
  List<GerbongTipeModel> get allGerbong => _allGerbong;
  List<GerbongTipeModel> get filteredGerbong => _filteredGerbong;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // Listen to search text changes
    searchController.addListener(() {
      _searchQuery.value = searchController.text;
      _filterGerbong();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void updateGerbongList(List<GerbongTipeModel> gerbongList) {
    if (_allGerbong != gerbongList) {
      _allGerbong.value = gerbongList;
      _filterGerbong();
    }
  }

  void _filterGerbong() {
    if (_searchQuery.value.isEmpty) {
      _filteredGerbong.value = List.from(_allGerbong);
    } else {
      _filteredGerbong.value = _allGerbong.where((gerbong) {
        final namaTipeLower = gerbong.namaTipeLengkap.toLowerCase();
        final layoutLower = gerbong.tipeLayout.deskripsi.toLowerCase();
        final searchQueryLower = _searchQuery.value.toLowerCase();
        return namaTipeLower.contains(searchQueryLower) ||
            layoutLower.contains(searchQueryLower);
      }).toList();
    }
  }

  void clearSearch() {
    searchController.clear();
  }

  Stream<List<GerbongTipeModel>> get gerbongTipeStream =>
      _adminService.getGerbongTipeList();
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
          Expanded(child: _buildGerbongList(controller)),
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
      title: const Text(
        "Kelola Tipe Gerbong",
        style: TextStyle(
          color: pureWhite,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      iconTheme: const IconThemeData(color: pureWhite),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [electricBlue, Colors.blue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(ListGerbongController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: pureWhite,
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
          Text(
            "Pencarian Gerbong",
            style: TextStyle(
              color: charcoalGray,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: electricBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: "Cari Tipe Gerbong",
                hintText: "Masukkan nama atau tipe layout gerbong...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded, color: electricBlue),
                filled: true,
                fillColor: pureWhite,
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
                  borderSide: const BorderSide(color: electricBlue, width: 2),
                ),
                suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: Colors.grey.shade600),
                        onPressed: controller.clearSearch,
                      )
                    : const SizedBox.shrink()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGerbongList(ListGerbongController controller) {
    return StreamBuilder<List<GerbongTipeModel>>(
      stream: controller.gerbongTipeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          print("Error Stream Gerbong: ${snapshot.error}");
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          controller.updateGerbongList([]);
          return _buildEmptyState("Belum ada data tipe gerbong");
        }

        // Update controller data
        controller.updateGerbongList(snapshot.data!);

        return Obx(() {
          if (controller.filteredGerbong.isEmpty &&
              controller.searchQuery.isNotEmpty) {
            return _buildEmptyState("Tipe gerbong tidak ditemukan");
          }

          if (controller.filteredGerbong.isEmpty) {
            return _buildEmptyState("Belum ada data tipe gerbong");
          }

          return _buildGerbongListView(controller);
        });
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(electricBlue),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            "Memuat data gerbong...",
            style: TextStyle(
              color: charcoalGray,
              fontSize: 16,
            ),
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
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              "Terjadi Kesalahan",
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Error: $error",
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.train_outlined,
              color: Colors.grey.shade400,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: charcoalGray,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        return _buildGerbongCard(context, gerbong, index);
      },
    );
  }

  Widget _buildGerbongCard(
      BuildContext context, GerbongTipeModel gerbong, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToForm(context, gerbong),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: electricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.view_comfortable_outlined,
                    color: electricBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gerbong.namaTipeLengkap,
                        style: const TextStyle(
                          color: charcoalGray,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.dashboard_outlined,
                              color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Layout: ${gerbong.tipeLayout.deskripsi}",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event_seat_outlined,
                              color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Kapasitas: ${gerbong.jumlahKursi} kursi",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: electricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: electricBlue, size: 20),
                    onPressed: () => _navigateToForm(context, gerbong),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: electricBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context, null),
        backgroundColor: electricBlue,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: pureWhite),
        label: const Text(
          "Tambah Gerbong",
          style: TextStyle(
            color: pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, GerbongTipeModel? gerbong) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormGerbongScreen(gerbongToEdit: gerbong),
      ),
    );
  }
}
