import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import 'package:kaig/screens/admin/screens/form_jadwal_krl_final_screen.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';

/// Controller untuk mengelola state dan logika dari halaman ListJadwalKrlFinalScreen.
/// Menggunakan GetX untuk state management.
class ListJadwalKrlController extends GetxController {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController searchController = TextEditingController();

  final RxString searchQuery = "".obs;
  // RxList untuk menampung semua data asli dari stream Firestore.
  final RxList<JadwalKrlModel> allJadwalKrl = <JadwalKrlModel>[].obs;
  // RxList untuk data yang akan ditampilkan di UI setelah melalui proses filter.
  final RxList<JadwalKrlModel> filteredJadwalKrl = <JadwalKrlModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Listener untuk filter otomatis saat user mengetik di search bar.
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

  /// Mengupdate daftar jadwal utama dan memicu filter.
  /// Dipanggil dari StreamBuilder di UI.
  void updateJadwalListFromStream(List<JadwalKrlModel> jadwalFromStream) {
    allJadwalKrl.assignAll(jadwalFromStream);
    filterJadwalKrl();
  }


  /// Menyaring daftar jadwal berdasarkan query pencarian.
  void filterJadwalKrl() {
    List<JadwalKrlModel> _jadwal;
    if (searchQuery.isEmpty) {
      _jadwal = allJadwalKrl;
    } else {
      String searchQueryLower = searchQuery.toLowerCase();
      _jadwal = allJadwalKrl.where((jadwal) {
        final nomorKaLower = jadwal.nomorKa.toLowerCase();
        final relasiLower = jadwal.relasi.toLowerCase();
        final tipeHariLower = jadwal.tipeHari.toLowerCase();

        return nomorKaLower.contains(searchQueryLower) ||
            relasiLower.contains(searchQueryLower) ||
            tipeHariLower.contains(searchQueryLower);
      }).toList();
    }
    filteredJadwalKrl.assignAll(_jadwal);
  }

  /// Membersihkan teks di search controller.
  void clearSearch() {
    searchController.clear();
  }

  /// Navigasi ke halaman form. Bisa untuk menambah, mengedit, atau menyalin jadwal.
  Future<void> navigateToForm({JadwalKrlModel? jadwal, bool isDuplicating = false}) async {
    // `Get.to` akan mengembalikan sebuah Future.
    // Kita bisa menunggu halaman form ditutup.
    final result = await Get.to(() => FormJadwalKrlFinalScreen(
      jadwal: jadwal,
      isDuplicating: isDuplicating,
    ));

    // Jika form ditutup dengan hasil `true` (artinya ada perubahan),
    // kita bisa melakukan aksi tambahan di sini.
    // Namun, karena kita menggunakan `bindStream`, daftar akan otomatis refresh.
    if (result == true) {
      Get.log("Kembali dari form dengan perubahan, daftar diperbarui via stream.");
    }
  }

