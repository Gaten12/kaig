import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart';
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuteKeretaSection(),
                const SizedBox(height: 32.0),
                _buildKelasSection(currencyFormatter),
              ],
            ),
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
              const Icon(Icons.arrow_back_ios_new, color: primaryRed, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryRed, darkRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${widget.stasiunAsalDisplay} ✈ ${widget.stasiunTujuanDisplay}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                tanggalInfo,
                style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Icon(Icons.people, size: 12, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                penumpangInfo,
                style: TextStyle(
                    fontSize: 11,
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

  Widget _buildRuteKeretaSection() {
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
            padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.train_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.jadwalDipesan.namaKereta.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryRed,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.jadwalDipesan.idKereta,
                              style: const TextStyle(
                                fontSize: 12,
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
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 16, color: accentBlue),
                      const SizedBox(width: 6),
                      Text(
                        "Durasi: ${widget.jadwalDipesan.durasiPerjalananTotal}",
                        style: TextStyle(
                          fontSize: 13,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🛤️ Rute Perjalanan",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRuteTimeline(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuteTimeline() {
    if (widget.jadwalDipesan.detailPerhentian.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: warmGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: textSecondary),
            const SizedBox(width: 12),
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
          _buildStationTimelineItem(perhentian, isStasiunAwal, isStasiunAkhir));
    }

    return Column(children: ruteWidgets);
  }

  Widget _buildStationTimelineItem(
      dynamic perhentian, bool isStasiunAwal, bool isStasiunAkhir) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isStasiunAwal && perhentian.waktuTiba != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuTiba!.toDate()),
                      style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: 2),
                if (!isStasiunAkhir && perhentian.waktuBerangkat != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuBerangkat!.toDate()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                  ),
                if (isStasiunAwal && perhentian.waktuBerangkat != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuBerangkat!.toDate()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: successGreen,
                      ),
                    ),
                  ),
                if (isStasiunAkhir &&
                    perhentian.waktuTiba != null &&
                    !isStasiunAwal)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('HH:mm')
                          .format(perhentian.waktuTiba!.toDate()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: warningOrange,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Timeline Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isStasiunAwal
                        ? successGreen
                        : (isStasiunAkhir
                            ? warningOrange
                            : primaryRed.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
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
                    size: 14,
                  ),
                ),
                if (!isStasiunAkhir)
                  Container(
                    height: 40,
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
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
          ),

          // Station Name
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                perhentian.namaStasiun.isNotEmpty
                    ? perhentian.namaStasiun.toUpperCase()
                    : perhentian.idStasiun.toUpperCase(),
                style: TextStyle(
                  fontWeight: (isStasiunAwal || isStasiunAkhir)
                      ? FontWeight.bold
                      : FontWeight.w600,
                  fontSize: (isStasiunAwal || isStasiunAkhir) ? 15 : 14,
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

  Widget _buildKelasSection(NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.airline_seat_recline_normal,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "🎟️ Pilih Kelas & Harga",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.jadwalDipesan.daftarKelasHarga.isEmpty)
          _buildEmptyKelasState()
        else
          _buildKelasList(currencyFormatter),
      ],
    );
  }

  Widget _buildEmptyKelasState() {
    return Container(
      padding: const EdgeInsets.all(32),
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
          Icon(Icons.event_seat_outlined, size: 64, color: textSecondary),
          const SizedBox(height: 16),
          Text(
            "Tidak Ada Kelas Tersedia",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Detail kelas tidak tersedia untuk jadwal ini",
            style: TextStyle(fontSize: 14, color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKelasList(NumberFormat currencyFormatter) {
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Class Icon
                    Container(
                      width: 60,
                      height: 60,
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
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Class Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kelas.displayKelasLengkap,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isTersedia ? textPrimary : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTersedia
                                  ? successGreen.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isTersedia
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color: isTersedia ? successGreen : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ketersediaanText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isTersedia ? successGreen : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price & Arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(kelas.harga),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isTersedia ? primaryRed : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isTersedia
                                ? accentBlue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isTersedia ? accentBlue : Colors.grey,
                          ),
                        ),
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
