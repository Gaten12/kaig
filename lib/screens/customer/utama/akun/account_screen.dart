import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/akun/tentang_aplikasi.dart';
import 'package:kaig/screens/customer/utama/riwayat/riwayat_transaksi_screen.dart';
import 'package:flutter/cupertino.dart'; // Digunakan untuk CupertinoAlertDialog
import '../../../../models/passenger_model.dart';
import '../../../../services/auth_service.dart';
import '../../../login/login_screen.dart';
import '../pembayaran/metode_pembayaran_screen.dart';
import 'ganti_kata_sandi_screen.dart';
import 'informasi_data_diri_screen.dart';
import 'konfirmasi_password_screen.dart';
import 'list_penumpang_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
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
    String displayNameToShow = "Pengguna";

    if (firebaseUser != null) {
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
    }

    if (mounted) {
      setState(() {
        _userName = displayNameToShow;
      });
    }
  }

  // Fungsi ini diperbaiki dengan menambahkan 'async'
  void _navigasiKeKelolaAkun() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => KonfirmasiPasswordScreen(
        onPasswordConfirmed: () async { // <-- TAMBAHKAN ASYNC DI SINI
          Navigator.of(context).pop(); // Tutup layar konfirmasi password
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InformasiDataDiriScreen()),
          );
          _loadUserData();
        },
      ),
    ));
  }


  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildDialogContent(context),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.exit_to_app_rounded,
              color: const Color(0xFFC50000),
              size: isSmallScreen ? 35 : 40,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            'Log Out Akun?',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Apakah anda yakin ingin keluar dari akun ini?',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => LoginEmailScreen()),
                            (Route<dynamic> route) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC50000),
                    side: const BorderSide(color: Color(0xFFC50000), width: 1.5),
                    padding:
                    EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Ya, Log Out',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF304FFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                    EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tidak',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context, isSmallScreen),
            _buildSectionTitle("Informasi Pengguna", isSmallScreen),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(context, icon: Icons.lock_outline, title: "Ganti Kata Sandi", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GantiKataSandiScreen())), isSmallScreen: isSmallScreen),
                  Divider(height: 1, thickness: 1, indent: isSmallScreen ? 50 : 56, endIndent: 16, color: Colors.grey[300]),
                  _buildMenuItem(context, icon: Icons.receipt_long_outlined, title: "Riwayat Transaksi", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatTransaksiScreen())), isSmallScreen: isSmallScreen),
                  Divider(height: 1, thickness: 1, indent: isSmallScreen ? 50 : 56, endIndent: 16, color: Colors.grey[300]),
                  _buildMenuItem(context, icon: Icons.people_alt_outlined, title: "Daftar Penumpang", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListPenumpangScreen())), isSmallScreen: isSmallScreen),
                  Divider(height: 1, thickness: 1, indent: isSmallScreen ? 50 : 56, endIndent: 16, color: Colors.grey[300]),
                  _buildMenuItem(context, icon: Icons.payment_outlined, title: "Metode Pembayaran Saya", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MetodePembayaranScreen())), isSmallScreen: isSmallScreen),
                ],
              ),
            ),
            _buildSectionTitle("Lainnya", isSmallScreen),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(context, icon: Icons.info_outline, title: "Tentang Aplikasi TrainOrder", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TentangAplikasiScreen())), isSmallScreen: isSmallScreen),
                  Divider(height: 1, thickness: 1, indent: isSmallScreen ? 50 : 56, endIndent: 16, color: Colors.grey[300]),
                  _buildMenuItem(context, icon: Icons.logout, title: "Log Out", textColor: Colors.red, iconColor: Colors.red, onTap: _showLogoutConfirmationDialog, isSmallScreen: isSmallScreen),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + (isSmallScreen ? 16 : 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isSmallScreen) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(isSmallScreen ? 12.0 : 16.0, statusBarHeight + (isSmallScreen ? 12.0 : 16.0), isSmallScreen ? 12.0 : 16.0, isSmallScreen ? 12.0 : 16.0),
      color: const Color(0xFFB71C1C),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10.0 : 12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 25 : 30,
                  backgroundColor: const Color(0xFFC50000),
                  child: Text(
                    _userInitials,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12.0 : 16.0),
                Expanded(
                  child: Text(
                    _userName,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12.0 : 16.0),
            ElevatedButton.icon(
              icon: Icon(Icons.person, size: isSmallScreen ? 18 : 20),
              label: Text("Kelola Profile", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
              onPressed: _navigasiKeKelolaAkun,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFC50000),
                minimumSize: Size(double.infinity, isSmallScreen ? 35 : 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 6.0 : 8.0),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isSmallScreen ? 16.0 : 20.0, isSmallScreen ? 20.0 : 24.0, isSmallScreen ? 16.0 : 20.0, isSmallScreen ? 6.0 : 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? textColor,
        Color? iconColor,
        required bool isSmallScreen}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 20.0),
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: isSmallScreen ? 20 : 24),
      title: Text(title,
          style: TextStyle(
              color: textColor ?? Colors.black87,
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w500)),
      trailing:
      Icon(Icons.arrow_forward_ios, size: isSmallScreen ? 14 : 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}