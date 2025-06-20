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

  // Update widget options untuk menggunakan callback
  List<Widget> get _widgetOptions => <Widget>[
    BerandaContent(
        onNavigateToTab: _onItemTapped), // <--- Gunakan BerandaContent dari file terpisah
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Halo, $_userName!'
              : _getAppBarTitle(_selectedIndex),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
          if (_selectedIndex == 0) ...[ // Use a spread operator if multiple widgets
            // Tombol Chat AI
            Container(
              margin: const EdgeInsets.only(right: 8), // Adjusted margin
              decoration: BoxDecoration(
                color: Colors.blue[100], // New background color
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: IconButton(
                icon: Icon(Icons.chat_outlined, color: Colors.blue[700]), // New icon and color
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()), // Navigate to ChatScreen
                  );
                },
              ),
            ),
            // Tombol Keranjang
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
              color: Colors.grey.withOpacity(0.1),
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