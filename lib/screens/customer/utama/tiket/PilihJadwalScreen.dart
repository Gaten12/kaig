import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/JadwalModel.dart';
import '../../../../models/jadwal_kelas_info_model.dart';
import '../../../admin/services/admin_firestore_service.dart';
import 'PilihKelasScreen.dart';

class PilihJadwalScreen extends StatefulWidget {
  final String stasiunAsal;
  final String stasiunTujuan;
  final DateTime tanggalBerangkat;
  final int jumlahDewasa;
  final int jumlahBayi;
  final bool isRoundTrip;
  final DateTime? tanggalPulang;
  final bool isReturnJourney;
  final JadwalModel? jadwalPergi;
  final JadwalKelasInfoModel? kelasPergi;

  const PilihJadwalScreen({
    super.key,
    required this.stasiunAsal,
    required this.stasiunTujuan,
    required this.tanggalBerangkat,
    required this.jumlahDewasa,
    required this.jumlahBayi,
    this.isRoundTrip = false,
    this.tanggalPulang,
    this.isReturnJourney = false,
    this.jadwalPergi,
    this.kelasPergi,
  });

  @override
  State<PilihJadwalScreen> createState() => _PilihJadwalScreenState();
}

class _PilihJadwalScreenState extends State<PilihJadwalScreen>
    with SingleTickerProviderStateMixin {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  late DateTime _currentSelectedDate;
  final List<DateTime> _dateTabs = [];
  Stream<List<JadwalModel>>? _jadwalStream;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color Scheme
  static const Color primaryRed = Color(0xFFC50000);
  static const Color lightRed = Color(0xFFFFE6E6);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color neutralGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF9FAFB);
  static const Color darkGray = Color(0xFF374151);

  @override
  void initState() {
    super.initState();
    _currentSelectedDate =
    widget.isReturnJourney ? widget.tanggalPulang! : widget.tanggalBerangkat;
    _generateDateTabs();
    _updateJadwalStream();

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateDateTabs() {
    _dateTabs.clear();
    DateTime baseDate = _currentSelectedDate;
    for (int i = 0; i < 3; i++) {
      _dateTabs.add(baseDate.add(Duration(days: i)));
    }
  }

  String _getKodeFromDisplayName(String displayName) {
    if (displayName.contains("(") && displayName.contains(")")) {
      return displayName.substring(
          displayName.indexOf("(") + 1, displayName.indexOf(")"));
    }
    return displayName;
  }

  void _onDateTabSelected(DateTime selectedDate) {
    if (!mounted) return;
    setState(() {
      _currentSelectedDate = selectedDate;
      _updateJadwalStream();
    });
  }

  void _updateJadwalStream() {
    String kodeAsal = _getKodeFromDisplayName(widget.stasiunAsal);
    String kodeTujuan = _getKodeFromDisplayName(widget.stasiunTujuan);
    DateTime? waktuTibaPergi;

    if (widget.isReturnJourney && widget.jadwalPergi != null) {
      final tglPergi =
      DateUtils.dateOnly(widget.jadwalPergi!.tanggalBerangkatUtama.toDate());
      final tglPulang = DateUtils.dateOnly(_currentSelectedDate);

      if (tglPulang.isAtSameMomentAs(tglPergi)) {
        final perhentianTujuanPergi = widget.jadwalPergi!
            .getPerhentianByKode(_getKodeFromDisplayName(widget.stasiunAsal));
        waktuTibaPergi = perhentianTujuanPergi?.waktuTiba?.toDate();
      }
    }

    setState(() {
      _jadwalStream = _firestoreService.getJadwalList(
        tanggal: _currentSelectedDate,
        kodeAsal: kodeAsal.toUpperCase(),
        kodeTujuan: kodeTujuan.toUpperCase(),
        berangkatSetelah: waktuTibaPergi,
      );
    });
  }

  String _formatInfoPenumpangAppBar() {
    String tanggalFormatted =
    DateFormat('EEE, dd MMM yy', 'id_ID').format(_currentSelectedDate);
    String dewasaInfo = "${widget.jumlahDewasa} Dewasa";
    String bayiInfo =
    widget.jumlahBayi > 0 ? ", ${widget.jumlahBayi} Bayi" : "";
    return "$tanggalFormatted  •  $dewasaInfo$bayiInfo";
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

  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) return (screenWidth - 1000) / 2;
    if (screenWidth > 600) return 24.0;
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: lightGray,
      appBar: _buildAppBar(screenWidth),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDateTabsWidget(isSmallScreen, screenWidth),
              _buildHeaderSection(isSmallScreen, screenWidth),
              _buildJadwalList(isSmallScreen, screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double screenWidth) {
    return AppBar(
      backgroundColor: widget.isReturnJourney ? accentBlue : primaryRed,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: Colors.white, size: _responsiveIconSize(screenWidth, 20)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.stasiunAsal.toUpperCase(),
                  style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 16),
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: _responsiveFontSize(screenWidth, 8)),
                child: Icon(Icons.train,
                    size: _responsiveIconSize(screenWidth, 20)),
              ),
              Expanded(
                child: Text(
                  widget.stasiunTujuan.toUpperCase(),
                  style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 16),
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 2)),
          Text(
            _formatInfoPenumpangAppBar(),
            style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 12),
                fontWeight: FontWeight.w400,
                color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTabsWidget(bool isSmallScreen, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen
          ? _responsiveFontSize(screenWidth, 8.0)
          : _responsiveFontSize(screenWidth, 16.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _dateTabs.map((date) {
          bool isSelected = DateUtils.isSameDay(date, _currentSelectedDate);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen
                      ? _responsiveFontSize(screenWidth, 2.0)
                      : _responsiveFontSize(screenWidth, 4.0)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onDateTabSelected(date),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                        horizontal: _responsiveFontSize(screenWidth, 12),
                        vertical: _responsiveFontSize(screenWidth, 16)),
                    decoration: BoxDecoration(
                      color: isSelected ? accentBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSelected
                              ? accentBlue
                              : neutralGray.withOpacity(0.3),
                          width: 1.5),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                            color: accentBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('EEE', 'id_ID').format(date).toUpperCase(),
                          style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 11),
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : neutralGray,
                              letterSpacing: 0.5),
                        ),
                        SizedBox(height: _responsiveFontSize(screenWidth, 4)),
                        Text(
                          DateFormat('dd', 'id_ID').format(date),
                          style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 18),
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : darkGray),
                        ),
                        SizedBox(height: _responsiveFontSize(screenWidth, 2)),
                        Text(
                          DateFormat('MMM', 'id_ID').format(date).toUpperCase(),
                          style: TextStyle(
                              fontSize: _responsiveFontSize(screenWidth, 10),
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white70
                                  : neutralGray),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen, double screenWidth) {
    final headerColor = widget.isReturnJourney ? accentBlue : primaryRed;
    final headerText = widget.isReturnJourney
        ? "Pilih Kereta Pulang"
        : "Pilih Kereta Berangkat";

    return Container(
      padding: EdgeInsets.fromLTRB(
          _responsiveHorizontalPadding(screenWidth),
          _responsiveFontSize(screenWidth, 20),
          _responsiveHorizontalPadding(screenWidth),
          _responsiveFontSize(screenWidth, 12)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 12)),
            decoration: BoxDecoration(
                color: headerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.train,
                color: headerColor, size: _responsiveIconSize(screenWidth, 24)),
          ),
          SizedBox(width: _responsiveFontSize(screenWidth, 16)),
          Expanded(
            child: Text(
              headerText,
              style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 20),
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                  letterSpacing: -0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalList(bool isSmallScreen, double screenWidth) {
    return StreamBuilder<List<JadwalModel>>(
      stream: _jadwalStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), screenWidth);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(screenWidth);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
              "Tidak ada jadwal untuk rute dan tanggal ini.", screenWidth);
        }
        final jadwalList = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              _responsiveHorizontalPadding(screenWidth),
              0,
              _responsiveHorizontalPadding(screenWidth),
              _responsiveFontSize(screenWidth, 20)),
          itemCount: jadwalList.length,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _buildJadwalCard(jadwalList[index], index, screenWidth),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          Text(
            "Mencari jadwal kereta...",
            style: TextStyle(
              fontSize: _responsiveFontSize(screenWidth, 16),
              fontWeight: FontWeight.w500,
              color: neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, double screenWidth) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(_responsiveFontSize(screenWidth, 32)),
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 32)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
              decoration: BoxDecoration(
                color: lightRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.train_outlined,
                size: _responsiveIconSize(screenWidth, 48),
                color: primaryRed,
              ),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 16)),
            Text(
              "Tidak Ada Jadwal",
              style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 18),
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 14),
                color: neutralGray,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, double screenWidth) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(_responsiveFontSize(screenWidth, 32)),
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 24)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: _responsiveIconSize(screenWidth, 48),
              color: Colors.red,
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 16)),
            Text(
              "Terjadi Kesalahan",
              style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 18),
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 8)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 14),
                color: neutralGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard(JadwalModel jadwal, int index, double screenWidth) {
    final String kodeAsal = _getKodeFromDisplayName(widget.stasiunAsal);
    final String kodeTujuan = _getKodeFromDisplayName(widget.stasiunTujuan);

    return Container(
      margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 16.0)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            // A. Jika ini perjalanan SEKALI JALAN atau pemilihan jadwal PERGI untuk tiket PP
            if (!widget.isReturnJourney) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PilihKelasScreen(
                    // Layar selanjutnya akan menampilkan kelas untuk jadwal ini
                    jadwalUntukDitampilkan: jadwal,
                    // Kirim juga data pergi (yang merupakan jadwal ini sendiri)
                    jadwalPergi: jadwal,
                    // Kirim semua info relevan untuk melanjutkan alur
                    isRoundTrip: widget.isRoundTrip,
                    tanggalPulang: widget.tanggalPulang,
                    stasiunAsalDisplay: widget.stasiunAsal,
                    stasiunTujuanDisplay: widget.stasiunTujuan,
                    tanggalBerangkat: widget.tanggalBerangkat,
                    jumlahDewasa: widget.jumlahDewasa,
                    jumlahBayi: widget.jumlahBayi,
                  ),
                ),
              );
            }
            // B. Jika ini adalah pemilihan jadwal PULANG untuk tiket PP
            else {
              // Pastikan data pergi (jadwal & kelas) tidak null
              if (widget.jadwalPergi == null || widget.kelasPergi == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error: Data perjalanan pergi tidak lengkap.")),
                );
                return;
              }
              // Navigasi ke PilihKelasScreen untuk memilih kelas PULANG
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PilihKelasScreen(
                    jadwalPergi: widget.jadwalPergi,
                    kelasPergi: widget.kelasPergi,
                    // Jadwal pulang baru dipilih, ini yang akan ditampilkan kelasnya
                    jadwalUntukDitampilkan: jadwal,
                    // Kirim data pulang yang baru dipilih
                    jadwalPulang: jadwal,
                    isRoundTrip: true,
                    tanggalPulang: widget.tanggalPulang,
                    // Stasiun display tetap sama seperti dari pencarian awal
                    stasiunAsalDisplay: widget.stasiunAsal,
                    stasiunTujuanDisplay: widget.stasiunTujuan,
                    tanggalBerangkat: widget.tanggalBerangkat,
                    jumlahDewasa: widget.jumlahDewasa,
                    jumlahBayi: widget.jumlahBayi,
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrainHeader(jadwal, screenWidth),
                SizedBox(height: _responsiveFontSize(screenWidth, 20.0)),
                _buildJourneyInfo(jadwal, screenWidth, kodeAsal, kodeTujuan),
                SizedBox(height: _responsiveFontSize(screenWidth, 16.0)),
                _buildPriceInfo(jadwal, screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainHeader(JadwalModel jadwal, double screenWidth) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 10)),
          decoration: BoxDecoration(
            color: primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.train,
            color: primaryRed,
            size: _responsiveIconSize(screenWidth, 24),
          ),
        ),
        SizedBox(width: _responsiveFontSize(screenWidth, 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jadwal.namaKereta.toUpperCase(),
                style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 18),
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: _responsiveFontSize(screenWidth, 2)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8), vertical: _responsiveFontSize(screenWidth, 4)),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  jadwal.idKereta,
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 12),
                    fontWeight: FontWeight.w600,
                    color: accentBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ✨ PERUBAHAN UTAMA ADA DI SINI ✨ ---
  Widget _buildJourneyInfo(JadwalModel jadwal, double screenWidth, String kodeAsal, String kodeTujuan) {
    return Container(
      padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Gunakan method baru untuk mendapatkan jam berangkat dari stasiun yang dicari
                  jadwal.getJamBerangkatUntukSegmen(kodeAsal),
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 20),
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                SizedBox(height: _responsiveFontSize(screenWidth, 4)),
                Text(
                  // Tampilkan kode stasiun yang dicari
                  kodeAsal,
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 13),
                    color: neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: _responsiveFontSize(screenWidth, 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryRed.withOpacity(0.3),
                        primaryRed,
                        primaryRed.withOpacity(0.3)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                SizedBox(height: _responsiveFontSize(screenWidth, 8)),
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 6)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryRed.withOpacity(0.2)),
                  ),
                  child: Text(
                    // Gunakan method baru untuk mendapatkan durasi sesuai rute yang dicari
                    jadwal.getDurasiUntukSegmen(kodeAsal, kodeTujuan),
                    style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 11),
                      fontWeight: FontWeight.w600,
                      color: primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  // Gunakan method baru untuk mendapatkan jam tiba di stasiun yang dicari
                  jadwal.getJamTibaUntukSegmen(kodeTujuan),
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 20),
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                SizedBox(height: _responsiveFontSize(screenWidth, 4)),
                Text(
                  // Tampilkan kode stasiun yang dicari
                  kodeTujuan,
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 13),
                    color: neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(JadwalModel jadwal, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightBlue, Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Harga mulai dari",
                style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 12),
                  color: neutralGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: _responsiveFontSize(screenWidth, 4)),
              Text(
                currencyFormatter.format(jadwal.hargaMulaiDari),
                style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 18),
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16), vertical: _responsiveFontSize(screenWidth, 8)),
            decoration: BoxDecoration(
              color: accentBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pilih",
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: _responsiveFontSize(screenWidth, 4)),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: _responsiveIconSize(screenWidth, 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}