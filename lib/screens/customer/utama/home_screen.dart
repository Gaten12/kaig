import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaig/screens/customer/utama/promo/promo_screen.dart';
import 'package:kaig/screens/customer/utama/riwayat/tiket_saya_screen.dart';
import '../../../models/passenger_model.dart';
import '../../../services/auth_service.dart';
import 'beranda_content.dart';
import 'chat/chat_screen.dart';
import 'tiket/PesanTiketScreen.dart';
import 'akun/account_screen.dart';
import 'keranjang/keranjang_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  final AuthService _authService = AuthService();
  String _userName = "Pengguna";

  List<Widget> get _widgetOptions => <Widget>[
    BerandaContent(onNavigateToTab: _onItemTapped),
    const PesanTiketScreen(),
    const TiketSayaScreen(),
    const PromoScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      PassengerModel? primaryPassenger =
      await _authService.getPrimaryPassenger(firebaseUser.uid);
      String displayName = "Pengguna";

      if (primaryPassenger != null && primaryPassenger.namaLengkap.isNotEmpty) {
        displayName = primaryPassenger.namaLengkap;
      } else if (firebaseUser.displayName != null &&
          firebaseUser.displayName!.isNotEmpty) {
        displayName = firebaseUser.displayName!;
      } else if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        displayName = firebaseUser.email!.split('@')[0];
      }

      if (mounted) {
        setState(() {
          _userName = displayName;
          if (_userName.length > 15) {
            _userName = "${_userName.substring(0, 12)}...";
          }
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- GANTI FUNGSI INI DENGAN VERSI BARU YANG LEBIH BAIK ---
  void _handlePopAttempt(bool didPop) {
    if (didPop) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Pengguna harus memilih salah satu tombol
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: contentBox(context),
        );
      },
    );
  }

  // --- WIDGET UNTUK KONTEN DIALOG KUSTOM ---
  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Agar ukuran Column mengikuti konten
        children: <Widget>[
          // Ikon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.exit_to_app_rounded,
              color: Color(0xFFC50000),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          // Judul
          const Text(
            'Keluar Aplikasi?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Deskripsi
          Text(
            'Apakah Anda yakin ingin keluar dari Simulasi Train Order?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Tombol Aksi
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => SystemNavigator.pop(), // Tutup aplikasi
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC50000),
                    side: const BorderSide(color: Color(0xFFC50000), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ya, Keluar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(), // Tutup dialog
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF304FFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tidak',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic _result) {
        _handlePopAttempt(didPop);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? 'Halo, $_userName!'
                : _getAppBarTitle(_selectedIndex),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFC50000),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
          actions: [
            if (_selectedIndex == 0) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: IconButton(
                  icon: Icon(Icons.chat_outlined, color: Colors.blue[700]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatScreen()),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: IconButton(
                  icon: Icon(Icons.shopping_cart_outlined, color: Colors.grey[700]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const KeranjangScreen()),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha((255 * 0.1).round()),
                blurRadius: 20,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.train_outlined),
                    activeIcon: Icon(Icons.train_rounded),
                    label: 'Kereta',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.confirmation_number_outlined),
                    activeIcon: Icon(Icons.confirmation_number_rounded),
                    label: 'Tiket Saya',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.local_offer_outlined),
                    activeIcon: Icon(Icons.local_offer_rounded),
                    label: 'Promo',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Akun',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: const Color(0xFF2196F3),
                unselectedItemColor: Colors.grey[500],
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                onTap: _onItemTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Halo, $_userName!';
      case 1:
        return 'Pesan Tiket Kereta';
      case 2:
        return 'Tiket Saya';
      case 3:
        return 'Promo';
      case 4:
        return 'Akun Saya';
      default:
        return 'TrainOrder';
    }
  }
}