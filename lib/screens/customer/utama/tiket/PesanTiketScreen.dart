import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/screens/customer/utama/akun/informasi_data_diri_screen.dart';
import 'package:kaig/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/stasiun_model.dart';
import '../../../../widgets/passenger_selection_widget.dart';
import 'PilihJadwalScreen.dart';
import 'PilihStasiunScreen.dart';

class PesanTiketScreen extends StatefulWidget {
  const PesanTiketScreen({super.key});

  @override
  State<PesanTiketScreen> createState() => _PesanTiketScreenState();
}

class _PesanTiketScreenState extends State<PesanTiketScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // State
  StasiunModel? _stasiunAsal;
  StasiunModel? _stasiunTujuan;
  DateTime? _selectedTanggalPergi;
  DateTime? _selectedTanggalPulang;
  int _jumlahDewasa = 1;
  int _jumlahBayi = 0;
  bool _isPulangPergi = false;


  // Enhanced color scheme
  static const Color primaryRed = Color(0xFFC50000);

  static const Color accentBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color backgroundGrey = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  // New color for the search button
  static const Color searchButtonColor = Color(0xFF304FFE);


  Future<void> _pilihStasiunUntuk(bool isAsal) async {
    final StasiunModel? stasiunTerpilih = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PilihStasiunScreen()),
    );
    if (stasiunTerpilih != null && mounted) {
      setState(() => isAsal ? _stasiunAsal = stasiunTerpilih : _stasiunTujuan = stasiunTerpilih);
    }
  }

  void _swapLokasi() {
    final temp = _stasiunAsal;
    setState(() {
      _stasiunAsal = _stasiunTujuan;
      _stasiunTujuan = temp;
    });
  }

  Future<void> _pilihTanggalPergi(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalPergi ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Keberangkatan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryRed, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTanggalPergi && mounted) {
      setState(() {
        _selectedTanggalPergi = picked;
        if (_isPulangPergi && _selectedTanggalPulang != null && _selectedTanggalPulang!.isBefore(picked)) {
          _selectedTanggalPulang = null; // Reset tanggal pulang jika jadi tidak valid
        }
      });
    }
  }

  Future<void> _pilihTanggalPulang(BuildContext context) async {
    if (_selectedTanggalPergi == null) {
      _showErrorSnackBar('Pilih tanggal keberangkatan terlebih dahulu.');
      return;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalPulang ?? _selectedTanggalPergi!,
      firstDate: _selectedTanggalPergi!,
      lastDate: _selectedTanggalPergi!.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Pulang',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: accentBlue, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTanggalPulang && mounted) {
      setState(() => _selectedTanggalPulang = picked);
    }
  }

  void _showPassengerSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: PassengerSelectionWidget(
          initialDewasa: _jumlahDewasa,
          initialBayi: _jumlahBayi,
          onSelesai: (int dewasa, int bayi) {
            if (mounted) setState(() { _jumlahDewasa = dewasa; _jumlahBayi = bayi; });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _cariTiket() async {
    // Pengecekan data diri pengguna
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userModel = await _authService.getUserModel(user.uid);
      final primaryPassenger = await _authService.getPrimaryPassenger(user.uid);
      if (userModel == null || primaryPassenger == null || userModel.noTelepon.isEmpty || primaryPassenger.namaLengkap.isEmpty) {
        if (mounted) {
          showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Data Diri Belum Lengkap"),
                content: const Text("Anda harus melengkapi data diri Anda di menu Akun sebelum dapat memesan tiket."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InformasiDataDiriScreen()));
                    },
                    child: const Text("Lengkapi Sekarang"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Nanti"),
                  ),
                ],
              ));
        }
        return; // Hentikan proses jika data tidak lengkap
      }
    } else {
      // Jika pengguna belum login
      _showErrorSnackBar('Anda harus login untuk memesan tiket.');
      return;
    }


    if (_formKey.currentState!.validate()) {
      if (_stasiunAsal == null) { _showErrorSnackBar('Pilih stasiun keberangkatan.'); return; }
      if (_stasiunTujuan == null) { _showErrorSnackBar('Pilih stasiun tujuan.'); return; }
      if (_selectedTanggalPergi == null) { _showErrorSnackBar('Pilih tanggal keberangkatan.'); return; }
      if (_isPulangPergi && _selectedTanggalPulang == null) { _showErrorSnackBar('Pilih tanggal pulang.'); return; }
      if (_stasiunAsal!.id == _stasiunTujuan!.id) { _showErrorSnackBar('Stasiun asal dan tujuan tidak boleh sama.'); return; }
      if ((_jumlahDewasa + _jumlahBayi) == 0) { _showErrorSnackBar('Jumlah penumpang minimal 1 orang.'); return; }
      if (_jumlahBayi > _jumlahDewasa) { _showErrorSnackBar('Jumlah bayi tidak boleh melebihi jumlah penumpang dewasa.'); return; }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PilihJadwalScreen(
            stasiunAsal: _stasiunAsal!.displayName,
            stasiunTujuan: _stasiunTujuan!.displayName,
            tanggalBerangkat: _selectedTanggalPergi!,
            jumlahDewasa: _jumlahDewasa,
            jumlahBayi: _jumlahBayi,
            isRoundTrip: _isPulangPergi,
            tanggalPulang: _selectedTanggalPulang,
            isReturnJourney: false,
            jadwalPergi: null,
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [ const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]),
      backgroundColor: primaryRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Widget _buildStasiunField({
    required String label,
    required StasiunModel? stasiun,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestination = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestination
                    ? lightBlue.withOpacity(0.1)
                    : primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestination ? accentBlue : primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stasiun?.displayName ?? 'Pilih stasiun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: stasiun != null ? textPrimary : textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right,
              color: textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    String penumpangDisplay = "$_jumlahDewasa Dewasa";
    if (_jumlahBayi > 0) {
      penumpangDisplay += ", $_jumlahBayi Bayi";
    }

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: CustomScrollView(
        slivers: [

          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Station Selection Card
                      _buildEnhancedCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      // Changed icon color to match primaryRed for consistency
                                      color: const Color.fromARGB(255, 7, 0, 197).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF304FFE), // Changed icon color
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Pilih Rute Perjalanan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildStasiunField(
                                          label: 'Stasiun Keberangkatan',
                                          stasiun: _stasiunAsal,
                                          icon: Icons.radio_button_checked,
                                          onTap: () => _pilihStasiunUntuk(true),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          height: 1,
                                          color: dividerColor,
                                        ),
                                        _buildStasiunField(
                                          label: 'Stasiun Tujuan',
                                          stasiun: _stasiunTujuan,
                                          icon: Icons.location_on,
                                          onTap: () =>
                                              _pilihStasiunUntuk(false),
                                          isDestination: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: accentBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.swap_vert,
                                        color: accentBlue,
                                        size: 24,
                                      ),
                                      onPressed: _swapLokasi,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Date Selection Card
                      _buildEnhancedCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Pulang Pergi?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  Switch(
                                    value: _isPulangPergi,
                                    onChanged: (value) => setState(() {
                                      _isPulangPergi = value;
                                      if (!_isPulangPergi) _selectedTanggalPulang = null;
                                    }),
                                    activeColor: accentBlue,
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: dividerColor),
                              // Pemanggilan fungsi yang benar: _pilihTanggalPergi
                              _buildDateField(
                                label: 'Tanggal Keberangkatan',
                                selectedDate: _selectedTanggalPergi,
                                icon: Icons.calendar_month,
                                iconColor: primaryRed,
                                onTap: () => _pilihTanggalPergi(context),
                              ),
                              // Tampilkan field Tanggal Pulang jika toggle aktif
                              if (_isPulangPergi) ...[
                                const Divider(height: 24, color: dividerColor),
                                _buildDateField(
                                  label: 'Tanggal Pulang',
                                  selectedDate: _selectedTanggalPulang,
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: accentBlue,
                                  onTap: () => _pilihTanggalPulang(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Passenger Selection Card
                      _buildEnhancedCard(
                        child: InkWell(
                          onTap: _showPassengerSelectionBottomSheet,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accentBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.people,
                                    color: accentBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Jumlah Penumpang',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        penumpangDisplay,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (_jumlahBayi > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Penumpang bayi tidak mendapatkan kursi sendiri.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32.0),

                      // Search Button
                      Container(
                        decoration: BoxDecoration(
                          // Changed gradient to a solid color as requested
                          color: searchButtonColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: searchButtonColor.withOpacity(0.3), // Use new color for shadow
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _cariTiket,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'CARI TIKET KERETA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  selectedDate == null ? 'Pilih tanggal' : DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}