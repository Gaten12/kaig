import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/JadwalModel.dart';
import '../../../admin/services/admin_firestore_service.dart';
import 'PilihKelasScreen.dart';

class PilihJadwalScreen extends StatefulWidget {
  final String stasiunAsal;
  final String stasiunTujuan;
  final DateTime tanggalBerangkat;
  final int jumlahDewasa;
  final int jumlahBayi;

  const PilihJadwalScreen({
    super.key,
    required this.stasiunAsal,
    required this.stasiunTujuan,
    required this.tanggalBerangkat,
    required this.jumlahDewasa,
    required this.jumlahBayi,
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

  // Elegant Train Color Scheme
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
    _currentSelectedDate = widget.tanggalBerangkat;
    _generateDateTabs();
    _updateJadwalStream();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    print("[PilihJadwalScreen] initState: Customer Mode");
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
    if (!_dateTabs.any((d) =>
    d.year == _currentSelectedDate.year &&
        d.month == _currentSelectedDate.month &&
        d.day == _currentSelectedDate.day)) {
      _currentSelectedDate = _dateTabs.isNotEmpty ? _dateTabs.first : baseDate;
    }
  }

  // --- ✨ FUNGSI BARU UNTUK MENDAPATKAN KODE STASIUN ---
  /// Helper untuk mengekstrak kode stasiun dari display name, contoh: "GAMBIR (GMR)" -> "GMR"
  String _getKodeFromDisplayName(String displayName) {
    if (displayName.contains("(") && displayName.contains(")")) {
      return displayName.substring(displayName.indexOf("(") + 1, displayName.indexOf(")"));
    }
    // Jika format tidak sesuai, kembalikan string asli sebagai fallback
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
    // Gunakan helper yang sudah dibuat
    String kodeAsal = _getKodeFromDisplayName(widget.stasiunAsal);
    String kodeTujuan = _getKodeFromDisplayName(widget.stasiunTujuan);

    print(
        "[PilihJadwalScreen] Memperbarui stream untuk tanggal: ${DateFormat('yyyy-MM-dd').format(_currentSelectedDate)}");
    print(
        "Asal: $kodeAsal (dari ${widget.stasiunAsal}), Tujuan: $kodeTujuan (dari ${widget.stasiunTujuan})");

    setState(() {
      _jadwalStream = _firestoreService.getJadwalList(
          tanggal: _currentSelectedDate,
          kodeAsal: kodeAsal.toUpperCase(),
          kodeTujuan: kodeTujuan.toUpperCase());
    });
  }

  String _formatInfoPenumpangAppBar() {
    String tanggalFormatted =
    DateFormat('EEE, dd MMM yy', 'id_ID').format(widget.tanggalBerangkat);
    String dewasaInfo = "${widget.jumlahDewasa} Dewasa";
    String bayiInfo =
    widget.jumlahBayi > 0 ? ", ${widget.jumlahBayi} Bayi" : "";
    return "$tanggalFormatted  •  $dewasaInfo$bayiInfo";
  }

  // Helper method for responsive font sizes
  double _responsiveFontSize(double screenWidth, double baseSize) {
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
      return (screenWidth - 1000) / 2;
    } else if (screenWidth > 600) {
      return 24.0;
    } else {
      return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("[PilihJadwalScreen] Build method dipanggil.");
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
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: _responsiveIconSize(screenWidth, 20)),
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 8)),
                child: Icon(
                  Icons.train,
                  color: Colors.white,
                  size: _responsiveIconSize(screenWidth, 20),
                ),
              ),
              Expanded(
                child: Text(
                  widget.stasiunTujuan.toUpperCase(),
                  style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
              color: Colors.white70,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.3),
                Colors.transparent
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTabsWidget(bool isSmallScreen, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? _responsiveFontSize(screenWidth, 8.0) : _responsiveFontSize(screenWidth, 16.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _dateTabs.map((date) {
          bool isSelected = date.year == _currentSelectedDate.year &&
              date.month == _currentSelectedDate.month &&
              date.day == _currentSelectedDate.day;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? _responsiveFontSize(screenWidth, 2.0) : _responsiveFontSize(screenWidth, 4.0)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onDateTabSelected(date),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                        horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 16)),
                    decoration: BoxDecoration(
                      color: isSelected ? accentBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? accentBlue
                            : neutralGray.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: accentBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
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
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: _responsiveFontSize(screenWidth, 4)),
                        Text(
                          DateFormat('dd', 'id_ID').format(date),
                          style: TextStyle(
                            fontSize: _responsiveFontSize(screenWidth, 18),
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : darkGray,
                          ),
                        ),
                        SizedBox(height: _responsiveFontSize(screenWidth, 2)),
                        Text(
                          DateFormat('MMM', 'id_ID').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: _responsiveFontSize(screenWidth, 10),
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white70 : neutralGray,
                          ),
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
    return Container(
      padding: EdgeInsets.fromLTRB(_responsiveHorizontalPadding(screenWidth), _responsiveFontSize(screenWidth, 20), _responsiveHorizontalPadding(screenWidth), _responsiveFontSize(screenWidth, 12)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 12)),
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
            child: Text(
              "Pilih Kereta Berangkat",
              style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 20),
                fontWeight: FontWeight.bold,
                color: darkGray,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 12), vertical: _responsiveFontSize(screenWidth, 6)),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_dateTabs.length} hari",
              style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 12),
                fontWeight: FontWeight.w600,
                color: accentBlue,
              ),
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
        print(
            "[PilihJadwalScreen] StreamBuilder: ConnectionState = ${snapshot.connectionState}");

        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return _buildErrorState(snapshot.error.toString(), screenWidth);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(screenWidth);
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyState("Tidak ada data jadwal tersedia saat ini.", screenWidth);
        }

        final jadwalList = snapshot.data!;
        print(
            "[PilihJadwalScreen] Data diterima, jumlah item = ${jadwalList.length}");

        if (jadwalList.isEmpty) {
          return _buildEmptyState(
              "Tidak ada jadwal untuk rute dan tanggal ini.", screenWidth);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(_responsiveHorizontalPadding(screenWidth), 0, _responsiveHorizontalPadding(screenWidth), _responsiveFontSize(screenWidth, 20)),
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

  // --- ✨ PERUBAHAN UTAMA ADA DI SINI ✨ ---
  Widget _buildJadwalCard(JadwalModel jadwal, int index, double screenWidth) {
    // Ambil kode stasiun dari widget untuk digunakan di dalam card
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PilihKelasScreen(
                  jadwalDipesan: jadwal,
                  stasiunAsalDisplay: widget.stasiunAsal,
                  stasiunTujuanDisplay: widget.stasiunTujuan,
                  tanggalBerangkat: _currentSelectedDate,
                  jumlahDewasa: widget.jumlahDewasa,
                  jumlahBayi: widget.jumlahBayi,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrainHeader(jadwal, screenWidth),
                SizedBox(height: _responsiveFontSize(screenWidth, 20.0)),
                // Kirim kode asal dan tujuan ke _buildJourneyInfo
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