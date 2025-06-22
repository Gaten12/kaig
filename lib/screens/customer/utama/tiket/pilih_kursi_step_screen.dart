import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pembayaran_screen.dart';
import 'package:kaig/screens/customer/utama/tiket/pilih_gerbong_screen.dart';

import 'DataPenumpangScreen.dart';


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
    if (_kursiTerpilih.length < widget.dataPenumpangList.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Harap pilih kursi untuk semua penumpang.')),
            ],
          ),
          backgroundColor: warningOrange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        title: const Text(
          "Pesan Tiket",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.67, // Step 2 dari 3
                backgroundColor: Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(primaryTrainColor),
                minHeight: 6,
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildStepHeader(),
            const SizedBox(height: 24.0),
            _buildInfoKeretaCard(),
            const SizedBox(height: 24.0),
            _buildPenumpangSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryTrainColor.withAlpha((255 * 0.1).round()),
            primaryTrainColor.withAlpha((255 * 0.05).round())
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryTrainColor.withAlpha((255 * 0.2).round())),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: primaryTrainColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.airline_seat_recline_normal,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Langkah 2 dari 3",
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Pilih Kursi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoKeretaCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.08).round()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryTrainColor.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.train,
                    color: primaryTrainColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Kereta Pergi",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEE, dd MMM yy', 'id_ID').format(widget
                            .jadwalDipesan.tanggalBerangkatUtama
                            .toDate()),
                        style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        widget.jadwalDipesan.jamBerangkatFormatted,
                        style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.jadwalDipesan.idStasiunAsal,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryTrainColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 16),
                      ),
                      Expanded(
                        child: Text(
                          widget.jadwalDipesan.idStasiunTujuan,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.jadwalDipesan.namaKereta,
                        style:
                            const TextStyle(fontSize: 14, color: textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentBlueColor.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.kelasDipilih.displayKelasLengkap,
                          style: const TextStyle(
                            fontSize: 12,
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

  Widget _buildPenumpangSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Penumpang",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._buildListPenumpang(),
      ],
    );
  }

  List<Widget> _buildListPenumpang() {
    return List.generate(widget.dataPenumpangList.length, (index) {
      final penumpang = widget.dataPenumpangList[index];
      final kursiDipilih = _kursiTerpilih[index];
      final hasSelectedSeat = kursiDipilih != null;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelectedSeat
                ? successGreen.withAlpha((255 * 0.3).round())
                : Colors.grey.withAlpha((255 * 0.2).round()),
            width: hasSelectedSeat ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.06).round()),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: hasSelectedSeat
                          ? successGreen.withAlpha((255 * 0.1).round())
                          : primaryTrainColor.withAlpha((255 * 0.1).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: hasSelectedSeat
                              ? successGreen
                              : primaryTrainColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Penumpang ${index + 1}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentBlueColor.withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Dewasa",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: accentBlueColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          penumpang.namaLengkap,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasSelectedSeat
                          ? Icons.event_seat
                          : Icons.event_seat_outlined,
                      color: hasSelectedSeat ? successGreen : textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kursiDipilih ?? "Belum memilih kursi",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: hasSelectedSeat
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: hasSelectedSeat ? successGreen : textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () => _pilihKursiUntukPenumpang(index),
                        child: Text(
                          hasSelectedSeat ? "Ubah" : "Pilih Kursi",
                          style: const TextStyle(
                            fontSize: 12,
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
    });
  }

  Widget _buildBottomButton() {
    final allSeatsSelected =
        _kursiTerpilih.length == widget.dataPenumpangList.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!allSeatsSelected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: warningOrange.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warningOrange.withAlpha((255 * 0.3).round())),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: warningOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pilih kursi untuk ${widget.dataPenumpangList.length - _kursiTerpilih.length} penumpang lagi",
                        style: const TextStyle(
                          fontSize: 12,
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
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      allSeatsSelected ? accentBlueColor : Colors.grey[400],
                  foregroundColor: Colors.white,
                  elevation: allSeatsSelected ? 4 : 0,
                  shadowColor: accentBlueColor.withAlpha((255 * 0.3).round()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: allSeatsSelected ? _lanjutkanKePembayaran : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (allSeatsSelected) ...[
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      "LANJUTKAN KE PEMBAYARAN",
                      style: TextStyle(
                        fontSize: 16,
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
