// lib/screens/admin/screens/list_jadwal_krl_final_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import 'package:kaig/screens/admin/screens/form_jadwal_krl_final_screen.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';

class ListJadwalKrlController extends GetxController {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController searchController = TextEditingController();

  final RxString searchQuery = "".obs;
  final RxList<JadwalKrlModel> allJadwalKrl = <JadwalKrlModel>[].obs;
  final RxList<JadwalKrlModel> filteredJadwalKrl = <JadwalKrlModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      filterJadwalKrl();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void filterJadwalKrl() {
    if (searchQuery.isEmpty) {
      filteredJadwalKrl.assignAll(allJadwalKrl);
    } else {
      filteredJadwalKrl.assignAll(allJadwalKrl.where((jadwal) {
        final nomorKaLower = jadwal.nomorKa.toLowerCase();
        final relasiLower = jadwal.relasi.toLowerCase();
        final tipeHariLower = jadwal.tipeHari.toLowerCase();
        final searchQueryLower = searchQuery.toLowerCase();

        return nomorKaLower.contains(searchQueryLower) ||
            relasiLower.contains(searchQueryLower) ||
            tipeHariLower.contains(searchQueryLower);
      }).toList());
    }
  }

  void clearSearch() { // Added this method
    searchController.clear();
  }

  Future<void> deleteJadwalKrl(String jadwalId, String nomorKa) async {
    try {
      isLoading.value = true;
      await _adminService.deleteJadwalKrl(jadwalId);
      Get.snackbar(
        'Berhasil',
        'Jadwal KRL $nomorKa berhasil dihapus',
        backgroundColor: const Color(0xFF3B82F6),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus jadwal KRL: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Stream<List<JadwalKrlModel>> getJadwalKrlStream() {
    return _adminService.getJadwalKrlList();
  }
}

class ListJadwalKrlFinalScreen extends StatelessWidget {
  const ListJadwalKrlFinalScreen({super.key});

  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ListJadwalKrlController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        title: const Text(
          "Daftar Jadwal KRL",
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
                        color: electricBlue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Obx(
                        () => TextField(
                      controller: controller.searchController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Cari Jadwal KRL",
                        hintText: "Nomor KA, relasi, tipe hari...",
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
                        suffixIcon: controller.searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              color: Colors.grey.shade600),
                          onPressed: controller.clearSearch, // Calls the new clearSearch method
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<JadwalKrlModel>>(
              stream: controller.getJadwalKrlStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  controller.allJadwalKrl.clear();
                  controller.filterJadwalKrl();
                  return _buildEmptyState("Belum ada data jadwal KRL.");
                }

                if (controller.allJadwalKrl.length != snapshot.data!.length) {
                  controller.allJadwalKrl.assignAll(snapshot.data!);
                  controller.filterJadwalKrl();
                }

                return Obx(() {
                  if (controller.filteredJadwalKrl.isEmpty &&
                      controller.searchQuery.isNotEmpty) {
                    return _buildEmptyState("Jadwal KRL tidak ditemukan.");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: controller.filteredJadwalKrl.length,
                    itemBuilder: (context, index) {
                      final jadwal = controller.filteredJadwalKrl[index];
                      return _buildJadwalKrlCard(context, jadwal, controller);
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
              color: electricBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => const FormJadwalKrlFinalScreen());
          },
          backgroundColor: electricBlue,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: pureWhite),
          label: const Text(
            "Tambah Jadwal KRL",
            style: TextStyle(
              color: pureWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalKrlCard(BuildContext context, JadwalKrlModel jadwal,
      ListJadwalKrlController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.to(() => FormJadwalKrlFinalScreen(jadwal: jadwal));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: electricBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        jadwal.nomorKa,
                        style: const TextStyle(
                          color: pureWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        jadwal.relasi,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: charcoalGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: charcoalGray.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Tipe Hari: ",
                            style: TextStyle(
                              fontSize: 14,
                              color: charcoalGray.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            jadwal.tipeHari,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: charcoalGray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.money_rounded,
                            size: 16,
                            color: charcoalGray.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Harga: ",
                            style: TextStyle(
                              fontSize: 14,
                              color: charcoalGray.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(jadwal.harga),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: charcoalGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_off_outlined,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        tooltip: "Fitur Edit belum tersedia",
                        onPressed: () {
                          Get.to(() => FormJadwalKrlFinalScreen(jadwal: jadwal));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        onPressed: () => _showDeleteConfirmation(
                          context,
                          jadwal,
                          controller,
                        ),
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              electricBlue,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Memuat data jadwal KRL...",
            style: TextStyle(
              color: charcoalGray,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: electricBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.train_rounded,
              size: 64,
              color: electricBlue.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: charcoalGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan tambahkan jadwal baru dengan menekan tombol + di bawah",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: charcoalGray.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              "Terjadi Error",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$error",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context,
      JadwalKrlModel jadwal,
      ListJadwalKrlController controller,
      ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
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
                color: charcoalGray,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus jadwal KRL berikut?',
              style: TextStyle(
                color: charcoalGray.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "KA ${jadwal.nomorKa} - ${jadwal.relasi}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: charcoalGray,
                    ),
                  ),
                  Text(
                    "Tipe Hari: ${jadwal.tipeHari}",
                    style: TextStyle(
                      color: charcoalGray.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: TextStyle(
                color: charcoalGray.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteJadwalKrl(jadwal.id!, jadwal.nomorKa);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}