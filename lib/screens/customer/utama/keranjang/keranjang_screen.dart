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

  List<KeranjangModel> _semuaItemKeranjang = [];
  List<String> _selectedItemsIds = [];
  bool _pilihSemua = false;

  static const Color primaryRed = Color(0xFFC50000);
  static const Color lightRed = Color(0xFFE53935);
  static const Color accentGold = Color(0xFFFFC107);
  static const Color warmGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF424242);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color royalBlue = Color(0xFF0000CD);
  static const Color checkoutButtonColor = Color(0xFF304FFE);

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
      _selectedItemsIds = _pilihSemua
          ? _semuaItemKeranjang.map((item) => item.id!).toList()
          : [];
    });
  }

  void _onItemSelect(String itemId) {
    setState(() {
      if (_selectedItemsIds.contains(itemId)) {
        _selectedItemsIds.remove(itemId);
      } else {
        _selectedItemsIds.add(itemId);
      }
      _pilihSemua = _semuaItemKeranjang.isNotEmpty &&
          _selectedItemsIds.length == _semuaItemKeranjang.length;
    });
  }

  void _checkout() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (_selectedItemsIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: isSmallScreen ? 20 : 24),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                  child: Text("Pilih minimal satu pesanan untuk di-checkout",
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16))),
            ],
          ),
          backgroundColor: primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12)),
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
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

  @override
  Widget build(BuildContext context) {
    // Definisikan variabel responsif di sini
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Nilai-nilai responsif
    final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    final double verticalPadding = isSmallScreen ? 12.0 : 16.0;
    final double titleFontSize = isSmallScreen ? 18.0 : 22.0;
    final double bodyFontSize = isSmallScreen ? 14.0 : 16.0;
    final double smallFontSize = isSmallScreen ? 12.0 : 14.0;
    final double iconSize = isSmallScreen ? 22.0 : 26.0;
    final double smallIconSize = isSmallScreen ? 18.0 : 20.0;
    final double cardRadius = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: warmGray,
      appBar: AppBar(
        title: Text(
          "Keranjang Belanja",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: primaryRed,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: iconSize),
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
                    strokeWidth: isSmallScreen ? 3 : 4,
                  ),
                  SizedBox(height: verticalPadding),
                  Text("Memuat keranjang...",
                      style: TextStyle(
                          color: darkGray,
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: isSmallScreen ? 60 : 80, color: primaryRed),
                  SizedBox(height: verticalPadding),
                  Text("Terjadi kesalahan",
                      style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: darkGray)),
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
                    padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.shopping_cart_outlined,
                        size: isSmallScreen ? 64 : 80, color: primaryRed),
                  ),
                  SizedBox(height: verticalPadding * 1.5),
                  Text("Keranjang Kosong",
                      style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: darkGray)),
                  SizedBox(height: verticalPadding / 2),
                  Text("Belum ada tiket kereta yang dipilih",
                      style: TextStyle(
                          fontSize: bodyFontSize, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: verticalPadding),
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: verticalPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: isSmallScreen ? 1.1 : 1.3,
                      child: Checkbox(
                        value: _pilihSemua,
                        onChanged: _onPilihSemua,
                        activeColor: royalBlue,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text("Pilih Semua",
                        style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: darkGray)),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 10 : 12,
                          vertical: isSmallScreen ? 5 : 6),
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(isSmallScreen ? 15 : 20),
                      ),
                      child: Text("${_semuaItemKeranjang.length} item",
                          style: TextStyle(
                              color: primaryRed,
                              fontWeight: FontWeight.w600,
                              fontSize: smallFontSize)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: _semuaItemKeranjang.length,
                  itemBuilder: (context, index) {
                    final item = _semuaItemKeranjang[index];
                    return _buildKeranjangItemCard(item, isSmallScreen);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutButton(isSmallScreen),
    );
  }

  Widget _buildKeranjangItemCard(KeranjangModel item, bool isSmallScreen) {
    final isSelected = _selectedItemsIds.contains(item.id);
    final double cardPadding = isSmallScreen ? 16.0 : 20.0;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: isSelected ? royalBlue : Colors.transparent,
          width: isSmallScreen ? 2 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? royalBlue.withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: isSmallScreen ? 1.1 : 1.3,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _onItemSelect(item.id!),
                    activeColor: royalBlue,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: _SisaWaktuWidget(
                      batasWaktu: item.batasWaktuPembayaran.toDate(),
                      isSmallScreen: isSmallScreen),
                ),
              ],
            ),
            SizedBox(height: cardPadding),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                  color: warmGray,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  border: Border.all(color: lightGray)),
              child: Column(
                children: [
                  Row(children: [
                    Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius:
                            BorderRadius.circular(isSmallScreen ? 8 : 10)),
                        child: Icon(Icons.train,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24)),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Expanded(
                        child: Text(item.jadwalDipesan.namaKereta,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 16 : 18,
                                color: Colors.black87))),
                  ]),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    child: Row(children: [
                      Expanded(
                          child: Text(item.jadwalDipesan.idStasiunAsal,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14 : 16))),
                      Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12),
                          child: Icon(Icons.arrow_forward,
                              color: primaryRed,
                              size: isSmallScreen ? 18 : 22)),
                      Expanded(
                          child: Text(item.jadwalDipesan.idStasiunTujuan,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14 : 16))),
                    ]),
                  ),
                ],
              ),
            ),
            SizedBox(height: cardPadding),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                border: Border.all(color: lightGray),
              ),
              child: ExpansionTile(
                title: Row(children: [
                  Icon(Icons.people,
                      color: primaryRed, size: isSmallScreen ? 20 : 24),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Text("${item.penumpang.length} Penumpang",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 15 : 17)),
                ]),
                children: item.penumpang
                    .map((p) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 12 : 16,
                      0,
                      isSmallScreen ? 12 : 16,
                      isSmallScreen ? 8 : 12),
                  child: Row(children: [
                    Icon(Icons.person,
                        color: Colors.grey,
                        size: isSmallScreen ? 18 : 20),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                        child: Text(p['nama']!,
                            style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16))),
                    Text("Kursi: ${p['kursi']!}",
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isSmallScreen ? 13 : 15))
                  ]),
                ))
                    .toList(),
              ),
            ),
            SizedBox(height: cardPadding),
            Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: royalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Pembayaran",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 15 : 17)),
                      Text(
                          NumberFormat.currency(
                              locale: 'id_ID', symbol: 'Rp ')
                              .format(item.totalBayar),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 16 : 18,
                              color: royalBlue)),
                    ])),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(bool isSmallScreen) {
    if (_selectedItemsIds.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: checkoutButtonColor,
            minimumSize: Size(double.infinity, isSmallScreen ? 50 : 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            ),
          ),
          onPressed: _checkout,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment,
                  color: Colors.white, size: isSmallScreen ? 22 : 26),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Text(
                "Checkout (${_selectedItemsIds.length} item)",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SisaWaktuWidget extends StatefulWidget {
  final DateTime batasWaktu;
  final bool isSmallScreen;
  const _SisaWaktuWidget(
      {required this.batasWaktu, required this.isSmallScreen});

  @override
  State<_SisaWaktuWidget> createState() => _SisaWaktuWidgetState();
}

class _SisaWaktuWidgetState extends State<_SisaWaktuWidget> {
  Timer? _timer;
  Duration _sisaWaktu = Duration.zero;

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
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = widget.isSmallScreen ? 12 : 14;
    final double iconSize = widget.isSmallScreen ? 16 : 18;

    if (_sisaWaktu.isNegative) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: iconSize),
          const SizedBox(width: 8),
          Text("Waktu Habis",
              style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize)),
        ],
      );
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_sisaWaktu.inHours);
    final minutes = twoDigits(_sisaWaktu.inMinutes.remainder(60));
    final seconds = twoDigits(_sisaWaktu.inSeconds.remainder(60));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, color: Colors.orange, size: iconSize),
        const SizedBox(width: 8),
        Text("Sisa waktu:",
            style: TextStyle(fontSize: fontSize, color: Colors.grey[700])),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "$hours:$minutes:$seconds",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: Colors.white,
                fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}