import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/riwayat_transaksi_screen.dart';
import 'package:kaig/screens/customer/utama/tentang_aplikasi.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/passenger_model.dart';
import '../../../services/auth_service.dart'; // Pastikan path ini benar
import '../../../screens/login/login_screen.dart'; // Halaman login
import 'ganti_kata_sandi_screen.dart';
import 'informasi_data_diri_screen.dart';
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
  String get _userInitials => getInitials(_userName);

  String getInitials(String name) {
    String trimmedName = name.trim();
    if (trimmedName.isEmpty) return "?";
    
    final List<String> nameParts = trimmedName.split(RegExp(r'\s+'));
    String initials = nameParts[0][0];
    
    if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
      initials += nameParts[1][0];
    }
    
    return initials.toUpperCase();
  }

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
    // Daftar menu, dipisahkan dari header
    final List<Widget> listMenuItems = [
      _buildSectionTitle("Informasi Pengguna"),
      _buildMenuItem(context, icon: Icons.lock_outline, title: "Ganti Kata Sandi", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GantiKataSandiScreen()))),
      _buildMenuItem(context, icon: Icons.receipt_long_outlined, title: "Riwayat Transaksi", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatTransaksiScreen()))),
      _buildMenuItem(context, icon: Icons.people_alt_outlined, title: "Daftar Penumpang", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListPenumpangScreen()))),
      _buildMenuItem(context, icon: Icons.payment_outlined, title: "Metode Pembayaran Saya", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MetodePembayaranScreen()))),
      _buildSectionTitle("Lainnya"),
      _buildMenuItem(context, icon: Icons.info_outline, title: "Tentang Aplikasi TrainOrder", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TentangAplikasiScreen()))),
      _buildMenuItem(context, icon: Icons.logout, title: "Keluar", textColor: Colors.red, iconColor: Colors.red, onTap: _showLogoutConfirmationDialog),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[200], // Background abu-abu untuk daftar menu
      // Menggunakan Column agar bisa menumpuk header dan list
      body: Column(
        children: [
          _buildProfileHeader(context),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero, // Hapus padding atas dari list
              itemCount: listMenuItems.length,
              itemBuilder: (context, index) {
                return listMenuItems[index];
              },
              separatorBuilder: (context, index) {
                final currentItem = listMenuItems[index];
                if (index < listMenuItems.length - 1) {
                  final nextItem = listMenuItems[index + 1];
                  // Tampilkan divider hanya di antara dua menu item
                  if (currentItem is Container && nextItem is Container) {
                    return const Divider(height: 1, thickness: 1, indent: 56, endIndent: 16);
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// PERUBAHAN UTAMA: Widget ini sekarang membangun seluruh bagian header merah.
  Widget _buildProfileHeader(BuildContext context) {
    // Mendapatkan tinggi status bar untuk padding yang aman
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      // Container Merah sebagai background utama
      padding: EdgeInsets.fromLTRB(16.0, statusBarHeight + 16.0, 16.0, 16.0),
      color: const Color(0xFFB71C1C), // Warna merah maroon
      child: Container(
        // Container Putih sebagai kartu (card)
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFC50000),
                  child: Text(
                    _userInitials,
                    style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    _userName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Tombol "Kelola Profile"
            ElevatedButton.icon(
              icon: const Icon(Icons.person, size: 20),
              label: const Text("Kelola Profile"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InformasiDataDiriScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFC50000), // Merah maroon
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 0, // Hilangkan bayangan tombol
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? textColor,
      Color? iconColor}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(icon, color: iconColor ?? Colors.grey.shade700),
        title: Text(title,
            style: TextStyle(
                color: textColor ?? Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}