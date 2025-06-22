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

  void _onDateTabSelected(DateTime selectedDate) {
    if (!mounted) return;
    setState(() {
      _currentSelectedDate = selectedDate;
      _updateJadwalStream();
    });
  }

  void _updateJadwalStream() {
    String kodeAsal =
        widget.stasiunAsal.contains("(") && widget.stasiunAsal.contains(")")
            ? widget.stasiunAsal.substring(widget.stasiunAsal.indexOf("(") + 1,
                widget.stasiunAsal.indexOf(")"))
            : widget.stasiunAsal;
    String kodeTujuan =
        widget.stasiunTujuan.contains("(") && widget.stasiunTujuan.contains(")")
            ? widget.stasiunTujuan.substring(
                widget.stasiunTujuan.indexOf("(") + 1,
                widget.stasiunTujuan.indexOf(")"))
            : widget.stasiunTujuan;

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

  @override
  Widget build(BuildContext context) {
    print("[PilihJadwalScreen] Build method dipanggil.");
    return Scaffold(
      backgroundColor: lightGray,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildDateTabsWidget(),
            _buildHeaderSection(),
            Expanded(child: _buildJadwalList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: const Icon(
                  Icons.train,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  widget.stasiunTujuan.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatInfoPenumpangAppBar(),
            style: const TextStyle(
              fontSize: 12,
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
                Colors.white.withAlpha((255 * 0.3).round()),
                Colors.transparent
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTabsWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
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
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onDateTabSelected(date),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? accentBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? accentBlue
                            : neutralGray.withAlpha((255 * 0.3).round()),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentBlue.withAlpha((255 * 0.3).round()),
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : neutralGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd', 'id_ID').format(date),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : darkGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM', 'id_ID').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
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

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryRed.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.train,
              color: primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Pilih Kereta Berangkat",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGray,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_dateTabs.length} hari",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalList() {
    return StreamBuilder<List<JadwalModel>>(
      stream: _jadwalStream,
      builder: (context, snapshot) {
        print(
            "[PilihJadwalScreen] StreamBuilder: ConnectionState = ${snapshot.connectionState}");

        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyState("Tidak ada data jadwal tersedia saat ini.");
        }

        final jadwalList = snapshot.data!;
        print(
            "[PilihJadwalScreen] Data diterima, jumlah item = ${jadwalList.length}");

        if (jadwalList.isEmpty) {
          return _buildEmptyState(
              "Tidak ada jadwal untuk rute dan tanggal ini.");
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: jadwalList.length,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _buildJadwalCard(jadwalList[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.1).round()),
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
          const SizedBox(height: 16),
          const Text(
            "Mencari jadwal kereta...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.08).round()),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.train_outlined,
                size: 48,
                color: primaryRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Tidak Ada Jadwal",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: neutralGray,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withAlpha((255 * 0.2).round())),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha((255 * 0.1).round()),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              "Terjadi Kesalahan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: neutralGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard(JadwalModel jadwal, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        elevation: 2,
        shadowColor: Colors.black.withAlpha((255 * 0.1).round()),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrainHeader(jadwal),
                const SizedBox(height: 20.0),
                _buildJourneyInfo(jadwal),
                const SizedBox(height: 16.0),
                _buildPriceInfo(jadwal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainHeader(JadwalModel jadwal) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryRed.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.train,
            color: primaryRed,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jadwal.namaKereta.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  jadwal.idKereta,
                  style: const TextStyle(
                    fontSize: 12,
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

  Widget _buildJourneyInfo(JadwalModel jadwal) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  jadwal.jamBerangkatFormatted,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jadwal.idStasiunAsal,
                  style: const TextStyle(
                    fontSize: 13,
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
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryRed.withAlpha((255 * 0.3).round()),
                        primaryRed,
                        primaryRed.withAlpha((255 * 0.3).round())
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryRed.withAlpha((255 * 0.2).round())),
                  ),
                  child: Text(
                    jadwal.durasiPerjalananTotal,
                    style: const TextStyle(
                      fontSize: 11,
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
                  jadwal.jamTibaFormatted,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jadwal.idStasiunTujuan,
                  style: const TextStyle(
                    fontSize: 13,
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

  Widget _buildPriceInfo(JadwalModel jadwal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightBlue, Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBlue.withAlpha((255 * 0.2).round())),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Harga mulai dari",
                style: TextStyle(
                  fontSize: 12,
                  color: neutralGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormatter.format(jadwal.hargaMulaiDari),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accentBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentBlue.withAlpha((255 * 0.3).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pilih",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
