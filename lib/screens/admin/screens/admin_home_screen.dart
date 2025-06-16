import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../login/login_screen.dart';
import 'list_gerbong_screen.dart';
import 'list_jadwal_screen.dart';
import 'list_kereta_screen.dart';
import 'list_stasiun_screen.dart';
import 'sales_statistics_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService authService = AuthService();
  String _adminName = "Admin";

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  void _loadAdminName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _adminName = user.email!.split('@')[0];
      });
    }
  }

  final List<Map<String, dynamic>> menuItems = [
    {
      "title": "Kelola Stasiun",
      "icon": Icons.account_balance_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListStasiunScreen()),
        );
      },
    },
    {
      "title": "Kelola Tipe Gerbong",
      "icon": Icons.view_comfortable_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListGerbongScreen()),
        );
      },
    },
    {
      "title": "Kelola Kereta",
      "icon": Icons.train_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListKeretaScreen()),
        );
      },
    },
    {
      "title": "Kelola Jadwal",
      "icon": Icons.calendar_today_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListJadwalScreen()),
        );
      },
    },
    {
      "title": "Statistik Penjualan",
      "icon": Icons.analytics_outlined,
      "onTap": (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalesStatisticsScreen()),
        );
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
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
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Selamat Datang, $_adminName!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildAdminMenuItem(
                    context,
                    title: item["title"],
                    icon: item["icon"],
                    onTap: () => item["onTap"](context),
                  ),
                );
              },
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Area untuk statistik atau ringkasan lainnya",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuItem(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return Container(
      width: 120,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(height: 4.0),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}