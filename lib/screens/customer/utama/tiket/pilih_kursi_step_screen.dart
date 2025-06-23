import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pembayaran_screen.dart';
import 'package:kaig/screens/customer/utama/tiket/pilih_gerbong_screen.dart';

import 'DataPenumpangScreen.dart'; // Import ini tetap diperlukan untuk PenumpangInputData


class PilihKursiStepScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi;

  const PilihKursiStepScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.dataPenumpangList,
    required this.jumlahBayi,
  });

  @override
  State<PilihKursiStepScreen> createState() => _PilihKursiStepScreenState();
}

class _PilihKursiStepScreenState extends State<PilihKursiStepScreen>
    with TickerProviderStateMixin {
  // Menyimpan kursi yang dipilih untuk setiap penumpang
  late Map<int, String> _kursiTerpilih;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color Constants - Tema Kereta Elegan
  static const Color primaryTrainColor = Color(0xFFC50000);
  static const Color accentBlueColor = Color(0xFF1976D2);
  static const Color backgroundGray = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color warningOrange = Color(0xFFE67E22);

  @override
  void initState() {
    super.initState();
    _kursiTerpilih = {};

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pilihKursiUntukPenumpang(int indexPenumpang) async {
    final String? hasilPilihKursi = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PilihGerbongScreen(
          jadwalDipesan: widget.jadwalDipesan,
          kelasDipilih: widget.kelasDipilih,
          penumpangSaatIni: widget.dataPenumpangList[indexPenumpang],
          kursiYangSudahDipilihGrup: _kursiTerpilih.values
              .where((k) => k != _kursiTerpilih[indexPenumpang])
              .toList(),
        ),
      ),
    );

    if (hasilPilihKursi != null && mounted) {
      setState(() {
        _kursiTerpilih.removeWhere((key, value) => value == hasilPilihKursi);
        _kursiTerpilih[indexPenumpang] = hasilPilihKursi;
      });
    }
  }

  void _lanjutkanKePembayaran() {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width for responsive SnackBar

    if (_kursiTerpilih.length < widget.dataPenumpangList.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: _responsiveIconSize(screenWidth, 20)),
              SizedBox(width: _responsiveFontSize(screenWidth, 12)),
              Expanded(child: Text('Harap pilih kursi untuk semua penumpang.', style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)))),
            ],
          ),
          backgroundColor: warningOrange,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
          margin: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PembayaranScreen(
          jadwalDipesan: widget.jadwalDipesan,
          kelasDipilih: widget.kelasDipilih,
          dataPenumpangList: widget.dataPenumpangList,
          kursiTerpilih: _kursiTerpilih,
          jumlahBayi: widget.jumlahBayi,
        ),
      ),
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
      backgroundColor: backgroundGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFC50000), // Merah sesuai gambar
        foregroundColor: Colors.white, // Teks putih
        title: Text( // Judul "Pesan Tiket"
          "Pesan Tiket",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: _responsiveFontSize(screenWidth, 18), // Responsive font size
          ),
        ),
        // No centerTitle for app bar as per image
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_responsiveFontSize(screenWidth, 8.0)), // Responsive height for progress bar
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: _responsiveHorizontalPadding(screenWidth)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 4)), // Responsive border radius
              child: LinearProgressIndicator(
                value: 0.67, // Step 2 dari 3
                backgroundColor: Colors.grey[200],
                valueColor:
                const AlwaysStoppedAnimation<Color>(const Color(0xFF0000CD)), // Use orange for progress as per image
                minHeight: _responsiveFontSize(screenWidth, 6), // Responsive min height
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)), // Responsive padding
          children: [
            _buildStepHeader(screenWidth),
            SizedBox(height: _responsiveFontSize(screenWidth, 24.0)), // Responsive spacing
            _buildInfoKeretaCard(screenWidth),
            SizedBox(height: _responsiveFontSize(screenWidth, 24.0)), // Responsive spacing
            _buildPenumpangSection(screenWidth),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(screenWidth),
    );
  }

  Widget _buildStepHeader(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 10.0), horizontal: _responsiveFontSize(screenWidth, 16.0)), // Responsive padding
      decoration: BoxDecoration(
        color: Colors.deepOrange, // Warna oranye sesuai gambar
        borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 8.0)), // Responsive border radius
        // Menghilangkan gradient, border, dan shadow
      ),
      child: Text(
        "2. Pilih Kursi", // Teks untuk langkah 2
        style: TextStyle(
          fontSize: _responsiveFontSize(screenWidth, 18), // Responsive font size
          fontWeight: FontWeight.bold,
          color: Colors.white, // Warna teks putih
        ),
      ),
    );
  }

  Widget _buildInfoKeretaCard(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)), // Responsive border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _responsiveFontSize(screenWidth, 20), // Responsive blur radius
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 24.0)), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 8)), // Responsive padding
                  decoration: BoxDecoration(
                    color: primaryTrainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)), // Responsive border radius
                  ),
                  child: Icon(
                    Icons.train,
                    color: primaryTrainColor,
                    size: _responsiveIconSize(screenWidth, 20), // Responsive icon size
                  ),
                ),
                SizedBox(width: _responsiveFontSize(screenWidth, 12)), // Responsive spacing
                Text(
                  "Kereta Pergi",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontSize: _responsiveFontSize(screenWidth, 16), // Responsive font size
                  ),
                ),
              ],
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 20)), // Responsive spacing
            Container(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)), // Responsive padding
              decoration: BoxDecoration(
                color: backgroundGray,
                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)), // Responsive border radius
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: _responsiveIconSize(screenWidth, 16), color: textSecondary), // Responsive icon size
                      SizedBox(width: _responsiveFontSize(screenWidth, 8)), // Responsive spacing
                      Text(
                        DateFormat('EEE, dd MMM yy', 'id_ID').format(widget
                            .jadwalDipesan.tanggalBerangkatUtama
                            .toDate()),
                        style: TextStyle(
                            fontSize: _responsiveFontSize(screenWidth, 14), // Responsive font size
                            color: textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: _responsiveFontSize(screenWidth, 16)), // Responsive spacing
                      Icon(Icons.access_time, size: _responsiveIconSize(screenWidth, 16), color: textSecondary), // Responsive icon size
                      SizedBox(width: _responsiveFontSize(screenWidth, 8)), // Responsive spacing
                      Text(
                        widget.jadwalDipesan.jamBerangkatFormatted,
                        style: TextStyle(
                            fontSize: _responsiveFontSize(screenWidth, 14), // Responsive font size
                            color: textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 12)), // Responsive spacing
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.jadwalDipesan.idStasiunAsal,
                          style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 16), // Responsive font size
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 4)), // Responsive padding
                        decoration: BoxDecoration(
                          color: primaryTrainColor,
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)), // Responsive border radius
                        ),
                        child: Icon(Icons.arrow_forward,
                            color: Colors.white, size: _responsiveIconSize(screenWidth, 16)), // Responsive icon size
                      ),
                      Expanded(
                        child: Text(
                          widget.jadwalDipesan.idStasiunTujuan,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 16), // Responsive font size
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 12)), // Responsive spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.jadwalDipesan.namaKereta,
                        style:
                        TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: textSecondary), // Responsive font size
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 6)), // Responsive padding
                        decoration: BoxDecoration(
                          color: accentBlueColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)), // Responsive border radius
                        ),
                        child: Text(
                          widget.kelasDipilih.displayKelasLengkap,
                          style: TextStyle(
                            fontSize: _responsiveFontSize(screenWidth, 12), // Responsive font size
                            color: accentBlueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenumpangSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Daftar Penumpang",
          style: TextStyle(
            fontSize: _responsiveFontSize(screenWidth, 18), // Responsive font size
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        SizedBox(height: _responsiveFontSize(screenWidth, 16)), // Responsive spacing
        ..._buildListPenumpang(screenWidth),
      ],
    );
  }

  List<Widget> _buildListPenumpang(double screenWidth) {
    return List.generate(widget.dataPenumpangList.length, (index) {
      final penumpang = widget.dataPenumpangList[index];
      final kursiDipilih = _kursiTerpilih[index];
      final hasSelectedSeat = kursiDipilih != null;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 16.0)), // Responsive margin
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 16)), // Responsive border radius
          border: Border.all(
            color: hasSelectedSeat
                ? successGreen.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: hasSelectedSeat ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: _responsiveFontSize(screenWidth, 12), // Responsive blur radius
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20.0)), // Responsive padding
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: _responsiveIconSize(screenWidth, 50), // Responsive size
                    height: _responsiveIconSize(screenWidth, 50), // Responsive size
                    decoration: BoxDecoration(
                      color: hasSelectedSeat
                          ? successGreen.withOpacity(0.1)
                          : primaryTrainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: _responsiveFontSize(screenWidth, 18), // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: hasSelectedSeat
                              ? successGreen
                              : primaryTrainColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: _responsiveFontSize(screenWidth, 16)), // Responsive spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Penumpang ${index + 1}",
                              style: TextStyle(
                                fontSize: _responsiveFontSize(screenWidth, 12), // Responsive font size
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: _responsiveFontSize(screenWidth, 8)), // Responsive spacing
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)), // Responsive padding
                              decoration: BoxDecoration(
                                color: accentBlueColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)), // Responsive border radius
                              ),
                              child: Text(
                                "Dewasa",
                                style: TextStyle(
                                  fontSize: _responsiveFontSize(screenWidth, 10), // Responsive font size
                                  color: accentBlueColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _responsiveFontSize(screenWidth, 4)), // Responsive spacing
                        Text(
                          penumpang.namaLengkap,
                          style: TextStyle(
                            fontSize: _responsiveFontSize(screenWidth, 16), // Responsive font size
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: _responsiveFontSize(screenWidth, 16)), // Responsive spacing
              Container(
                padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)), // Responsive padding
                decoration: BoxDecoration(
                  color: backgroundGray,
                  borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)), // Responsive border radius
                ),
                child: Row(
                  children: [
                    Icon(
                      hasSelectedSeat
                          ? Icons.event_seat
                          : Icons.event_seat_outlined,
                      color: hasSelectedSeat ? successGreen : textSecondary,
                      size: _responsiveIconSize(screenWidth, 20), // Responsive icon size
                    ),
                    SizedBox(width: _responsiveFontSize(screenWidth, 12)), // Responsive spacing
                    Expanded(
                      child: Text(
                        kursiDipilih ?? "Belum memilih kursi",
                        style: TextStyle(
                          fontSize: _responsiveFontSize(screenWidth, 14), // Responsive font size
                          fontWeight: hasSelectedSeat
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: hasSelectedSeat ? successGreen : textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _responsiveFontSize(screenWidth, 36), // Responsive height
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          hasSelectedSeat ? Colors.white : accentBlueColor,
                          foregroundColor:
                          hasSelectedSeat ? accentBlueColor : Colors.white,
                          elevation: 0,
                          side: hasSelectedSeat
                              ? const BorderSide(color: accentBlueColor)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)), // Responsive border radius
                          ),
                          padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16)), // Responsive padding
                        ),
                        onPressed: () => _pilihKursiUntukPenumpang(index),
                        child: Text(
                          hasSelectedSeat ? "Ubah" : "Pilih Kursi",
                          style: TextStyle(
                            fontSize: _responsiveFontSize(screenWidth, 12), // Responsive font size
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomButton(double screenWidth) {
    final allSeatsSelected =
        _kursiTerpilih.length == widget.dataPenumpangList.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: _responsiveFontSize(screenWidth, 20), // Responsive blur radius
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20.0)), // Responsive padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!allSeatsSelected)
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16), vertical: _responsiveFontSize(screenWidth, 12)), // Responsive padding
                margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 16)), // Responsive margin
                decoration: BoxDecoration(
                  color: warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)), // Responsive border radius
                  border: Border.all(color: warningOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: warningOrange, size: _responsiveIconSize(screenWidth, 20)), // Responsive icon size
                    SizedBox(width: _responsiveFontSize(screenWidth, 12)), // Responsive spacing
                    Expanded(
                      child: Text(
                        "Pilih kursi untuk ${widget.dataPenumpangList.length - _kursiTerpilih.length} penumpang lagi",
                        style: TextStyle(
                          fontSize: _responsiveFontSize(screenWidth, 12), // Responsive font size
                          color: warningOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: _responsiveFontSize(screenWidth, 56), // Responsive height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  allSeatsSelected ? accentBlueColor : Colors.grey[400],
                  foregroundColor: Colors.white,
                  elevation: allSeatsSelected ? 4 : 0,
                  shadowColor: accentBlueColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 28)), // Responsive border radius
                  ),
                ),
                onPressed: allSeatsSelected ? _lanjutkanKePembayaran : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (allSeatsSelected) ...[
                      Icon(Icons.payment, size: _responsiveIconSize(screenWidth, 20)), // Responsive icon size
                      SizedBox(width: _responsiveFontSize(screenWidth, 8)), // Responsive spacing
                    ],
                    Text(
                      "LANJUTKAN KE PEMBAYARAN",
                      style: TextStyle(
                        fontSize: _responsiveFontSize(screenWidth, 16), // Responsive font size
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
