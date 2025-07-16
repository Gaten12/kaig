import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/KeretaModel.dart';
import '../services/admin_firestore_service.dart';
import 'form_kereta_screen.dart';

class ListKeretaController extends GetxController {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = "".obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Stream<List<KeretaModel>> getKeretaList() {
    return _adminService.getKeretaList();
  }

  Future<void> deleteKereta(KeretaModel kereta) async {
    try {
      isLoading.value = true;
      await _adminService.deleteKereta(kereta.id!);
      Get.snackbar(
        'Berhasil',
        '${kereta.nama} berhasil dihapus',
        backgroundColor: const Color(0xFF3B82F6),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus kereta: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = "";
  }

  void navigateToForm({KeretaModel? kereta, bool isDuplicating = false}) {
    Get.to(() => FormKeretaScreen(kereta: kereta, isDuplicating: isDuplicating));
  }
}

class ListKeretaScreen extends StatelessWidget {
  const ListKeretaScreen({super.key});

  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

  /// Helper function untuk mengekstrak nomor dari nama kereta.
  /// Contoh: "KA 10 Argo Bromo" akan mengembalikan 10.
  int _extractNumberFromName(String name) {
    // Menggunakan regular expression untuk mencari urutan angka pertama dalam string.
    final match = RegExp(r'\d+').firstMatch(name);
    if (match != null) {
      // Jika ditemukan, parse ke integer.
      return int.tryParse(match.group(0)!) ?? 9999;
    }
    // Jika tidak ada angka, kembalikan nilai besar agar diletakkan di akhir.
    return 9999;
  }


  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ListKeretaController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        title: const Text(
          "Daftar Kereta",
          style: TextStyle(
            color: pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: pureWhite),
        centerTitle: true,
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
      ),
      body: Column(
        children: [
          // Header dengan search section
          Container(
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: electricBlue.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Obx(() => TextField(
                    controller: controller.searchController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Cari Nama Kereta",
                      hintText: "Masukkan nama kereta...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, color: electricBlue),
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
                      suffixIcon: controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: Colors.grey.shade600),
                        onPressed: controller.clearSearch,
                      )
                          : const SizedBox.shrink(),
                    ),
                  )),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: StreamBuilder<List<KeretaModel>>(
              stream: controller.getKeretaList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState("Belum ada data kereta");
                }

                return Obx(() {
                  List<KeretaModel> allKereta = snapshot.data!;

                  // --- LOGIKA PENGURUTAN BERDASARKAN NOMOR KA ---
                  allKereta.sort((a, b) {
                    final numA = _extractNumberFromName(a.nama);
                    final numB = _extractNumberFromName(b.nama);
                    int numCompare = numA.compareTo(numB);
                    // Jika nomor sama, urutkan berdasarkan nama lengkap
                    if (numCompare == 0) {
                      return a.nama.compareTo(b.nama);
                    }
                    return numCompare;
                  });
                  // --- AKHIR LOGIKA PENGURUTAN ---

                  List<KeretaModel> filteredKereta = allKereta;

                  if (controller.searchQuery.value.isNotEmpty) {
                    filteredKereta = allKereta
                        .where((kereta) => kereta.nama.toLowerCase().contains(
                        controller.searchQuery.value.toLowerCase()))
                        .toList();
                  }

                  if (filteredKereta.isEmpty) {
                    return _buildEmptyState("Kereta tidak ditemukan");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredKereta.length,
                    itemBuilder: (context, index) {
                      final kereta = filteredKereta[index];
                      return _buildKeretaCard(kereta, controller, index);
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withAlpha(76),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => controller.navigateToForm(), // Navigasi untuk menambah baru
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            "Tambah Kereta",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildKeretaCard(
      KeretaModel kereta, ListKeretaController controller, int index) {
    String ruteDisplay = kereta.templateRute.isNotEmpty
        ? "${kereta.templateRute.first.stasiunId} ➤ ${kereta.templateRute.last.stasiunId}"
        : "Rute belum diatur";
    String rangkaianDisplay = "${kereta.rangkaian.length} gerbong";
    String kursiDisplay = "${kereta.totalKursi} kursi";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.navigateToForm(kereta: kereta), // Navigasi untuk mengedit
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan nama kereta
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.train_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kereta.nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info rute
                _buildInfoRow(
                  Icons.route_rounded,
                  "Rute",
                  ruteDisplay,
                ),

                const SizedBox(height: 8),

                // Info rangkaian dan kursi
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.view_carousel_rounded,
                        "Rangkaian",
                        rangkaianDisplay,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.event_seat_rounded,
                        "Kapasitas",
                        kursiDisplay,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tombol Salin
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.copy_outlined,
                          color: Colors.green,
                          size: 20,
                        ),
                        onPressed: () => controller.navigateToForm(kereta: kereta, isDuplicating: true),
                        tooltip: 'Salin Kereta',
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tombol Edit
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                        onPressed: () =>
                            controller.navigateToForm(kereta: kereta),
                        tooltip: 'Edit Kereta',
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tombol Hapus
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _showDeleteDialog(kereta, controller),
                        tooltip: 'Hapus Kereta',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isCompact = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        if (!isCompact) ...[
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            "Memuat data kereta...",
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 16,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.train_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Tap tombol + untuk menambah kereta baru",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Terjadi Kesalahan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(KeretaModel kereta, ListKeretaController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Hapus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        content: Text(
          'Anda yakin ingin menghapus kereta "${kereta.nama}"? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteKereta(kereta);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
