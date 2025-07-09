import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/JadwalModel.dart';
import '../../../../models/jadwal_kelas_info_model.dart';
import 'DataPenumpangScreen.dart';
import 'PilihJadwalScreen.dart'; // Import untuk navigasi kembali

class PilihKelasScreen extends StatefulWidget {
  // --- Parameter baru yang mendukung alur PP fleksibel ---

  // Jadwal yang kelasnya sedang ditampilkan di layar ini.
  final JadwalModel jadwalUntukDitampilkan;

  // Data perjalanan Pergi yang mungkin sudah dipilih.
  final JadwalModel? jadwalPergi;
  final JadwalKelasInfoModel? kelasPergi;

  // Data perjalanan Pulang (hanya diisi saat memilih kelas pulang).
  final JadwalModel? jadwalPulang;

  // Info umum pemesanan
  final bool isRoundTrip;
  final DateTime? tanggalPulang;
  final String stasiunAsalDisplay;
  final String stasiunTujuanDisplay;
  final DateTime tanggalBerangkat;
  final int jumlahDewasa;
  final int jumlahBayi;

  const PilihKelasScreen({
    super.key,
    required this.jadwalUntukDitampilkan,
    this.jadwalPergi,
    this.kelasPergi,
    this.jadwalPulang,
    this.isRoundTrip = false,
    this.tanggalPulang,
    required this.stasiunAsalDisplay,
    required this.stasiunTujuanDisplay,
    required this.tanggalBerangkat,
    required this.jumlahDewasa,
    required this.jumlahBayi,
  });

  @override
  State<PilihKelasScreen> createState() => _PilihKelasScreenState();
}

