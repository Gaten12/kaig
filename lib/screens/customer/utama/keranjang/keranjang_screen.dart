import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/services/keranjang_service.dart';

import 'keranjang_pembayaran_screen.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final KeranjangService _keranjangService = KeranjangService();
  Stream<List<KeranjangModel>>? _keranjangStream;

  // State untuk menyimpan data dan pilihan
  List<KeranjangModel> _semuaItemKeranjang = [];
  List<String> _selectedItemsIds = [];
  bool _pilihSemua = false;

  // Tema warna kereta elegan
  static const Color primaryRed = Color(0xFFC50000);
  static const Color lightRed = Color(0xFFE53935);
  static const Color accentGold = Color(0xFFFFC107);
  static const Color warmGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF424242);
  static const Color lightGray = Color(0xFFE0E0E0);

  // Warna baru sesuai permintaan
  static const Color royalBlue = Color(0xFF0000CD); // Warna background tanda centang & angka
  static const Color checkoutButtonColor = Color(0xFF304FFE); // Warna tombol checkout

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _keranjangStream = _keranjangService.getKeranjangStream(user.uid);
    }
  }

  void _onPilihSemua(bool? value) {
    setState(() {
      _pilihSemua = value ?? false;
      if (_pilihSemua) {
        _selectedItemsIds =
            _semuaItemKeranjang.map((item) => item.id!).toList();
      } else {
        _selectedItemsIds.clear();
      }
    });
  }

  void _onItemSelect(String itemId) {
    setState(() {
      if (_selectedItemsIds.contains(itemId)) {
        _selectedItemsIds.remove(itemId);
      } else {
        _selectedItemsIds.add(itemId);
      }
      if (_selectedItemsIds.length == _semuaItemKeranjang.length &&
          _semuaItemKeranjang.isNotEmpty) {
        _pilihSemua = true;
      } else {
        _pilihSemua = false;
      }
    });
  }

  void _checkout() {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width for responsive SnackBar

    if (_selectedItemsIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: _responsiveIconSize(screenWidth, 20)),
              SizedBox(width: _responsiveFontSize(screenWidth, 12)),
              Expanded(child: Text("Pilih minimal satu pesanan untuk di-checkout", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)))),
            ],
          ),
          backgroundColor: primaryRed,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
          margin: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
        ),
      );
      return;
    }

    final itemsToCheckout = _semuaItemKeranjang
        .where((item) => _selectedItemsIds.contains(item.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              KeranjangPembayaranScreen(itemsToCheckout: itemsToCheckout)),
    );
  }

  // Helper method for responsive font sizes
  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) {
      return baseSize * 0.8; // Smaller for very small phones
    } else if (screenWidth < 600) {
      return baseSize; // Base size for phones
    } else if (screenWidth < 900) {
      return baseSize * 1.1; // Slightly larger for tablets
    } else {
      return baseSize * 1.2; // Even larger for desktops
    }
  }

  // Helper method for responsive icon sizes
  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) {
      return baseSize;
    } else if (screenWidth < 900) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // Helper method for responsive horizontal padding
  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) {
      return (screenWidth - 1000) / 2; // Center content for very large screens
    } else if (screenWidth > 600) {
      return 24.0; // Medium padding for tablets
    } else {
      return 16.0; // Standard padding for phones
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: warmGray,
      appBar: AppBar(
        title: Text(
          "Keranjang Belanja",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: _responsiveFontSize(screenWidth, 20),
          ),
        ),
        backgroundColor: primaryRed,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: _responsiveIconSize(screenWidth, 24)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryRed, lightRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<KeranjangModel>>(
        stream: _keranjangStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                    strokeWidth: _responsiveIconSize(screenWidth, 3),
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 16)),
                  Text(
                    "Memuat keranjang...",
                    style: TextStyle(
                      color: darkGray,
                      fontSize: _responsiveFontSize(screenWidth, 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: _responsiveIconSize(screenWidth, 64), color: primaryRed),
                  SizedBox(height: _responsiveFontSize(screenWidth, 16)),
                  Text(
                    "Terjadi kesalahan",
                    style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 18),
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 8)),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: Colors.grey[600], fontSize: _responsiveFontSize(screenWidth, 14)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            _semuaItemKeranjang = snapshot.data!;
            _selectedItemsIds.removeWhere(
                    (id) => !_semuaItemKeranjang.any((item) => item.id == id));
          }

          if (_semuaItemKeranjang.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 24)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: _responsiveFontSize(screenWidth, 20),
                          offset: Offset(0, _responsiveFontSize(screenWidth, 10)),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: _responsiveIconSize(screenWidth, 64),
                      color: primaryRed,
                    ),
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 24)),
                  Text(
                    "Keranjang Kosong",
                    style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 22),
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 8)),
                  Text(
                    "Belum ada tiket kereta yang dipilih",
                    style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 16),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header dengan pilih semua
              Container(
                margin: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: _responsiveFontSize(screenWidth, 10),
                      offset: Offset(0, _responsiveFontSize(screenWidth, 4)),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 20), vertical: _responsiveFontSize(screenWidth, 16)),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: _responsiveFontSize(screenWidth, 1.2) / _responsiveFontSize(screenWidth, 1), // Adjust scale dynamically
                        child: Checkbox(
                          value: _pilihSemua,
                          onChanged: _onPilihSemua,
                          activeColor: royalBlue, // Perubahan warna: background tanda centang
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 4)),
                          ),
                        ),
                      ),
                      SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                      Text(
                        "Pilih Semua",
                        style: TextStyle(
                          fontSize: _responsiveFontSize(screenWidth, 16),
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 6)),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)),
                        ),
                        child: Text(
                          "${_semuaItemKeranjang.length} item",
                          style: TextStyle(
                            color: primaryRed,
                            fontWeight: FontWeight.w600,
                            fontSize: _responsiveFontSize(screenWidth, 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // List items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: _responsiveHorizontalPadding(screenWidth)),
                  itemCount: _semuaItemKeranjang.length,
                  itemBuilder: (context, index) {
                    final item = _semuaItemKeranjang[index];
                    return _buildKeranjangItemCard(item, screenWidth);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutButton(screenWidth),
    );
  }

  Widget _buildKeranjangItemCard(KeranjangModel item, double screenWidth) {
    final isSelected = _selectedItemsIds.contains(item.id);

    return Container(
      margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)),
        border: Border.all(
          color: isSelected ? royalBlue : Colors.transparent, // Perubahan warna border saat terpilih
          width: _responsiveFontSize(screenWidth, 2),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? royalBlue.withOpacity(0.15) // Perubahan warna shadow saat terpilih
                : Colors.black.withOpacity(0.08),
            blurRadius: _responsiveFontSize(screenWidth, isSelected ? 15 : 10),
            offset: Offset(0, _responsiveFontSize(screenWidth, 4)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan checkbox dan countdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: _responsiveFontSize(screenWidth, 1.2) / _responsiveFontSize(screenWidth, 1),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _onItemSelect(item.id!),
                    activeColor: royalBlue, // Perubahan warna: background tanda centang
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 4)),
                    ),
                  ),
                ),
                SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                Expanded(
                  child: _SisaWaktuWidget(
                      batasWaktu: item.batasWaktuPembayaran.toDate(), screenWidth: screenWidth),
                ),
              ],
            ),

            SizedBox(height: _responsiveFontSize(screenWidth, 16)),

            // Info kereta
            Container(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
              decoration: BoxDecoration(
                color: warmGray,
                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
                border: Border.all(color: lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 8)),
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 8)),
                        ),
                        child: Icon(
                          Icons.train,
                          color: Colors.white,
                          size: _responsiveIconSize(screenWidth, 20),
                        ),
                      ),
                      SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${item.jadwalDipesan.namaKereta}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _responsiveFontSize(screenWidth, 16),
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "ID: ${item.jadwalDipesan.idKereta}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: _responsiveFontSize(screenWidth, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: _responsiveFontSize(screenWidth, 12)),

                  // Rute
                  Container(
                    padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 12)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                item.jadwalDipesan.idStasiunAsal,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _responsiveFontSize(screenWidth, 14),
                                ),
                              ),
                              SizedBox(height: _responsiveFontSize(screenWidth, 4)),
                              Text(
                                "Asal",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: _responsiveFontSize(screenWidth, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 12)),
                          child: Row(
                            children: [
                              Container(
                                width: _responsiveFontSize(screenWidth, 8),
                                height: _responsiveFontSize(screenWidth, 8),
                                decoration: BoxDecoration(
                                  color: primaryRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: _responsiveFontSize(screenWidth, 40),
                                height: _responsiveFontSize(screenWidth, 2),
                                color: primaryRed,
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: primaryRed,
                                size: _responsiveIconSize(screenWidth, 16),
                              ),
                              Container(
                                width: _responsiveFontSize(screenWidth, 40),
                                height: _responsiveFontSize(screenWidth, 2),
                                color: primaryRed,
                              ),
                              Container(
                                width: _responsiveFontSize(screenWidth, 8),
                                height: _responsiveFontSize(screenWidth, 8),
                                decoration: BoxDecoration(
                                  color: primaryRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                item.jadwalDipesan.idStasiunTujuan,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _responsiveFontSize(screenWidth, 14),
                                ),
                              ),
                              SizedBox(height: _responsiveFontSize(screenWidth, 4)),
                              Text(
                                "Tujuan",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: _responsiveFontSize(screenWidth, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: _responsiveFontSize(screenWidth, 16)),

            // Expansion tile untuk penumpang
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
                border: Border.all(color: lightGray),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(Icons.people, color: primaryRed, size: _responsiveIconSize(screenWidth, 20)),
                    SizedBox(width: _responsiveFontSize(screenWidth, 8)),
                    Text(
                      "${item.penumpang.length} Penumpang",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: _responsiveFontSize(screenWidth, 16),
                      ),
                    ),
                  ],
                ),
                tilePadding:
                EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16), vertical: _responsiveFontSize(screenWidth, 4)),
                childrenPadding:
                EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16), vertical: _responsiveFontSize(screenWidth, 8)),
                children: item.penumpang
                    .map((p) => Container(
                  margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 8)),
                  padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 12)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 10)),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 6)),
                        decoration: BoxDecoration(
                          color: accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 6)),
                        ),
                        child: Icon(
                          Icons.person,
                          color: accentGold.withOpacity(0.8),
                          size: _responsiveIconSize(screenWidth, 16),
                        ),
                      ),
                      SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['nama']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: _responsiveFontSize(screenWidth, 14),
                              ),
                            ),
                            Text(
                              "Kursi: ${p['kursi']!}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: _responsiveFontSize(screenWidth, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // FIX OVERFLOW HERE - Already had FittedBox
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 4)),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 6)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            NumberFormat.currency(
                                locale: 'id_ID', symbol: 'Rp ')
                                .format(item.kelasDipilih.harga),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _responsiveFontSize(screenWidth, 12),
                              color: primaryRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),

            SizedBox(height: _responsiveFontSize(screenWidth, 16)),

            // Total bayar
            Container(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryRed.withOpacity(0.1),
                    lightRed.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
                border: Border.all(color: primaryRed.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Pembayaran",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: _responsiveFontSize(screenWidth, 16),
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')
                        .format(item.totalBayar),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _responsiveFontSize(screenWidth, 18),
                      color: royalBlue, // Perubahan warna di sini
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(double screenWidth) {
    if (_selectedItemsIds.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: _responsiveFontSize(screenWidth, 10),
            offset: Offset(0, _responsiveFontSize(screenWidth, -5)),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            // Menghapus gradient dan menggunakan warna solid untuk tombol checkout
            color: checkoutButtonColor, // Perubahan warna: tombol checkout
            borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 16)),
            boxShadow: [
              BoxShadow(
                color: checkoutButtonColor.withOpacity(0.3), // Perubahan warna shadow
                blurRadius: _responsiveFontSize(screenWidth, 10),
                offset: Offset(0, _responsiveFontSize(screenWidth, 4)),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Tetap transparent agar warna dari container terlihat
              shadowColor: Colors.transparent,
              minimumSize: Size(double.infinity, _responsiveFontSize(screenWidth, 56)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 16)),
              ),
            ),
            onPressed: _checkout,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment,
                  color: Colors.white,
                  size: _responsiveIconSize(screenWidth, 24),
                ),
                SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                Text(
                  "Checkout (${_selectedItemsIds.length} item)",
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SisaWaktuWidget extends StatefulWidget {
  final DateTime batasWaktu;
  final double screenWidth; // Pass screenWidth for responsiveness
  const _SisaWaktuWidget({required this.batasWaktu, required this.screenWidth});

  @override
  State<_SisaWaktuWidget> createState() => _SisaWaktuWidgetState();
}

class _SisaWaktuWidgetState extends State<_SisaWaktuWidget> {
  late Timer _timer;
  Duration _sisaWaktu = Duration.zero;

  // Helper method for responsive font sizes (copied for internal use)
  double _responsiveFontSizeInternal(double screenWidth, double baseSize) {
    if (screenWidth < 360) {
      return baseSize * 0.8;
    } else if (screenWidth < 600) {
      return baseSize;
    } else if (screenWidth < 900) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // Helper method for responsive icon sizes (copied for internal use)
  double _responsiveIconSizeInternal(double screenWidth, double baseSize) {
    if (screenWidth < 600) {
      return baseSize;
    } else if (screenWidth < 900) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }


  @override
  void initState() {
    super.initState();
    _sisaWaktu = widget.batasWaktu.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _sisaWaktu = widget.batasWaktu.difference(DateTime.now());
      });
      if (_sisaWaktu.isNegative) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sisaWaktu.isNegative) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: _responsiveFontSizeInternal(widget.screenWidth, 16), vertical: _responsiveFontSizeInternal(widget.screenWidth, 8)),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_responsiveFontSizeInternal(widget.screenWidth, 12)),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: _responsiveIconSizeInternal(widget.screenWidth, 18)),
            SizedBox(width: _responsiveFontSizeInternal(widget.screenWidth, 8)),
            Text(
              "Waktu Habis",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: _responsiveFontSizeInternal(widget.screenWidth, 14),
              ),
            ),
          ],
        ),
      );
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_sisaWaktu.inHours);
    final minutes = twoDigits(_sisaWaktu.inMinutes.remainder(60));
    final seconds = twoDigits(_sisaWaktu.inSeconds.remainder(60));

    Color timerColor = Colors.orange; // Perubahan warna: angka timer
    if (_sisaWaktu.inHours < 1) {
      timerColor = Colors.orange;
    }
    if (_sisaWaktu.inMinutes < 15) {
      timerColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: _responsiveFontSizeInternal(widget.screenWidth, 16), vertical: _responsiveFontSizeInternal(widget.screenWidth, 8)),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_responsiveFontSizeInternal(widget.screenWidth, 12)),
        border: Border.all(color: timerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, color: timerColor, size: _responsiveIconSizeInternal(widget.screenWidth, 18)),
          SizedBox(width: _responsiveFontSizeInternal(widget.screenWidth, 8)),
          Text(
            "Sisa waktu:",
            style: TextStyle(
              fontSize: _responsiveFontSizeInternal(widget.screenWidth, 12),
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: _responsiveFontSizeInternal(widget.screenWidth, 6)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSizeInternal(widget.screenWidth, 8), vertical: _responsiveFontSizeInternal(widget.screenWidth, 2)),
            decoration: BoxDecoration(
              color: timerColor,
              borderRadius: BorderRadius.circular(_responsiveFontSizeInternal(widget.screenWidth, 6)),
            ),
            child: Text(
              "$hours:$minutes:$seconds",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _responsiveFontSizeInternal(widget.screenWidth, 12),
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
