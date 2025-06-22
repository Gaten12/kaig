import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart';
import '../services/admin_firestore_service.dart';
import 'form_jadwal_screen.dart';

// Controller untuk GetX
class ListJadwalController extends GetxController {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController searchController = TextEditingController();

  final RxString searchQuery = "".obs;
  final RxList<JadwalModel> allJadwal = <JadwalModel>[].obs;
  final RxList<JadwalModel> filteredJadwal = <JadwalModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      filterJadwal();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void filterJadwal() {
    if (searchQuery.isEmpty) {
      filteredJadwal.assignAll(allJadwal);
    } else {
      filteredJadwal.assignAll(allJadwal.where((jadwal) {
        final namaKeretaLower = jadwal.namaKereta.toLowerCase();
        final idKeretaLower = jadwal.idKereta.toLowerCase();
        final stasiunAsalLower = jadwal.idStasiunAsal.toLowerCase();
        final stasiunTujuanLower = jadwal.idStasiunTujuan.toLowerCase();
        final searchQueryLower = searchQuery.toLowerCase();

        return namaKeretaLower.contains(searchQueryLower) ||
            idKeretaLower.contains(searchQueryLower) ||
            stasiunAsalLower.contains(searchQueryLower) ||
            stasiunTujuanLower.contains(searchQueryLower);
      }).toList());
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = "";
  }

  Future<void> deleteJadwal(String jadwalId, String namaKereta) async {
    try {
      isLoading.value = true;
      await _adminService.deleteJadwal(jadwalId);
      Get.snackbar(
        'Berhasil',
        'Jadwal $namaKereta berhasil dihapus.',
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
        'Gagal menghapus jadwal: $e',
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

  Stream<List<JadwalModel>> getJadwalStream() {
    return _adminService.getJadwalList();
  }
}

class ListJadwalScreen extends StatelessWidget {
  const ListJadwalScreen({super.key});

  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ListJadwalController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        title: const Text(
          "Daftar Jadwal Kereta",
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
                        color: electricBlue.withAlpha((255 * 0.1).round()),
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
                        labelText: "Cari Jadwal",
                        hintText: "Nama kereta, rute, stasiun...",
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
                                onPressed: controller.clearSearch,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List Content
          Expanded(
            child: StreamBuilder<List<JadwalModel>>(
              stream: controller.getJadwalStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withAlpha((255 * 0.3).round()),
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
                            "${snapshot.error}\nPastikan Indeks Firestore sudah dibuat.",
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

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Memuat data jadwal...",
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  controller.allJadwal.clear();
                  controller.filterJadwal();
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.train_rounded,
                            size: 64,
                            color: const Color(0xFF3B82F6).withAlpha((255 * 0.7).round()),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Belum Ada Jadwal",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Silakan tambahkan jadwal baru dengan menekan tombol + di bawah",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Update data ketika stream berubah
                if (controller.allJadwal.length != snapshot.data!.length) {
                  controller.allJadwal.assignAll(snapshot.data!);
                  controller.filterJadwal();
                }

                return Obx(() {
                  if (controller.filteredJadwal.isEmpty &&
                      controller.searchQuery.isNotEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Jadwal tidak ditemukan",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Coba kata kunci yang berbeda",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: controller.filteredJadwal.length,
                    itemBuilder: (context, index) {
                      final jadwal = controller.filteredJadwal[index];
                      return _buildJadwalCard(context, jadwal, controller);
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
              color: const Color(0xFF3B82F6).withAlpha((255 * 0.3).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => const FormJadwalScreen());
          },
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            "Tambah Jadwal",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalCard(BuildContext context, JadwalModel jadwal,
      ListJadwalController controller) {
    String tanggalBerangkatFormatted = "N/A";
    String jamTibaFormatted = "N/A";
    String tanggalTibaFormattedSimple = "N/A";

    try {
      tanggalBerangkatFormatted = DateFormat('EEE, dd MMM yy HH:mm', 'id_ID')
          .format(jadwal.tanggalBerangkatUtama.toDate());
      jamTibaFormatted =
          DateFormat('HH:mm', 'id_ID').format(jadwal.tanggalTibaUtama.toDate());
      tanggalTibaFormattedSimple = DateFormat('dd MMM', 'id_ID')
          .format(jadwal.tanggalTibaUtama.toDate());
    } catch (e) {
      print("Error formatting date for jadwal ID ${jadwal.id}: $e");
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.08).round()),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withAlpha((255 * 0.2).round()),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan nama kereta
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jadwal.idKereta,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    jadwal.namaKereta,
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

            // Route Information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DARI",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jadwal.idStasiunAsal,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "KE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jadwal.idStasiunTujuan,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha((255 * 0.05).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Berangkat: ",
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
                        ),
                      ),
                      Text(
                        tanggalBerangkatFormatted,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Tiba: ",
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
                        ),
                      ),
                      Text(
                        "$jamTibaFormatted ($tanggalTibaFormattedSimple)",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Footer with class info and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151).withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.airline_seat_recline_normal_rounded,
                        size: 16,
                        color: const Color(0xFF374151).withAlpha((255 * 0.8).round()),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${jadwal.daftarKelasHarga.length} kelas",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151).withAlpha((255 * 0.8).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Edit button (disabled)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withAlpha((255 * 0.3).round()),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_off_outlined,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        tooltip: "Fitur Edit belum tersedia",
                        onPressed: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withAlpha((255 * 0.3).round()),
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
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    JadwalModel jadwal,
    ListJadwalController controller,
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
                color: Colors.red.withAlpha((255 * 0.1).round()),
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
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus jadwal berikut?',
              style: TextStyle(
                color: const Color(0xFF374151).withAlpha((255 * 0.8).round()),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${jadwal.namaKereta} (${jadwal.idKereta})",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    "${jadwal.idStasiunAsal} → ${jadwal.idStasiunTujuan}",
                    style: TextStyle(
                      color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
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
                color: const Color(0xFF374151).withAlpha((255 * 0.7).round()),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteJadwal(jadwal.id, jadwal.namaKereta);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
