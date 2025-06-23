import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  StasiunModel? _stasiunAsal;
  StasiunModel? _stasiunTujuan;

  DateTime? _selectedTanggalPergi;
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
      MaterialPageRoute(
        builder: (context) => const PilihStasiunScreen(),
      ),
    );

    if (stasiunTerpilih != null && mounted) {
      setState(() {
        if (isAsal) {
          _stasiunAsal = stasiunTerpilih;
        } else {
          _stasiunTujuan = stasiunTerpilih;
        }
      });
    }
  }

  void _swapLokasi() {
    final temp = _stasiunAsal;
    setState(() {
      _stasiunAsal = _stasiunTujuan;
      _stasiunTujuan = temp;
    });
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalPergi ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Keberangkatan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTanggalPergi && mounted) {
      setState(() {
        _selectedTanggalPergi = picked;
      });
    }
  }

  void _showPassengerSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: PassengerSelectionWidget(
            initialDewasa: _jumlahDewasa,
            initialBayi: _jumlahBayi,
            onSelesai: (int dewasa, int bayi) {
              if (mounted) {
                setState(() {
                  _jumlahDewasa = dewasa;
                  _jumlahBayi = bayi;
                });
              }
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _cariTiket() {
    if (_formKey.currentState!.validate()) {
      if (_stasiunAsal == null) {
        _showErrorSnackBar('Silakan pilih stasiun keberangkatan.');
        return;
      }
      if (_stasiunTujuan == null) {
        _showErrorSnackBar('Silakan pilih stasiun tujuan.');
        return;
      }
      if (_selectedTanggalPergi == null) {
        _showErrorSnackBar('Silakan pilih tanggal keberangkatan.');
        return;
      }
      if (_stasiunAsal!.id == _stasiunTujuan!.id) {
        _showErrorSnackBar('Stasiun asal dan tujuan tidak boleh sama.');
        return;
      }
      if ((_jumlahDewasa + _jumlahBayi) == 0) {
        _showErrorSnackBar('Jumlah penumpang minimal 1 orang.');
        return;
      }
      if (_jumlahBayi > 0 && _jumlahDewasa == 0) {
        _showErrorSnackBar('Bayi harus didampingi penumpang dewasa.');
        return;
      }
      if (_jumlahBayi > _jumlahDewasa) {
        _showErrorSnackBar(
            'Jumlah bayi tidak boleh melebihi jumlah penumpang dewasa.');
        return;
      }

      print("--- Memulai Navigasi ke PilihJadwalScreen ---");
      print(
          "Stasiun Asal: ${_stasiunAsal?.displayName} (ID: ${_stasiunAsal?.id})");
      print(
          "Stasiun Tujuan: ${_stasiunTujuan?.displayName} (ID: ${_stasiunTujuan?.id})");
      print("Tanggal Pergi: $_selectedTanggalPergi");
      print("Jumlah Dewasa: $_jumlahDewasa");
      print("Jumlah Bayi: $_jumlahBayi");
      print("--- Mengirim Data ---");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PilihJadwalScreen(
            stasiunAsal: _stasiunAsal!.displayName,
            stasiunTujuan: _stasiunTujuan!.displayName,
            tanggalBerangkat: _selectedTanggalPergi!,
            jumlahDewasa: _jumlahDewasa,
            jumlahBayi: _jumlahBayi,
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  Widget _buildEnhancedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    String penumpangDisplay = "$_jumlahDewasa Dewasa";
    if (_jumlahBayi > 0) {
      penumpangDisplay += ", $_jumlahBayi Bayi";
    }

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Pesan Tiket',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: primaryRed,
        // Remove the leading IconButton to remove the back button
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        automaticallyImplyLeading: false, // This will remove the default back button
        elevation: 0,
      ),
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
                        child: InkWell(
                          onTap: () => _pilihTanggal(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: primaryRed,
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
                                        'Tanggal Keberangkatan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedTanggalPergi == null
                                            ? 'Pilih tanggal perjalanan'
                                            : DateFormat('EEEE, dd MMMM yyyy',
                                            'id_ID')
                                            .format(_selectedTanggalPergi!),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'Pulang Pergi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Switch(
                                      value: _isPulangPergi,
                                      onChanged: (value) {
                                        setState(() {
                                          _isPulangPergi = value;
                                          if (_isPulangPergi) {
                                            _showErrorSnackBar(
                                                'Fitur Pulang Pergi belum diimplementasikan sepenuhnya.');
                                          }
                                        });
                                      },
                                      activeColor: accentBlue,
                                      materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                )
                              ],
                            ),
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
}
