import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import 'package:kaig/screens/admin/screens/form_jadwal_krl_final_screen.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';

/// Controller untuk mengelola state dan logika dari halaman ListJadwalKrlFinalScreen.
class ListJadwalKrlController extends GetxController {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final TextEditingController searchController = TextEditingController();

  final RxString searchQuery = "".obs;
  final RxBool isLoading = true.obs;

  // RxList terpisah untuk setiap rute
  final RxList<JadwalKrlModel> jadwalYkToPl = <JadwalKrlModel>[].obs;
  final RxList<JadwalKrlModel> jadwalPlToYk = <JadwalKrlModel>[].obs;

  // RxList terpisah untuk hasil filter
  final RxList<JadwalKrlModel> filteredJadwalYkToPl = <JadwalKrlModel>[].obs;
  final RxList<JadwalKrlModel> filteredJadwalPlToYk = <JadwalKrlModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Listener untuk filter otomatis saat user mengetik.
    searchController.addListener(filterAllJadwal);

    // Listener stream dari Firestore.
    getJadwalKrlStream().listen((allJadwal) {
      isLoading.value = false;

      // Pisahkan jadwal berdasarkan relasi ke dalam list masing-masing.
      jadwalYkToPl.assignAll(allJadwal.where((j) => j.relasi.contains("YK - PL")));
      jadwalPlToYk.assignAll(allJadwal.where((j) => j.relasi.contains("PL - YK")));

      // Panggil filter untuk pertama kali setelah data diterima.
      filterAllJadwal();
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar("Error", "Gagal memuat data: $error");
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Menyaring kedua daftar jadwal berdasarkan query pencarian.
  void filterAllJadwal() {
    String query = searchQuery.toLowerCase();

    // Filter untuk rute YK -> PL
    if (query.isEmpty) {
      filteredJadwalYkToPl.assignAll(jadwalYkToPl);
    } else {
      filteredJadwalYkToPl.assignAll(_filterList(jadwalYkToPl, query));
    }

    // Filter untuk rute PL -> YK
    if (query.isEmpty) {
      filteredJadwalPlToYk.assignAll(jadwalPlToYk);
    } else {
      filteredJadwalPlToYk.assignAll(_filterList(jadwalPlToYk, query));
    }
  }

  /// Helper untuk logika filter.
  List<JadwalKrlModel> _filterList(List<JadwalKrlModel> list, String query) {
    return list.where((jadwal) {
      final nomorKaLower = jadwal.nomorKa.toLowerCase();
      final tipeHariLower = jadwal.tipeHari.toLowerCase();
      return nomorKaLower.contains(query) || tipeHariLower.contains(query);
    }).toList();
  }

  void clearSearch() => searchController.clear();

  Future<void> navigateToForm({JadwalKrlModel? jadwal, bool isDuplicating = false}) async {
    await Get.to(() => FormJadwalKrlFinalScreen(
      jadwal: jadwal,
      isDuplicating: isDuplicating,
    ));
  }

  Future<void> deleteJadwalKrl(String jadwalId, String nomorKa) async {
    try {
      await _adminService.deleteJadwalKrl(jadwalId);
      Get.snackbar('Berhasil', 'Jadwal KRL $nomorKa berhasil dihapus',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus jadwal: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Stream<List<JadwalKrlModel>> getJadwalKrlStream() => _adminService.getJadwalKrlList();
}

/// Widget untuk menampilkan daftar jadwal KRL dengan tampilan Tab.
class ListJadwalKrlFinalScreen extends StatelessWidget {
  const ListJadwalKrlFinalScreen({super.key});

  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ListJadwalKrlController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 1,
          shadowColor: Colors.black.withAlpha(26),
          backgroundColor: pureWhite,
          foregroundColor: charcoalGray,
          title: const Text("Kelola Jadwal KRL", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: electricBlue,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: electricBlue,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Yogyakarta → Palur"),
              Tab(text: "Palur → Yogyakarta"),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: "Cari nomor KA atau tipe hari...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: electricBlue, width: 2)),
                  suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: controller.clearSearch)
                      : const SizedBox.shrink()),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildJadwalListView(controller.filteredJadwalYkToPl, controller),
                  _buildJadwalListView(controller.filteredJadwalPlToYk, controller),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => controller.navigateToForm(),
          backgroundColor: electricBlue,
          icon: const Icon(Icons.add, color: pureWhite),
          label: const Text("Tambah Jadwal", style: TextStyle(color: pureWhite, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildJadwalListView(RxList<JadwalKrlModel> jadwalList, ListJadwalKrlController controller) {
    return Obx(() {
      if (controller.isLoading.isTrue) {
        return const Center(child: CircularProgressIndicator());
      }
      if (jadwalList.isEmpty) {
        return _buildEmptyState(controller.searchQuery.isNotEmpty
            ? "Jadwal tidak ditemukan."
            : "Belum ada jadwal untuk rute ini.");
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: jadwalList.length,
        itemBuilder: (context, index) {
          final jadwal = jadwalList[index];
          return _buildJadwalKrlCard(context, jadwal, controller);
        },
      );
    });
  }

  Widget _buildJadwalKrlCard(BuildContext context, JadwalKrlModel jadwal, ListJadwalKrlController controller) {
    final perhentian = jadwal.perhentian;
    String jamBerangkat = perhentian.isNotEmpty ? perhentian.first.jamBerangkat ?? "--:--" : "--:--";
    String jamTiba = perhentian.length > 1 ? perhentian.last.jamDatang ?? "--:--" : "--:--";
    String stasiunAwal = perhentian.isNotEmpty ? perhentian.first.namaStasiun : "N/A";
    String stasiunAkhir = perhentian.length > 1 ? perhentian.last.namaStasiun : "N/A";


    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("KA ${jadwal.nomorKa}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: electricBlue)),
                        const SizedBox(height: 2),
                        Text(jadwal.relasi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: charcoalGray), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: jadwal.tipeHari.toLowerCase() == 'weekend' ? Colors.orange.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(jadwal.tipeHari, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: jadwal.tipeHari.toLowerCase() == 'weekend' ? Colors.orange.shade800 : Colors.blue.shade800)),
                  )
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeInfo(stasiunAwal, jamBerangkat, Icons.departure_board_rounded, Colors.green),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 20),
                  _buildTimeInfo(stasiunAkhir, jamTiba, Icons.share_arrival_time_rounded, Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionButton(icon: Icons.copy_outlined, label: "Salin", color: successGreen, onTap: () => controller.navigateToForm(jadwal: jadwal, isDuplicating: true)),
                  const SizedBox(width: 8),
                  _actionButton(icon: Icons.edit_rounded, label: "Edit", color: electricBlue, onTap: () => controller.navigateToForm(jadwal: jadwal)),
                  const SizedBox(width: 8),
                  _actionButton(icon: Icons.delete_outline_rounded, label: "Hapus", color: Colors.redAccent, onTap: () => _showDeleteConfirmation(context, jadwal, controller)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String stasiun, String time, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(stasiun, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: charcoalGray)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color.withAlpha(26),
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
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: charcoalGray), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text("Gunakan tombol + untuk menambahkan jadwal baru.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, JadwalKrlModel jadwal, ListJadwalKrlController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus jadwal KRL KA ${jadwal.nomorKa} (${jadwal.relasi})?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
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
