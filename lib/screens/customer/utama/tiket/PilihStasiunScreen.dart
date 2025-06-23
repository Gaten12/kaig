import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/JadwalModel.dart';
import 'DataPenumpangScreen.dart';

class PilihKelasScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final String stasiunAsalDisplay;
  final String stasiunTujuanDisplay;
  final DateTime tanggalBerangkat;
  final int jumlahDewasa;
  final int jumlahBayi;

  const PilihKelasScreen({
    super.key,
    required this.jadwalDipesan,
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

  // Tema Warna Kereta Elegan
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
  static const Color darkBlue = Color(0xFF0000CD); // New color for numbers

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String penumpangInfo = "${widget.jumlahDewasa} Dewasa";
    if (widget.jumlahBayi > 0) {
      penumpangInfo += ", ${widget.jumlahBayi} Bayi";
    }
    String tanggalInfo = DateFormat('EEE, dd MMM yy', 'id_ID')
        .format(widget.jadwalDipesan.tanggalBerangkatUtama.toDate());

    return Scaffold(
      backgroundColor: warmGray,
      appBar: _buildElegantAppBar(tanggalInfo, penumpangInfo),
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
                    _buildRuteKeretaSection(screenWidth),
                    SizedBox(height: _responsiveFontSize(screenWidth, 32.0)),
                    _buildKelasSection(currencyFormatter, screenWidth),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildElegantAppBar(
      String tanggalInfo, String penumpangInfo) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: lightRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon:
          Icon(Icons.arrow_back_ios_new, color: primaryRed, size: _responsiveIconSize(MediaQuery.of(context).size.width, 20)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(MediaQuery.of(context).size.width, 12), vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryRed, darkRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${widget.stasiunAsalDisplay} 🚂 ${widget.stasiunTujuanDisplay}",
              style: TextStyle(
                fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 14),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: _responsiveIconSize(MediaQuery.of(context).size.width, 12), color: textSecondary),
              SizedBox(width: _responsiveFontSize(MediaQuery.of(context).size.width, 4)),
              Text(
                tanggalInfo,
                style: TextStyle(
                    fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 11),
                    color: textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              SizedBox(width: _responsiveFontSize(MediaQuery.of(context).size.width, 12)),
              Icon(Icons.people, size: _responsiveIconSize(MediaQuery.of(context).size.width, 12), color: textSecondary),
              SizedBox(width: _responsiveFontSize(MediaQuery.of(context).size.width, 4)),
              Text(
                penumpangInfo,
                style: TextStyle(
                    fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 11),
                    color: textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildRuteKeretaSection(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryRed.withOpacity(0.1), lightRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.train_rounded,
                          color: Colors.white, size: _responsiveIconSize(screenWidth, 24)),
                    ),
                    SizedBox(width: _responsiveFontSize(screenWidth, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.jadwalDipesan.namaKereta.toUpperCase(),
                            style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 18),
                              fontWeight: FontWeight.bold,
                              color: primaryRed,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)),
                            decoration: BoxDecoration(
                              color: primaryRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.jadwalDipesan.idKereta,
                              style: TextStyle(
                                fontSize: _responsiveFontSize(screenWidth, 12),
                                fontWeight: FontWeight.bold,
                                color: primaryRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _responsiveFontSize(screenWidth, 12)),
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 6)),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: _responsiveIconSize(screenWidth, 16), color: accentBlue),
                      SizedBox(width: _responsiveFontSize(screenWidth, 6)),
                      Text(
                        "Durasi: ${widget.jadwalDipesan.durasiPerjalananTotal}",
                        style: TextStyle(
                          fontSize: _responsiveFontSize(screenWidth, 13),
                          fontWeight: FontWeight.w600,
                          color: accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🛤️ Rute Perjalanan",
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 16),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: _responsiveFontSize(screenWidth, 16)),
                _buildRuteTimeline(screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuteTimeline(double screenWidth) {
    if (widget.jadwalDipesan.detailPerhentian.isEmpty) {
      return Container(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
        decoration: BoxDecoration(
          color: warmGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: textSecondary),
            SizedBox(width: _responsiveFontSize(screenWidth, 12)),
            Text(
              "Detail rute tidak tersedia",
              style:
              TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    List<Widget> ruteWidgets = [];
    for (int i = 0; i < widget.jadwalDipesan.detailPerhentian.length; i++) {
      final perhentian = widget.jadwalDipesan.detailPerhentian[i];
      bool isStasiunAwal = i == 0;
      bool isStasiunAkhir =
          i == widget.jadwalDipesan.detailPerhentian.length - 1;

      ruteWidgets.add(
          _buildStationTimelineItem(perhentian, isStasiunAwal, isStasiunAkhir, screenWidth));
    }

    return Column(children: ruteWidgets);
  }

  Widget _buildStationTimelineItem(
      dynamic perhentian, bool isStasiunAwal, bool isStasiunAkhir, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          Expanded(
            flex: 2, // Give it a flex factor to occupy some space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isStasiunAwal && perhentian.waktuTiba != null)
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)),
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuTiba!.toDate()),
                      style: TextStyle(
                          fontSize: _responsiveFontSize(screenWidth, 11),
                          color: darkBlue, // Changed color to darkBlue
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: 2),
                if (!isStasiunAkhir && perhentian.waktuBerangkat != null)
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuBerangkat!.toDate()),
                      style: TextStyle(
                        fontSize: _responsiveFontSize(screenWidth, 12),
                        fontWeight: FontWeight.bold,
                        color: darkBlue, // Changed color to darkBlue
                      ),
                    ),
                  ),
                if (isStasiunAwal && perhentian.waktuBerangkat != null)
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)),
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuBerangkat!.toDate()),
                      style: TextStyle(
                        fontSize: _responsiveFontSize(screenWidth, 12),
                        fontWeight: FontWeight.bold,
                        color: darkBlue, // Changed color to darkBlue
                      ),
                    ),
                  ),
                if (isStasiunAkhir &&
                    perhentian.waktuTiba != null &&
                    !isStasiunAwal)
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 2)),
                    decoration: BoxDecoration(
                      color: warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuTiba!.toDate()),
                      style: TextStyle(
                        fontSize: _responsiveFontSize(screenWidth, 12),
                        fontWeight: FontWeight.bold,
                        color: darkBlue, // Changed color to darkBlue
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Timeline Indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16.0)),
            child: Column(
              children: [
                Container(
                  width: _responsiveIconSize(screenWidth, 24),
                  height: _responsiveIconSize(screenWidth, 24),
                  decoration: BoxDecoration(
                    color: isStasiunAwal
                        ? successGreen
                        : (isStasiunAkhir
                        ? warningOrange
                        : primaryRed.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(_responsiveIconSize(screenWidth, 12)),
                    border: Border.all(
                      color: isStasiunAwal
                          ? successGreen
                          : (isStasiunAkhir ? warningOrange : primaryRed),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isStasiunAwal
                        ? Icons.play_arrow_rounded
                        : (isStasiunAkhir
                        ? Icons.location_on_rounded
                        : Icons.fiber_manual_record),
                    color: Colors.white,
                    size: _responsiveIconSize(screenWidth, 14),
                  ),
                ),
                if (!isStasiunAkhir)
                  Container(
                    height: _responsiveFontSize(screenWidth, 40),
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryRed.withOpacity(0.6),
                          primaryRed.withOpacity(0.3)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    margin: EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 4)),
                  ),
              ],
            ),
          ),

          // Station Name
          Expanded(
            flex: 3, // Give it more flex space for station name
            child: Container(
              padding: EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 2)),
              child: Text(
                perhentian.namaStasiun.isNotEmpty
                    ? perhentian.namaStasiun.toUpperCase()
                    : perhentian.idStasiun.toUpperCase(),
                style: TextStyle(
                  fontWeight: (isStasiunAwal || isStasiunAkhir)
                      ? FontWeight.bold
                      : FontWeight.w600,
                  fontSize: _responsiveFontSize(screenWidth, (isStasiunAwal || isStasiunAkhir) ? 15 : 14),
                  color: (isStasiunAwal || isStasiunAkhir)
                      ? textPrimary
                      : textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKelasSection(NumberFormat currencyFormatter, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 20), vertical: _responsiveFontSize(screenWidth, 16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentBlue.withOpacity(0.1),
                accentBlue.withOpacity(0.05)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentBlue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 8)),
                decoration: BoxDecoration(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.airline_seat_recline_normal,
                    color: Colors.white, size: _responsiveIconSize(screenWidth, 20)),
              ),
              SizedBox(width: _responsiveFontSize(screenWidth, 12)),
              Text(
                "🎟️ Pilih Kelas & Harga",
                style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 18),
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _responsiveFontSize(screenWidth, 16)),
        if (widget.jadwalDipesan.daftarKelasHarga.isEmpty)
          _buildEmptyKelasState(screenWidth)
        else
          _buildKelasList(currencyFormatter, screenWidth),
      ],
    );
  }

  Widget _buildEmptyKelasState(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 32)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.event_seat_outlined, size: _responsiveIconSize(screenWidth, 64), color: textSecondary),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          Text(
            "Tidak Ada Kelas Tersedia",
            style: TextStyle(
              fontSize: _responsiveFontSize(screenWidth, 18),
              fontWeight: FontWeight.bold,
              color: textSecondary,
            ),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 8)),
          Text(
            "Detail kelas tidak tersedia untuk jadwal ini",
            style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKelasList(NumberFormat currencyFormatter, double screenWidth) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.jadwalDipesan.daftarKelasHarga.length,
      itemBuilder: (context, index) {
        final kelas = widget.jadwalDipesan.daftarKelasHarga[index];
        bool isTersedia = kelas.kuota > 0;
        String ketersediaanText =
        isTersedia ? "${kelas.kuota} kursi tersedia" : "Habis";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isTersedia
                  ? accentBlue.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: !isTersedia
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DataPenumpangScreen(
                      jadwalDipesan: widget.jadwalDipesan,
                      kelasDipilih: kelas,
                      tanggalBerangkat: widget.tanggalBerangkat,
                      jumlahDewasa: widget.jumlahDewasa,
                      jumlahBayi: widget.jumlahBayi,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
                child: Row(
                  children: [
                    // Class Icon
                    Container(
                      width: _responsiveIconSize(screenWidth, 60),
                      height: _responsiveIconSize(screenWidth, 60),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isTersedia
                              ? [
                            accentBlue.withOpacity(0.1),
                            accentBlue.withOpacity(0.05)
                          ]
                              : [
                            Colors.grey.withOpacity(0.1),
                            Colors.grey.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTersedia
                              ? accentBlue.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        _getClassIcon(kelas.displayKelasLengkap),
                        color: isTersedia ? accentBlue : Colors.grey,
                        size: _responsiveIconSize(screenWidth, 28),
                      ),
                    ),

                    SizedBox(width: _responsiveFontSize(screenWidth, 16)),

                    // Class Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kelas.displayKelasLengkap,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _responsiveFontSize(screenWidth, 16),
                              color: isTersedia ? textPrimary : Colors.grey,
                            ),
                          ),
                          SizedBox(height: _responsiveFontSize(screenWidth, 6)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: _responsiveFontSize(screenWidth, 10), vertical: _responsiveFontSize(screenWidth, 4)),
                            decoration: BoxDecoration(
                              color: isTersedia
                                  ? successGreen.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(

                              children: [
                                Icon(
                                  isTersedia
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: _responsiveIconSize(screenWidth, 14),
                                  color: isTersedia ? successGreen : Colors.red,
                                ),
                                SizedBox(width: _responsiveFontSize(screenWidth, 4)),
                                Flexible(
                                  child: Text(
                                    ketersediaanText,
                                    style: TextStyle(
                                      fontSize: _responsiveFontSize(screenWidth, 12),
                                      fontWeight: FontWeight.w600,
                                      color:
                                      isTersedia ? successGreen : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price & Arrow
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              currencyFormatter.format(kelas.harga),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _responsiveFontSize(screenWidth, 16),
                                color: darkBlue, // Changed color to darkBlue
                              ),
                            ),
                          ),
                          SizedBox(height: _responsiveFontSize(screenWidth, 8)),
                          Container(
                            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 8)),
                            decoration: BoxDecoration(
                              color: isTersedia
                                  ? accentBlue.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: _responsiveIconSize(screenWidth, 16),
                              color: isTersedia ? accentBlue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
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
    if (lowerName.contains('eksekutif') || lowerName.contains('executive')) {
      return Icons.star_rounded;
    } else if (lowerName.contains('bisnis') || lowerName.contains('business')) {
      return Icons.business_center_rounded;
    } else if (lowerName.contains('ekonomi') || lowerName.contains('economy')) {
      return Icons.airline_seat_recline_normal;
    } else {
      return Icons.train_rounded;
    }
  }
}
