import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pembayaran_screen.dart';
import 'package:kaig/screens/customer/utama/tiket/pilih_gerbong_screen.dart';
import 'DataPenumpangScreen.dart';

class PilihKursiStepScreen extends StatefulWidget {
  final JadwalModel jadwalPergi;
  final JadwalKelasInfoModel kelasDipilihPergi;
  final JadwalModel? jadwalPulang;
  final JadwalKelasInfoModel? kelasDipilihPulang;

  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi;

  const PilihKursiStepScreen({
    super.key,
    required this.jadwalPergi,
    required this.kelasDipilihPergi,
    this.jadwalPulang,
    this.kelasDipilihPulang,
    required this.dataPenumpangList,
    required this.jumlahBayi,
  });

  @override
  State<PilihKursiStepScreen> createState() => _PilihKursiStepScreenState();
}

class _PilihKursiStepScreenState extends State<PilihKursiStepScreen>
    with TickerProviderStateMixin {
  late Map<int, String> _kursiTerpilihPergi;
  late Map<int, String> _kursiTerpilihPulang;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Tema Warna
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
    _kursiTerpilihPergi = {};
    _kursiTerpilihPulang = {};

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pilihKursiUntukPenumpang(int indexPenumpang, bool isPergi) async {
    final String? hasilPilihKursi = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PilihGerbongScreen(
          jadwalDipesan: isPergi ? widget.jadwalPergi : widget.jadwalPulang!,
          kelasDipilih: isPergi ? widget.kelasDipilihPergi : widget.kelasDipilihPulang!,
          penumpangSaatIni: widget.dataPenumpangList[indexPenumpang],
          kursiYangSudahDipilihGrup: (isPergi ? _kursiTerpilihPergi : _kursiTerpilihPulang)
              .values
              .where((k) => k != (isPergi ? _kursiTerpilihPergi[indexPenumpang] : _kursiTerpilihPulang[indexPenumpang]))
              .toList(),
        ),
      ),
    );

    if (hasilPilihKursi != null && mounted) {
      setState(() {
        if (isPergi) {
          _kursiTerpilihPergi.removeWhere((key, value) => value == hasilPilihKursi);
          _kursiTerpilihPergi[indexPenumpang] = hasilPilihKursi;
        } else {
          _kursiTerpilihPulang.removeWhere((key, value) => value == hasilPilihKursi);
          _kursiTerpilihPulang[indexPenumpang] = hasilPilihKursi;
        }
      });
    }
  }

  void _lanjutkanKePembayaran() {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isRoundTrip = widget.jadwalPulang != null;

    if (_kursiTerpilihPergi.length < widget.dataPenumpangList.length) {
      _showErrorSnackBar('Harap pilih kursi keberangkatan untuk semua penumpang.', screenWidth);
      return;
    }

    if (isRoundTrip && _kursiTerpilihPulang.length < widget.dataPenumpangList.length) {
      _showErrorSnackBar('Harap pilih kursi kepulangan untuk semua penumpang.', screenWidth);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PembayaranScreen(
          jadwalPergi: widget.jadwalPergi,
          kelasDipilihPergi: widget.kelasDipilihPergi,
          kursiTerpilihPergi: _kursiTerpilihPergi,
          jadwalPulang: widget.jadwalPulang,
          kelasDipilihPulang: widget.kelasDipilihPulang,
          kursiTerpilihPulang: _kursiTerpilihPulang,
          dataPenumpangList: widget.dataPenumpangList,
          jumlahBayi: widget.jumlahBayi,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message, double screenWidth) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: _responsiveIconSize(screenWidth, 20)),
            SizedBox(width: _responsiveFontSize(screenWidth, 12)),
            Expanded(child: Text(message, style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)))),
          ],
        ),
        backgroundColor: warningOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
        margin: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
      ),
    );
  }

  // Helper-helper responsive
  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) return baseSize * 0.8;
    if (screenWidth < 600) return baseSize;
    return baseSize * 1.1;
  }
  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) return baseSize;
    return baseSize * 1.1;
  }
  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) return (screenWidth - 1000) / 2;
    if (screenWidth > 600) return 24.0;
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isRoundTrip = widget.jadwalPulang != null;

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text("Pesan Tiket", style: TextStyle(fontWeight: FontWeight.w600, fontSize: _responsiveFontSize(screenWidth, 18))),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_responsiveFontSize(screenWidth, 8.0)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: _responsiveHorizontalPadding(screenWidth)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 4)),
              child: LinearProgressIndicator(
                value: 0.75, // Step 3 dari 4
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0000CD)),
                minHeight: _responsiveFontSize(screenWidth, 6),
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
          children: [
            _buildStepHeader(screenWidth),
            SizedBox(height: _responsiveFontSize(screenWidth, 24.0)),
            _buildInfoKeretaCard(screenWidth, widget.jadwalPergi, widget.kelasDipilihPergi, "Kereta Pergi", primaryTrainColor),
            SizedBox(height: _responsiveFontSize(screenWidth, 24.0)),
            _buildPenumpangSection(screenWidth, "Pilih Kursi Pergi", true, _kursiTerpilihPergi),
            if (isRoundTrip) ...[
              SizedBox(height: _responsiveFontSize(screenWidth, 32.0)),
              _buildInfoKeretaCard(screenWidth, widget.jadwalPulang!, widget.kelasDipilihPulang!, "Kereta Pulang", accentBlueColor),
              SizedBox(height: _responsiveFontSize(screenWidth, 24.0)),
              _buildPenumpangSection(screenWidth, "Pilih Kursi Pulang", false, _kursiTerpilihPulang),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(screenWidth),
    );
  }

  Widget _buildStepHeader(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 10.0), horizontal: _responsiveFontSize(screenWidth, 16.0)),
      decoration: BoxDecoration(
        color: Colors.deepOrange,
        borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 8.0)),
      ),
      child: Text(
        "3. Pilih Kursi",
        style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoKeretaCard(double screenWidth, JadwalModel jadwal, JadwalKelasInfoModel kelas, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _responsiveFontSize(screenWidth, 20),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 8)),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
                  ),
                  child: Icon(Icons.train, color: color, size: _responsiveIconSize(screenWidth, 20)),
                ),
                SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontSize: _responsiveFontSize(screenWidth, 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 20)),
            Container(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
              decoration: BoxDecoration(
                color: backgroundGray,
                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: _responsiveIconSize(screenWidth, 16), color: textSecondary),
                      SizedBox(width: _responsiveFontSize(screenWidth, 8)),
                      Text(
                        DateFormat('EEE, dd MMM yy', 'id_ID').format(jadwal.tanggalBerangkatUtama.toDate()),
                        style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: _responsiveFontSize(screenWidth, 16)),
                      Icon(Icons.access_time, size: _responsiveIconSize(screenWidth, 16), color: textSecondary),
                      SizedBox(width: _responsiveFontSize(screenWidth, 8)),
                      Text(
                        jadwal.jamBerangkatFormatted,
                        style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 12)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          jadwal.idStasiunAsal,
                          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 4)),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)),
                        ),
                        child: Icon(Icons.arrow_forward, color: Colors.white, size: _responsiveIconSize(screenWidth, 16)),
                      ),
                      Expanded(
                        child: Text(
                          jadwal.idStasiunTujuan,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        jadwal.namaKereta,
                        style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: textSecondary),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 6)),
                        decoration: BoxDecoration(
                          color: accentBlueColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20)),
                        ),
                        child: Text(
                          kelas.displayKelasLengkap,
                          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 12), color: accentBlueColor, fontWeight: FontWeight.w600),
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

  Widget _buildPenumpangSection(double screenWidth, String title, bool isPergi, Map<int, String> kursiTerpilihMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold, color: textPrimary),
        ),
        SizedBox(height: _responsiveFontSize(screenWidth, 16)),
        ...List.generate(widget.dataPenumpangList.length, (index) {
          final penumpang = widget.dataPenumpangList[index];
          final kursiDipilih = kursiTerpilihMap[index];
          final hasSelectedSeat = kursiDipilih != null;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 16.0)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 16)),
              border: Border.all(
                color: hasSelectedSeat ? successGreen.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                width: hasSelectedSeat ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: _responsiveFontSize(screenWidth, 12), offset: const Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20.0)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: _responsiveIconSize(screenWidth, 50),
                        height: _responsiveIconSize(screenWidth, 50),
                        decoration: BoxDecoration(
                          color: hasSelectedSeat ? successGreen.withOpacity(0.1) : primaryTrainColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 18),
                              fontWeight: FontWeight.bold,
                              color: hasSelectedSeat ? successGreen : primaryTrainColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: _responsiveFontSize(screenWidth, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("Penumpang ${index + 1}", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 12), color: textSecondary, fontWeight: FontWeight.w500)),
                                SizedBox(width: _responsiveFontSize(screenWidth, 8)),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)),
                                  decoration: BoxDecoration(
                                    color: accentBlueColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
                                  ),
                                  child: Text("Dewasa", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 10), color: accentBlueColor, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
                            Text(
                              penumpang.namaLengkap,
                              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 16)),
                  Container(
                    padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
                    decoration: BoxDecoration(
                      color: backgroundGray,
                      borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasSelectedSeat ? Icons.event_seat : Icons.event_seat_outlined,
                          color: hasSelectedSeat ? successGreen : textSecondary,
                          size: _responsiveIconSize(screenWidth, 20),
                        ),
                        SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                        Expanded(
                          child: Text(
                            kursiDipilih ?? "Belum memilih kursi",
                            style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 14),
                              fontWeight: hasSelectedSeat ? FontWeight.w600 : FontWeight.normal,
                              color: hasSelectedSeat ? successGreen : textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _responsiveFontSize(screenWidth, 36),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasSelectedSeat ? Colors.white : accentBlueColor,
                              foregroundColor: hasSelectedSeat ? accentBlueColor : Colors.white,
                              elevation: 0,
                              side: hasSelectedSeat ? const BorderSide(color: accentBlueColor) : null,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 20))),
                              padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16)),
                            ),
                            onPressed: () => _pilihKursiUntukPenumpang(index, isPergi),
                            child: Text(
                              hasSelectedSeat ? "Ubah" : "Pilih Kursi",
                              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 12), fontWeight: FontWeight.w600),
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
        }).toList(),
      ],
    );
  }

  Widget _buildBottomButton(double screenWidth) {
    bool isRoundTrip = widget.jadwalPulang != null;
    bool allSeatsSelected = _kursiTerpilihPergi.length == widget.dataPenumpangList.length &&
        (!isRoundTrip || _kursiTerpilihPulang.length == widget.dataPenumpangList.length);

    int remainingSeats = (widget.dataPenumpangList.length - _kursiTerpilihPergi.length) +
        (isRoundTrip ? (widget.dataPenumpangList.length - _kursiTerpilihPulang.length) : 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: _responsiveFontSize(screenWidth, 20),
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!allSeatsSelected)
              Container(
                padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16), vertical: _responsiveFontSize(screenWidth, 12)),
                margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 16)),
                decoration: BoxDecoration(
                  color: warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
                  border: Border.all(color: warningOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: warningOrange, size: _responsiveIconSize(screenWidth, 20)),
                    SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                    Expanded(
                      child: Text(
                        "Pilih kursi untuk $remainingSeats penumpang lagi",
                        style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 12), color: warningOrange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: _responsiveFontSize(screenWidth, 56),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: allSeatsSelected ? accentBlueColor : Colors.grey[400],
                  foregroundColor: Colors.white,
                  elevation: allSeatsSelected ? 4 : 0,
                  shadowColor: accentBlueColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 28))),
                ),
                onPressed: allSeatsSelected ? _lanjutkanKePembayaran : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (allSeatsSelected) ...[
                      Icon(Icons.payment, size: _responsiveIconSize(screenWidth, 20)),
                      SizedBox(width: _responsiveFontSize(screenWidth, 8)),
                    ],
                    Text(
                      "LANJUTKAN KE PEMBAYARAN",
                      style: TextStyle(
                        fontSize: _responsiveFontSize(screenWidth, 16),
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
