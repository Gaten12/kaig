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
    if (_selectedItemsIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Pilih minimal satu pesanan untuk di-checkout"),
            ],
          ),
          backgroundColor: primaryRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Scaffold(
      backgroundColor: warmGray,
      appBar: AppBar(
        title: const Text(
          "Keranjang Belanja",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Memuat keranjang...",
                    style: TextStyle(
                      color: darkGray,
                      fontSize: 16,
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
                  Icon(Icons.error_outline, size: 64, color: primaryRed),
                  const SizedBox(height: 16),
                  Text(
                    "Terjadi kesalahan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: Colors.grey[600]),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.1).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: primaryRed,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Keranjang Kosong",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Belum ada tiket kereta yang dipilih",
                    style: TextStyle(
                      fontSize: 16,
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
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.08).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: _pilihSemua,
                          onChanged: _onPilihSemua,
                          activeColor: primaryRed,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Pilih Semua",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryRed.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_semuaItemKeranjang.length} item",
                          style: TextStyle(
                            color: primaryRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _semuaItemKeranjang.length,
                  itemBuilder: (context, index) {
                    final item = _semuaItemKeranjang[index];
                    return _buildKeranjangItemCard(item);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutButton(),
    );
  }

  Widget _buildKeranjangItemCard(KeranjangModel item) {
    final isSelected = _selectedItemsIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? primaryRed : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? primaryRed.withAlpha((255 * 0.15).round())
                : Colors.black.withAlpha((255 * 0.08).round()),
            blurRadius: isSelected ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan checkbox dan countdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _onItemSelect(item.id!),
                    activeColor: primaryRed,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SisaWaktuWidget(
                      batasWaktu: item.batasWaktuPembayaran.toDate()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info kereta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warmGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.train,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${item.jadwalDipesan.namaKereta}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "ID: ${item.jadwalDipesan.idKereta}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Rute
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                item.jadwalDipesan.idStasiunAsal,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Asal",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: primaryRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 2,
                                color: primaryRed,
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: primaryRed,
                                size: 16,
                              ),
                              Container(
                                width: 40,
                                height: 2,
                                color: primaryRed,
                              ),
                              Container(
                                width: 8,
                                height: 8,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tujuan",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
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

            const SizedBox(height: 16),

            // Expansion tile untuk penumpang
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightGray),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(Icons.people, color: primaryRed, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "${item.penumpang.length} Penumpang",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: item.penumpang
                    .map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accentGold.withAlpha((255 * 0.2).round()),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: accentGold.withAlpha((255 * 0.8).round()),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['nama']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Kursi: ${p['kursi']!}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryRed.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  NumberFormat.currency(
                                          locale: 'id_ID', symbol: 'Rp ')
                                      .format(item.kelasDipilih.harga),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: primaryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Total bayar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryRed.withAlpha((255 * 0.1).round()),
                    lightRed.withAlpha((255 * 0.05).round())
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryRed.withAlpha((255 * 0.3).round())),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Pembayaran",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')
                        .format(item.totalBayar),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryRed,
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

  Widget _buildCheckoutButton() {
    if (_selectedItemsIds.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryRed, lightRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryRed.withAlpha((255 * 0.3).round()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _checkout,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.payment,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Checkout (${_selectedItemsIds.length} item)",
                  style: const TextStyle(
                    fontSize: 18,
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
  const _SisaWaktuWidget({required this.batasWaktu});

  @override
  State<_SisaWaktuWidget> createState() => _SisaWaktuWidgetState();
}

class _SisaWaktuWidgetState extends State<_SisaWaktuWidget> {
  late Timer _timer;
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
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sisaWaktu.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withAlpha((255 * 0.3).round())),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text(
              "Waktu Habis",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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

    Color timerColor = Colors.green;
    if (_sisaWaktu.inHours < 1) {
      timerColor = Colors.orange;
    }
    if (_sisaWaktu.inMinutes < 15) {
      timerColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: timerColor.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timerColor.withAlpha((255 * 0.3).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, color: timerColor, size: 18),
          const SizedBox(width: 8),
          Text(
            "Sisa waktu:",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: timerColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "$hours:$minutes:$seconds",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
