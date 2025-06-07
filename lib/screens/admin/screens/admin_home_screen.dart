import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../login/login_screen.dart';
import 'list_gerbong_screen.dart';
import 'list_jadwal_screen.dart';
import 'list_kereta_screen.dart';
import 'list_stasiun_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // Daftar item menu yang lebih terstruktur
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Kelola Stasiun",
        "icon": Icons.account_balance_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListStasiunScreen()),
          );
        },
      },
      {
        "title": "Kelola Tipe Gerbong",
        "icon": Icons.view_comfortable_outlined,
        "onTap": () {
          // Pastikan Anda sudah membuat ListGerbongScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListGerbongScreen()),
          );
        },
      },
      {
        "title": "Kelola Kereta",
        "icon": Icons.train_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListKeretaScreen()),
          );
        },
      },
      {
        "title": "Kelola Jadwal",
        "icon": Icons.calendar_today_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListJadwalScreen()),
          );
        },
      },
      // Tambahkan menu admin lainnya di sini
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Untuk tombol back jika ada
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              final confirmLogout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Konfirmasi Keluar"),
                  content: const Text("Anda yakin ingin keluar dari akun admin?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Batal")),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Keluar", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirmLogout == true && context.mounted) {
                await authService.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginEmailScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Menampilkan 2 item per baris
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.1, // Rasio aspek item (lebar/tinggi)
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _buildAdminMenuItem(
            context,
            title: item["title"],
            icon: item["icon"],
            onTap: item["onTap"],
          );
        },
      ),
    );
  }

  Widget _buildAdminMenuItem(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 48, color: Theme.of(context).primaryColor), // Ukuran ikon disesuaikan
              const SizedBox(height: 12.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16, // Ukuran font disesuaikan
                  fontWeight: FontWeight.w600, // Sedikit lebih tebal
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
