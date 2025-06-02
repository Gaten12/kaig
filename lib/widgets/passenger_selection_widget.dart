// lib/src/pembelian_tiket/widgets/passenger_selection_widget.dart
import 'package:flutter/material.dart';

class PassengerSelectionWidget extends StatefulWidget {
  final int initialDewasa;
  final int initialBayi;
  final Function(int dewasa, int bayi) onSelesai;

  const PassengerSelectionWidget({
    super.key,
    required this.initialDewasa,
    required this.initialBayi,
    required this.onSelesai,
  });

  @override
  State<PassengerSelectionWidget> createState() => _PassengerSelectionWidgetState();
}

class _PassengerSelectionWidgetState extends State<PassengerSelectionWidget> {
  late int _dewasaCount;
  late int _bayiCount;

  // Batasan maksimal
  final int _maxDewasa = 4;
  final int _maxBayi = 4;

  @override
  void initState() {
    super.initState();
    _dewasaCount = widget.initialDewasa;
    _bayiCount = widget.initialBayi;
  }

  Widget _buildCounterSection(
      String title,
      String subtitle,
      int count,
      VoidCallback onIncrement, // Mengganti ValueChanged<int> dengan VoidCallback
      VoidCallback onDecrement, // Mengganti ValueChanged<int> dengan VoidCallback
      bool canIncrement, // Tambahan untuk menonaktifkan tombol +
      bool canDecrement, // Tambahan untuk menonaktifkan tombol -
      ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline, size: 30, color: canDecrement ? Colors.grey.shade700 : Colors.grey.shade300),
                onPressed: canDecrement ? onDecrement : null, // Nonaktifkan jika tidak bisa decrement
              ),
              Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.add_circle_outline, size: 30, color: canIncrement ? Colors.blue : Colors.grey.shade300),
                onPressed: canIncrement ? onIncrement : null, // Nonaktifkan jika tidak bisa increment
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Logika untuk tombol +/- Dewasa
    bool canIncrementDewasa = _dewasaCount < _maxDewasa;
    // Minimal 1 dewasa jika ada bayi, atau minimal 0 jika tidak ada bayi.
    // Namun, jika kita ingin minimal selalu 1 dewasa jika ada bayi, dan minimal 1 dewasa jika tidak ada bayi (agar tidak 0 penumpang), maka:
    bool canDecrementDewasa;
    if (_bayiCount > 0) {
      canDecrementDewasa = _dewasaCount > 1; // Jika ada bayi, dewasa tidak boleh kurang dari 1
    } else {
      canDecrementDewasa = _dewasaCount > 1; // Jika tidak ada bayi, dewasa minimal 1 (agar tidak 0 total)
      // Ubah ke _dewasaCount > 0 jika ingin bisa 0 dewasa (jika tidak ada bayi)
      // Untuk aplikasi tiket, minimal 1 dewasa biasanya jadi aturan.
    }
    // Jika ingin total penumpang minimal 1, dan dewasa bisa 0 jika ada bayi (tidak logis untuk tiket kereta)
    // Atau kita set _dewasaCount > 0 (tidak boleh 0)
    // Sesuai contoh sebelumnya, _dewasaCount tidak boleh kurang dari 1 jika _bayiCount > 0.
    // Jika _bayiCount == 0, _dewasaCount juga tidak boleh kurang dari 1 (total penumpang tidak boleh 0).
    // Maka, canDecrementDewasa = _dewasaCount > 1; sudah cukup,
    // karena kondisi _dewasaCount == 1 dan _bayiCount > 0 akan ditangani oleh validasi tombol Selesai.
    // Mari kita sederhanakan: dewasa bisa dikurangi hingga 1. Validasi lebih lanjut di tombol Selesai.
    canDecrementDewasa = _dewasaCount > 1; // Minimal dewasa adalah 1.


    // Logika untuk tombol +/- Bayi
    bool canIncrementBayi = _bayiCount < _maxBayi;
    bool canDecrementBayi = _bayiCount > 0;

    // Validasi untuk tombol SELESAI
    bool isSelesaiButtonEnabled = true;
    String validationMessage = "";

    if (_dewasaCount == 0 && _bayiCount == 0) { // Minimal 1 penumpang (dewasa)
      isSelesaiButtonEnabled = false;
      validationMessage = "Minimal 1 penumpang dewasa.";
    } else if (_bayiCount > 0 && _dewasaCount == 0) { // Jika ada bayi, harus ada dewasa
      isSelesaiButtonEnabled = false;
      validationMessage = 'Setiap bayi harus didampingi minimal 1 penumpang dewasa.';
    } else if (_bayiCount > _dewasaCount) { // Jumlah bayi tidak boleh melebihi jumlah dewasa
      isSelesaiButtonEnabled = false;
      validationMessage = 'Jumlah bayi tidak boleh melebihi jumlah penumpang dewasa.';
    }


    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tambah penumpang',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCounterSection(
                  'Dewasa',
                  '3 tahun ke atas',
                  _dewasaCount,
                      () { if (canIncrementDewasa) setState(() => _dewasaCount++); },
                      () { if (canDecrementDewasa) setState(() => _dewasaCount--); },
                  canIncrementDewasa,
                  canDecrementDewasa
              ),
              const SizedBox(width: 16),
              _buildCounterSection(
                  'Bayi',
                  'Bayi dibawah 3 tahun',
                  _bayiCount,
                      () { if (canIncrementBayi) setState(() => _bayiCount++); },
                      () { if (canDecrementBayi) setState(() => _bayiCount--); },
                  canIncrementBayi,
                  canDecrementBayi
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (!isSelesaiButtonEnabled && validationMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                validationMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelesaiButtonEnabled ? Colors.blue : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: isSelesaiButtonEnabled
                ? () => widget.onSelesai(_dewasaCount, _bayiCount)
                : null, // Nonaktifkan tombol jika validasi gagal
            child: const Text('SELESAI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}