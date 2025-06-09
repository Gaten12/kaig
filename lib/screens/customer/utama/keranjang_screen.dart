import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/screens/customer/utama/keranjang_pembayaran_screen.dart';
import 'package:kaig/services/keranjang_service.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final KeranjangService _keranjangService = KeranjangService();
  Stream<List<KeranjangModel>>? _keranjangStream;

  // State untuk menyimpan data dan pilihan
  List<KeranjangModel> _semuaItemKeranjang = [];
  List<String> _selectedItemsIds = [];
  bool _pilihSemua = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _keranjangStream = _keranjangService.getKeranjangStream(user.uid);
    }
  }

  // Fungsi ini tidak berubah
  void _onPilihSemua(bool? value) {
    setState(() {
      _pilihSemua = value ?? false;
      if (_pilihSemua) {
        _selectedItemsIds = _semuaItemKeranjang.map((item) => item.id!).toList();
      } else {
        _selectedItemsIds.clear();
      }
    });
  }

  // Fungsi ini tidak berubah
  void _onItemSelect(String itemId) {
    setState(() {
      if (_selectedItemsIds.contains(itemId)) {
        _selectedItemsIds.remove(itemId);
      } else {
        _selectedItemsIds.add(itemId);
      }
      if (_selectedItemsIds.length == _semuaItemKeranjang.length && _semuaItemKeranjang.isNotEmpty) {
        _pilihSemua = true;
      } else {
        _pilihSemua = false;
      }
    });
  }

  // Fungsi ini tidak berubah
  void _checkout() {
    if (_selectedItemsIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih minimal satu pesanan untuk di-checkout.")));
      return;
    }

    final itemsToCheckout = _semuaItemKeranjang
        .where((item) => _selectedItemsIds.contains(item.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KeranjangPembayaranScreen(itemsToCheckout: itemsToCheckout)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: StreamBuilder<List<KeranjangModel>>(
        stream: _keranjangStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // --- PERBAIKAN UTAMA DI SINI ---
          // Perbarui state lokal HANYA jika ada data baru dari stream.
          if (snapshot.hasData) {
            _semuaItemKeranjang = snapshot.data!;
            // Hapus item terpilih yang sudah tidak ada di keranjang
            _selectedItemsIds.removeWhere((id) => !_semuaItemKeranjang.any((item) => item.id == id));
          }

          if (_semuaItemKeranjang.isEmpty) {
            return const Center(child: Text("Keranjang Anda kosong."));
          }

          // UI sekarang menggunakan state lokal `_semuaItemKeranjang`
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _pilihSemua,
                      onChanged: _onPilihSemua,
                    ),
                    const Text("Pilih semua"),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _semuaItemKeranjang.length,
                  itemBuilder: (context, index) {
                    final item = _semuaItemKeranjang[index];
                    return _buildKeranjangItemCard(item);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutButton(),
    );
  }

  Widget _buildKeranjangItemCard(KeranjangModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _selectedItemsIds.contains(item.id), // Gunakan _selectedItemsIds
              onChanged: (_) => _onItemSelect(item.id!),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SisaWaktuWidget(batasWaktu: item.batasWaktuPembayaran.toDate()),
                  const SizedBox(height: 8),
                  Text("${item.jadwalDipesan.namaKereta} (${item.jadwalDipesan.idKereta})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${item.jadwalDipesan.idStasiunAsal} ❯ ${item.jadwalDipesan.idStasiunTujuan}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: Text("${item.penumpang.length} Penumpang"),
                    tilePadding: EdgeInsets.zero,
                    children: item.penumpang.map((p) => ListTile(
                      title: Text(p['nama']!),
                      subtitle: Text("Kursi: ${p['kursi']!}"),
                      trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item.kelasDipilih.harga)),
                    )).toList(),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item.totalBayar), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return _selectedItemsIds.isEmpty
        ? const SizedBox.shrink()
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue
        ),
        onPressed: _checkout,
        child: Text("Checkout (${_selectedItemsIds.length})"),
      ),
    );
  }
}

class _SisaWaktuWidget extends StatefulWidget {
  final DateTime batasWaktu;
  const _SisaWaktuWidget({required this.batasWaktu});

  @override
  State<_SisaWaktuWidget> createState() => _SisaWaktuWidgetState();
}

class _SisaWaktuWidgetState extends State<_SisaWaktuWidget> {
  late Timer _timer;
  Duration _sisaWaktu = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sisaWaktu = widget.batasWaktu.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _sisaWaktu = widget.batasWaktu.difference(DateTime.now());
      });
      if (_sisaWaktu.isNegative) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sisaWaktu.isNegative) {
      // Anda bisa menambahkan logika di sini untuk menghapus item dari keranjang jika waktu habis
      return const Text("Waktu habis", style: TextStyle(color: Colors.red));
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_sisaWaktu.inHours);
    final minutes = twoDigits(_sisaWaktu.inMinutes.remainder(60));
    final seconds = twoDigits(_sisaWaktu.inSeconds.remainder(60));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          const Text("Sisa waktu pelunasan", style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text("$hours:$minutes:$seconds", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}