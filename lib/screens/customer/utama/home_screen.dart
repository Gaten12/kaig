import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/keranjang_screen.dart'; // Import halaman keranjang
import 'package:kaig/screens/customer/utama/tiket_saya_screen.dart';
import '../../../models/passenger_model.dart';
import '../../../services/auth_service.dart';
import 'PesanTiketScreen.dart';
import 'account_screen.dart';


class BerandaContent extends StatelessWidget {
  const BerandaContent({super.key});

  Widget _buildMenuItem(BuildContext context,
      {required IconData iconData,
        required String label,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 35,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(iconData, size: 30, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8.0),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        const Text(
          'Menu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildMenuItem(
              context,
              iconData: Icons.tram_outlined,
              label: 'Pesan Tiket',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PesanTiketScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              iconData: Icons.directions_transit_outlined,
              label: 'Commuter Line',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fitur Commuter Line belum tersedia.')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Promo Terbaru',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur Lihat Semua Promo belum tersedia.')),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Center(
            child: Text(
              'Gambar Promo',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }
}


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

  static const List<Widget> _widgetOptions = <Widget>[
    BerandaContent(),
    PesanTiketScreen(),
    TiketSayaScreen(),
    Center(child: Text('Halaman Promo (Segera Hadir)')),
    AccountScreen(),
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
      PassengerModel? primaryPassenger = await _authService.getPrimaryPassenger(firebaseUser.uid);
      String displayName = "Pengguna";

      if (primaryPassenger != null && primaryPassenger.namaLengkap.isNotEmpty) {
        displayName = primaryPassenger.namaLengkap;
      } else if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
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
        title: Text(_getAppBarTitle(_selectedIndex)),
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              // --- PERBAIKAN DI SINI ---
              onPressed: () {
                // Arahkan ke halaman keranjang
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KeranjangScreen()),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.train_outlined),
            activeIcon: Icon(Icons.train),
            label: 'Kereta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Tiket Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Promo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Selamat Datang, $_userName';
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