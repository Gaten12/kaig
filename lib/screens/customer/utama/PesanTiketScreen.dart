import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'PilihJadwalScreen.dart';
import 'PilihStasiunScreen.dart';
import '../../../models/stasiun_model.dart';
import '../../../widgets/passenger_selection_widget.dart';

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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (context) {
        return PassengerSelectionWidget(
          initialDewasa: _jumlahDewasa,
          initialBayi: _jumlahBayi,
          onSelesai: (int dewasa, int bayi) {
            if (mounted) {
              setState(() {
                _jumlahDewasa = dewasa;
                _jumlahBayi = bayi;
              });
            }
            Navigator.pop(context); // Tutup bottom sheet
          },
        );
      },
    );
  }

  void _cariTiket() {
    if (_formKey.currentState!.validate()) {
      if (_stasiunAsal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih stasiun keberangkatan.')),
        );
        return;
      }
      if (_stasiunTujuan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih stasiun tujuan.')),
        );
        return;
      }
      if (_selectedTanggalPergi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih tanggal keberangkatan.')),
        );
        return;
      }
      if (_stasiunAsal!.id == _stasiunTujuan!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stasiun asal dan tujuan tidak boleh sama.')),
        );
        return;
      }
      if ((_jumlahDewasa + _jumlahBayi) == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah penumpang minimal 1 orang.')),
        );
        return;
      }
      if (_jumlahBayi > 0 && _jumlahDewasa == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bayi harus didampingi penumpang dewasa.')),
        );
        return;
      }
      if (_jumlahBayi > _jumlahDewasa) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah bayi tidak boleh melebihi jumlah penumpang dewasa.')),
        );
        return;
      }

      print("--- Memulai Navigasi ke PilihJadwalScreen ---");
      print("Stasiun Asal: ${_stasiunAsal?.displayName} (ID: ${_stasiunAsal?.id})");
      print("Stasiun Tujuan: ${_stasiunTujuan?.displayName} (ID: ${_stasiunTujuan?.id})");
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

  Widget _buildStasiunField({
    required String label,
    required StasiunModel? stasiun,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stasiun?.displayName ?? 'Pilih stasiun',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: stasiun != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String penumpangDisplay = "$_jumlahDewasa Dewasa";
    if (_jumlahBayi > 0) {
      penumpangDisplay += ", $_jumlahBayi Bayi";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kereta Antar Kota'),
        elevation: 1.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildStasiunField(
                              label: 'Dari',
                              stasiun: _stasiunAsal,
                              icon: Icons.train_outlined,
                              onTap: () => _pilihStasiunUntuk(true),
                            ),
                            const Divider(height: 20, thickness: 1),
                            _buildStasiunField(
                              label: 'Ke',
                              stasiun: _stasiunTujuan,
                              icon: Icons.train_outlined,
                              onTap: () => _pilihStasiunUntuk(false),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.swap_vert_circle_outlined, color: Colors.blue, size: 36),
                          onPressed: _swapLokasi,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pilihTanggal(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Tanggal pergi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                _selectedTanggalPergi == null
                                    ? 'Pilih tanggal'
                                    : DateFormat('EEE, dd MMM yy', 'id_ID').format(_selectedTanggalPergi!), // Format EEE, dd MMM yyyy
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const Text('Pulang Pergi', style: TextStyle(fontSize: 11)),
                          Switch(
                            value: _isPulangPergi,
                            onChanged: (value) {
                              setState(() {
                                _isPulangPergi = value;
                                if (_isPulangPergi) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Fitur Pulang Pergi belum diimplementasikan sepenuhnya.')));
                                }
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: _showPassengerSelectionBottomSheet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Penumpang', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(penumpangDisplay,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              if (_jumlahBayi > 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    'Penumpang bayi tidak mendapatkan kursi sendiri.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _cariTiket,
                child: const Text('CARI TIKET ANTAR KOTA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}