  /// Menghapus jadwal KRL dari Firestore.
  Future<void> deleteJadwalKrl(String jadwalId, String nomorKa) async {
    try {
      await _adminService.deleteJadwalKrl(jadwalId);
      Get.snackbar(
        'Berhasil',
        'Jadwal KRL $nomorKa berhasil dihapus',
        backgroundColor: const Color(0xFF3B82F6),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus jadwal KRL: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Mendapatkan stream data jadwal dari Firestore.
  Stream<List<JadwalKrlModel>> getJadwalKrlStream() {
    return _adminService.getJadwalKrlList();
  }
}

/// Widget untuk menampilkan daftar jadwal KRL.
class ListJadwalKrlFinalScreen extends StatelessWidget {
  const ListJadwalKrlFinalScreen({super.key});

  // Definisi warna untuk konsistensi UI
  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller menggunakan Get.put()
    final controller = Get.put(ListJadwalKrlController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black.withAlpha(26), // FIX: Mengganti withOpacity
        toolbarHeight: 80,
        backgroundColor: pureWhite,
        foregroundColor: charcoalGray,
        title: const Text(
          "Kelola Jadwal KRL",
          style: TextStyle(
            color: charcoalGray,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Obx(
                  () => TextField(
                controller: controller.searchController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Cari nomor KA, relasi, tipe hari...",
                  prefixIcon: const Icon(Icons.search_rounded, color: charcoalGray),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: electricBlue, width: 2),
                  ),
                  suffixIcon: controller.searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                    onPressed: controller.clearSearch,
                  )
                      : null,
                ),
              ),
            ),
          ),
          // Daftar Jadwal
          Expanded(
            child: StreamBuilder<List<JadwalKrlModel>>(
              stream: controller.getJadwalKrlStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // FIX: Memanggil _buildErrorState saat ada error
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                final jadwalList = snapshot.data ?? [];
                // Mengupdate list di controller dengan data terbaru dari stream
                controller.updateJadwalListFromStream(jadwalList);

                if (jadwalList.isEmpty) {
                  return _buildEmptyState("Belum ada data jadwal KRL.");
                }

                // Obx akan merebuild UI saat filteredJadwalKrl berubah
                return Obx(() {
                  if (controller.filteredJadwalKrl.isEmpty) {
                    return _buildEmptyState("Jadwal KRL tidak ditemukan.");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.navigateToForm(),
        backgroundColor: electricBlue,
        icon: const Icon(Icons.add, color: pureWhite),
        label: const Text(
          "Tambah Jadwal",
          style: TextStyle(color: pureWhite, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Widget untuk membangun setiap kartu jadwal dalam daftar.
  Widget _buildJadwalKrlCard(BuildContext context, JadwalKrlModel jadwal, ListJadwalKrlController controller) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.navigateToForm(jadwal: jadwal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "KA ${jadwal.nomorKa}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: electricBlue),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          jadwal.relasi,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: charcoalGray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: jadwal.tipeHari.toLowerCase() == 'weekend' ? Colors.orange.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      jadwal.tipeHari,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: jadwal.tipeHari.toLowerCase() == 'weekend' ? Colors.orange.shade800 : Colors.blue.shade800,
                      ),
                    ),
                  )
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.money_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text("Harga: ", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(jadwal.harga),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: charcoalGray),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionButton(
                    icon: Icons.copy_outlined,
                    label: "Salin",
                    color: successGreen,
                    onTap: () => controller.navigateToForm(jadwal: jadwal, isDuplicating: true),
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    icon: Icons.edit_rounded,
                    label: "Edit",
                    color: electricBlue,
                    onTap: () => controller.navigateToForm(jadwal: jadwal),
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    icon: Icons.delete_outline_rounded,
                    label: "Hapus",
                    color: Colors.redAccent,
                    onTap: () => _showDeleteConfirmation(context, jadwal, controller),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget untuk membuat tombol aksi (Edit, Salin, Hapus).
  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color.withAlpha((255 * 0.1).round()), // FIX: Mengganti withOpacity
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget yang ditampilkan saat data sedang dimuat.
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(electricBlue)),
          SizedBox(height: 16),
          Text("Memuat data jadwal KRL...", style: TextStyle(color: charcoalGray, fontSize: 16)),
        ],
      ),
    );
  }

  /// Widget yang ditampilkan saat tidak ada data atau hasil pencarian kosong.
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: charcoalGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Gunakan tombol + untuk menambahkan jadwal baru.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget yang ditampilkan jika terjadi error saat mengambil data.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Terjadi Error",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade600)),
          ],
        ),
      ),
    );
  }

  /// Menampilkan dialog konfirmasi sebelum menghapus jadwal.
  void _showDeleteConfirmation(BuildContext context, JadwalKrlModel jadwal, ListJadwalKrlController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus jadwal KRL KA ${jadwal.nomorKa} (${jadwal.relasi})?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteJadwalKrl(jadwal.id!, jadwal.nomorKa);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: pureWhite),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