class _PilihKelasScreenState extends State<PilihKelasScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Tema Warna
  static const Color primaryRed = Color(0xFFC50000);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color lightRed = Color(0xFFFFEBEE);
  static const Color darkRed = Color(0xFF8B0000);
  static const Color warmGray = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color cardShadow = Color(0x1A000000);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningOrange = Color(0xFFE65100);
  static const Color darkBlue = Color(0xFF0000CD);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Helper-helper responsive
  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) return (screenWidth - 1000) / 2;
    if (screenWidth > 600) return 24.0;
    return 16.0;
  }

  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) return baseSize * 0.8;
    if (screenWidth < 600) return baseSize;
    return baseSize * 1.1;
  }

  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) return baseSize;
    return baseSize * 1.1;
  }

  String _getKodeFromDisplayName(String displayName) {
    if (displayName.contains("(") && displayName.contains(")")) {
      return displayName.substring(
          displayName.indexOf("(") + 1, displayName.indexOf(")"));
    }
    return displayName;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String penumpangInfo = "${widget.jumlahDewasa} Dewasa";
    if (widget.jumlahBayi > 0) penumpangInfo += ", ${widget.jumlahBayi} Bayi";

    // --- Logika untuk menentukan konteks layar ---
    final bool isSelectingReturnClass = widget.jadwalPulang != null;
    final bool isSelectingDepartureClassForRoundTrip = widget.isRoundTrip && !isSelectingReturnClass;

    final JadwalModel jadwal = widget.jadwalUntukDitampilkan;

    String ruteText = isSelectingReturnClass
        ? "${widget.stasiunTujuanDisplay} → ${widget.stasiunAsalDisplay}"
        : "${widget.stasiunAsalDisplay} → ${widget.stasiunTujuanDisplay}";
    if (isSelectingDepartureClassForRoundTrip) ruteText += " (Pergi)";
    if (isSelectingReturnClass) ruteText += " (Pulang)";

    DateTime tanggalTampil = isSelectingReturnClass ? widget.tanggalPulang! : widget.tanggalBerangkat;
    String tanggalInfo = DateFormat('EEE, dd MMM yy', 'id_ID').format(tanggalTampil);

    return Scaffold(
      backgroundColor: warmGray,
      appBar: _buildElegantAppBar(ruteText, tanggalInfo, penumpangInfo),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double horizontalPadding = _responsiveHorizontalPadding(constraints.maxWidth);
              final double screenWidth = constraints.maxWidth;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuteKeretaSection(
                        screenWidth: screenWidth,
                        jadwal: jadwal,
                        title: isSelectingReturnClass ? "Rute Kepulangan" : "Rute Keberangkatan",
                        headerColor: isSelectingReturnClass ? accentBlue : primaryRed,
                        isPergi: !isSelectingReturnClass
                    ),
                    const SizedBox(height: 32.0),
                    _buildKelasSection(currencyFormatter, screenWidth, jadwal),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildElegantAppBar(String ruteText, String tanggalInfo, String penumpangInfo) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(color: lightRed, borderRadius: BorderRadius.circular(12)),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryRed, size: _responsiveIconSize(MediaQuery.of(context).size.width, 20)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(MediaQuery.of(context).size.width, 12), vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryRed, darkRed]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              ruteText,
              style: TextStyle(fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 14), fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: _responsiveIconSize(MediaQuery.of(context).size.width, 12), color: textSecondary),
              SizedBox(width: _responsiveFontSize(MediaQuery.of(context).size.width, 4)),
              Text(tanggalInfo, style: TextStyle(fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 11), color: textSecondary, fontWeight: FontWeight.w500)),
              SizedBox(width: _responsiveFontSize(MediaQuery.of(context).size.width, 12)),
              Icon(Icons.people, size: _responsiveIconSize(MediaQuery.of(context).size.width, 12), color: textSecondary),
              SizedBox(width: _responsiveFontSize(MediaQuery.of(context).size.width, 4)),
              Text(penumpangInfo, style: TextStyle(fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 11), color: textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildRuteKeretaSection({
    required double screenWidth,
    required JadwalModel jadwal,
    required String title,
    required Color headerColor,
    required bool isPergi,
  }) {
    String stasiunAsal = isPergi ? widget.stasiunAsalDisplay : widget.stasiunTujuanDisplay;
    String stasiunTujuan = isPergi ? widget.stasiunTujuanDisplay : widget.stasiunAsalDisplay;
    String kodeAsal = _getKodeFromDisplayName(stasiunAsal);
    String kodeTujuan = _getKodeFromDisplayName(stasiunTujuan);
    String durasiSegmen = jadwal.getDurasiUntukSegmen(kodeAsal, kodeTujuan);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [headerColor.withOpacity(0.1), headerColor.withOpacity(0.05)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold, color: headerColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 8)),
                      decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.train_rounded, color: Colors.white, size: _responsiveIconSize(screenWidth, 24)),
                    ),
                    SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jadwal.namaKereta.toUpperCase(), style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold, color: headerColor)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)),
                            decoration: BoxDecoration(color: headerColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(jadwal.idKereta, style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 12), fontWeight: FontWeight.bold, color: headerColor)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _responsiveFontSize(screenWidth, 12)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 6)),
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: headerColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: _responsiveIconSize(screenWidth, 16), color: headerColor),
                      SizedBox(width: _responsiveFontSize(screenWidth, 6)),
                      Text("Durasi: $durasiSegmen", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 13), fontWeight: FontWeight.w600, color: headerColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
            child: _buildRuteTimeline(jadwal, screenWidth, kodeAsal, kodeTujuan),
          ),
        ],
      ),
    );
  }

  Widget _buildRuteTimeline(JadwalModel jadwal, double screenWidth, String kodeAsal, String kodeTujuan) {
    final perhentianAsal = jadwal.getPerhentianByKode(kodeAsal);
    final perhentianTujuan = jadwal.getPerhentianByKode(kodeTujuan);

    if (perhentianAsal == null || perhentianTujuan == null) {
      return const Text("Detail rute untuk segmen ini tidak tersedia.");
    }

    return Column(
      children: [
        _buildStationTimelineItem(perhentianAsal, true, false, screenWidth),
        _buildStationTimelineItem(perhentianTujuan, false, true, screenWidth),
      ],
    );
  }

  Widget _buildStationTimelineItem(dynamic perhentian, bool isStasiunAwal, bool isStasiunAkhir, double screenWidth) {
    final time = isStasiunAwal ? perhentian.waktuBerangkat?.toDate() : perhentian.waktuTiba?.toDate();
    final timeFormatted = time != null ? DateFormat('HH:mm').format(time) : '--:--';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _responsiveFontSize(screenWidth, 50),
          child: Text(
            timeFormatted,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), fontWeight: FontWeight.bold, color: darkBlue),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16.0)),
          child: Column(
            children: [
              Container(
                width: _responsiveIconSize(screenWidth, 24),
                height: _responsiveIconSize(screenWidth, 24),
                decoration: BoxDecoration(
                  color: isStasiunAwal ? successGreen : warningOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: (isStasiunAwal ? successGreen : warningOrange).withOpacity(0.5), blurRadius: 5)],
                ),
                child: Icon(
                  isStasiunAwal ? Icons.play_arrow_rounded : Icons.flag_rounded,
                  color: Colors.white,
                  size: _responsiveIconSize(screenWidth, 14),
                ),
              ),
              if (!isStasiunAkhir)
                Container(
                  height: _responsiveFontSize(screenWidth, 30),
                  width: 2,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: _responsiveFontSize(screenWidth, 2)),
            child: Text(
              perhentian.namaStasiun.isNotEmpty ? perhentian.namaStasiun.toUpperCase() : perhentian.idStasiun.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 15), color: textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKelasSection(NumberFormat currencyFormatter, double screenWidth, JadwalModel jadwal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 20), vertical: _responsiveFontSize(screenWidth, 16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accentBlue.withOpacity(0.1), accentBlue.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentBlue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 8)),
                decoration: BoxDecoration(color: accentBlue, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.airline_seat_recline_normal, color: Colors.white, size: _responsiveIconSize(screenWidth, 20)),
              ),
              SizedBox(width: _responsiveFontSize(screenWidth, 12)),
              Text("🎟️ Pilih Kelas & Harga", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold, color: accentBlue)),
            ],
          ),
        ),
        SizedBox(height: _responsiveFontSize(screenWidth, 16)),
        if (jadwal.daftarKelasHarga.isEmpty)
          _buildEmptyKelasState(screenWidth)
        else
          _buildKelasList(currencyFormatter, screenWidth, jadwal),
      ],
    );
  }

  Widget _buildEmptyKelasState(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 32)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(Icons.event_seat_outlined, size: _responsiveIconSize(screenWidth, 64), color: textSecondary),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          Text("Tidak Ada Kelas Tersedia", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold, color: textSecondary)),
          SizedBox(height: _responsiveFontSize(screenWidth, 8)),
          Text("Detail kelas tidak tersedia untuk jadwal ini", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildKelasList(NumberFormat currencyFormatter, double screenWidth, JadwalModel jadwal) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jadwal.daftarKelasHarga.length,
      itemBuilder: (context, index) {
        final kelas = jadwal.daftarKelasHarga[index];
        bool isTersedia = kelas.kuota > 0;
        String ketersediaanText = isTersedia ? "${kelas.kuota} kursi tersedia" : "Habis";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
            border: Border.all(color: isTersedia ? accentBlue.withOpacity(0.2) : Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: !isTersedia ? null : () {
                // --- ✨ LOGIKA NAVIGASI UTAMA ✨ ---

                // Skenario 1: Sedang memilih kelas PERGI untuk alur PP
                if (widget.isRoundTrip && widget.jadwalPulang == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PilihJadwalScreen(
                        stasiunAsal: widget.stasiunTujuanDisplay, // Rute dibalik
                        stasiunTujuan: widget.stasiunAsalDisplay,
                        tanggalBerangkat: widget.tanggalPulang!, // Gunakan tanggal pulang
                        jumlahDewasa: widget.jumlahDewasa,
                        jumlahBayi: widget.jumlahBayi,
                        isRoundTrip: true,
                        tanggalPulang: widget.tanggalPulang,
                        isReturnJourney: true, // Tandai ini pemilihan jadwal pulang
                        jadwalPergi: widget.jadwalUntukDitampilkan, // Kirim jadwal pergi
                        kelasPergi: kelas, // Kirim kelas pergi yg baru dipilih
                      ),
                    ),
                  );
                }
                // Skenario 2: Sedang memilih kelas PULANG atau ini perjalanan SEKALI JALAN
                else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DataPenumpangScreen(
                        jadwalPergi: widget.jadwalPergi ?? widget.jadwalUntukDitampilkan,
                        kelasDipilihPergi: widget.kelasPergi ?? kelas,
                        jadwalPulang: widget.jadwalPulang,
                        kelasDipilihPulang: widget.jadwalPulang != null ? kelas : null,
                        tanggalBerangkat: widget.tanggalBerangkat,
                        jumlahDewasa: widget.jumlahDewasa,
                        jumlahBayi: widget.jumlahBayi,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
                child: Row(
                  children: [
                    Container(
                      width: _responsiveIconSize(screenWidth, 60),
                      height: _responsiveIconSize(screenWidth, 60),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isTersedia ? [accentBlue.withOpacity(0.1), accentBlue.withOpacity(0.05)] : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isTersedia ? accentBlue.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Icon(_getClassIcon(kelas.displayKelasLengkap), color: isTersedia ? accentBlue : Colors.grey, size: _responsiveIconSize(screenWidth, 28)),
                    ),
                    SizedBox(width: _responsiveFontSize(screenWidth, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kelas.displayKelasLengkap,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 16), color: isTersedia ? textPrimary : Colors.grey),
                          ),
                          SizedBox(height: _responsiveFontSize(screenWidth, 6)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 10), vertical: _responsiveFontSize(screenWidth, 4)),
                            decoration: BoxDecoration(color: isTersedia ? successGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isTersedia ? Icons.check_circle : Icons.cancel, size: _responsiveIconSize(screenWidth, 14), color: isTersedia ? successGreen : Colors.red),
                                SizedBox(width: _responsiveFontSize(screenWidth, 4)),
                                Flexible(
                                  child: Text(
                                    ketersediaanText,
                                    style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 12), fontWeight: FontWeight.w600, color: isTersedia ? successGreen : Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(kelas.harga),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 16), color: darkBlue),
                        ),
                        SizedBox(height: _responsiveFontSize(screenWidth, 8)),
                        Icon(Icons.arrow_forward_ios, size: _responsiveIconSize(screenWidth, 16), color: isTersedia ? accentBlue : Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getClassIcon(String className) {
    String lowerName = className.toLowerCase();
    if (lowerName.contains('eksekutif')) return Icons.star_rounded;
    if (lowerName.contains('bisnis')) return Icons.business_center_rounded;
    if (lowerName.contains('ekonomi')) return Icons.airline_seat_recline_normal;
    return Icons.train_rounded;
  }
}
