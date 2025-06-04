import 'package:flutter/material.dart';
import 'list_jadwal_screen.dart';
import 'list_kereta_screen.dart';
import 'list_stasiun_screen.dart';
import '../../../services/auth_service.dart'; // Untuk logout
import '../../../screens/login/login_screen.dart'; // Untuk navigasi setelah logout

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) =>  LoginEmailScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildAdminMenuItem(
            context,
            title: "Kelola Stasiun",
            icon: Icons.account_balance_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListStasiunScreen()),
              );
            },
          ),
          _buildAdminMenuItem(
            context,
            title: "Kelola Kereta",
            icon: Icons.train_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListKeretaScreen()),
              );
            },
          ),
          _buildAdminMenuItem(
            context,
            title: "Kelola Jadwal",
            icon: Icons.calendar_today_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListJadwalScreen()),
              );
            },
          ),
          // Tambahkan menu admin lainnya di sini
        ],
      ),
    );
  }

  Widget _buildAdminMenuItem(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}

