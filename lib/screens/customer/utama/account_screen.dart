import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/tentang_aplikasi.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/passenger_model.dart';
import '../../../services/auth_service.dart'; // Pastikan path ini benar
import '../../../screens/login/login_screen.dart'; // Halaman login
import 'ganti_kata_sandi_screen.dart';
import 'list_penumpang_screen.dart';
import 'metode_pembayaran_screen.dart'; // Halaman daftar penumpang

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  // UserModel? _currentUserModel; // Bisa tetap ada jika perlu data lain dari UserModel
  String _userName = "Pengguna";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final firebaseUser = _authService.currentUser;
    String displayNameToShow = "Pengguna"; // Default

    if (firebaseUser != null) {
      // Ambil nama dari data penumpang utama (primary passenger)
      try {
        PassengerModel? primaryPassenger = await _authService.getPrimaryPassenger(firebaseUser.uid);
        if (primaryPassenger != null && primaryPassenger.namaLengkap.isNotEmpty) {
          displayNameToShow = primaryPassenger.namaLengkap;
        } else if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
          displayNameToShow = firebaseUser.displayName!;
        } else if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
          displayNameToShow = firebaseUser.email!.split('@')[0];
        }
      } catch (e) {
        print("Error loading primary passenger for AccountScreen: $e");
        if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
          displayNameToShow = firebaseUser.displayName!;
        } else if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
          displayNameToShow = firebaseUser.email!.split('@')[0];
        }
      }

      // Jika Anda masih perlu data lain dari UserModel (misal no telepon, role, dll.)
      // Anda bisa tetap mengambil _currentUserModel di sini:
      // _currentUserModel = await _authService.getUserModel(firebaseUser.uid);
    }

    if (mounted) {
      setState(() {
        _userName = displayNameToShow;
        // Potong nama jika terlalu panjang untuk tampilan header
        if (_userName.length > 20) {
          _userName = "${_userName.substring(0, 17)}...";
        }
      });
    }
  }

  // --- FUNGSI BARU UNTUK MENAMPILKAN DIALOG ---
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text("Apakah Anda yakin ingin keluar dari akun Anda sekarang?"),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text("TIDAK"),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true, // Membuat teks menjadi tebal (gaya default iOS)
              onPressed: () async {
                // Tutup dialog terlebih dahulu
                Navigator.of(context).pop();

                // Lakukan proses logout
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginEmailScreen()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text("IYA"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: const Text("Akun Saya"),
      //   // automaticallyImplyLeading: false,
      //   // elevation: 1.0,
      // ),
      body: ListView(
        children: <Widget>[
          _buildProfileHeader(context),
          _buildSectionTitle("Informasi Pengguna"),
          _buildMenuItem(
            context,
            icon: Icons.lock_outline,
            title: "Ganti Kata Sandi",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GantiKataSandiScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_outlined,
            title: "Riwayat Transaksi",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur Riwayat Transaksi belum tersedia.')),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.people_alt_outlined,
            title: "Daftar Penumpang",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListPenumpangScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.payment_outlined,
            title: "Metode Pembayaran Saya",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MetodePembayaranScreen()),
              );
            },
          ),
          _buildSectionTitle("Lainnya"),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: "Tentang Aplikasi TrainOrder",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TentangAplikasiScreen()),
              );
              // showDialog(context: context, builder: (ctx) => AlertDialog(
              //   title: const Text("Tentang Aplikasi"),
              //   content: const Text("Aplikasi Pemesanan Tiket Kereta Api TrainOrder v1.0.0"),
              //   actions: [TextButton(onPressed: ()=>Navigator.of(ctx).pop(), child: const Text("OK"))],
              // ));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: "Keluar",
            // onTap: () async {
            //   await _authService.signOut();
            //   if (mounted) {
            //     Navigator.of(context).pushAndRemoveUntil(
            //       MaterialPageRoute(builder: (context) =>  LoginEmailScreen()),
            //           (Route<dynamic> route) => false,
            //     );
            //   }
            // },
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: _showLogoutConfirmationDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 12.0),
          Text(
            _userName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text("Kelola Profile"),
            onPressed: () {
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(content: Text('Fitur Kelola Profile belum tersedia.')),
              // );
            //  Navigator.push(
                // context,
                // MaterialPageRoute(builder: (context) => const InformasiDataDiriScreen()),
              // );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5))
                )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 8.0, right: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? textColor, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
      title: Text(title, style: TextStyle(color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}