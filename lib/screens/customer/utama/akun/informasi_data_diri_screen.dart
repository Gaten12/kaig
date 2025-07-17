import 'package:flutter/material.dart';
import 'package:kaig/models/user_model.dart';
import 'package:kaig/models/passenger_model.dart';
import 'package:kaig/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kaig/screens/login/login_screen.dart';
import 'package:intl/intl.dart';
import 'ganti_email_screen.dart';
import 'ganti_informasi_pribadi_screen.dart';
import 'ganti_nomor_identitas_screen.dart';
import 'ganti_nomor_telepon_screen.dart';
import 'konfirmasi_password_screen.dart';

class InformasiDataDiriScreen extends StatefulWidget {
  const InformasiDataDiriScreen({super.key});

  @override
  State<InformasiDataDiriScreen> createState() => _InformasiDataDiriScreenState();
}

class _InformasiDataDiriScreenState extends State<InformasiDataDiriScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  PassengerModel? _primaryPassenger;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userModel = await _authService.getUserModel(user.uid);
      final primaryPassenger = await _authService.getPrimaryPassenger(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userModel;
          _primaryPassenger = primaryPassenger;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _hapusAkun() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Hapus Akun"),
          content: const Text("Apakah Anda yakin ingin menghapus akun Anda secara permanen? Tindakan ini tidak dapat dibatalkan."),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Batal")),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _navigasiDenganKonfirmasiPassword(aksiSetelahKonfirmasi: () async {
                  try {
                    await _authService.hapusAkun();
                    if(mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Akun berhasil dihapus.")));
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => LoginEmailScreen()), (route) => false);
                    }
                  } catch (e) {
                    if(mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
                    }
                  }
                });
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            )
          ],
        )
    );
  }

  void _navigasiDenganKonfirmasiPassword({required Future<void> Function() aksiSetelahKonfirmasi, Widget? nextPage}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => KonfirmasiPasswordScreen(
          onPasswordConfirmed: () async {
            Navigator.of(context).pop();
            if (nextPage != null) {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
              _loadData();
            } else {
              await aksiSetelahKonfirmasi();
            }
          }
      ),
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informasi Data Diri"),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userModel == null || _primaryPassenger == null
          ? const Center(child: Text("Gagal memuat data pengguna."))
          : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text("Informasi data diri anda belum lengkap, lengkapi data diri anda untuk menikmati semua layanan TrainOrder", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        _buildInfoTile("No. Telepon", _userModel!.noTelepon, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => GantiNomorTeleponScreen(nomorTeleponSaatIni: _userModel!.noTelepon))).then((_) => _loadData());
        }),
        _buildInfoTile("Email", _userModel!.email, () {
          _navigasiDenganKonfirmasiPassword(
              aksiSetelahKonfirmasi: () async {},
              nextPage: GantiEmailScreen(emailSaatIni: _userModel!.email)
          );
        }),
        _buildInfoTile("Tipe ID & No. ID", "${_primaryPassenger!.tipeId} - ${_primaryPassenger!.nomorId}", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => GantiNomorIdentitasScreen(passenger: _primaryPassenger!))).then((_) => _loadData());
        }),
        _buildDataPribadiCard(),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _hapusAkun,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC50000),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text("HAPUS AKUN"),
        ),
      ],
    );
  }

  Widget _buildDataPribadiCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Nama Lengkap", style: TextStyle(color: Colors.grey, fontSize: 12)),
                TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GantiInformasiPribadiScreen(passenger: _primaryPassenger!))).then((_) => _loadData());
                    },
                    child: const Text("UBAH")
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_primaryPassenger!.namaLengkap, style: const TextStyle(fontSize: 16)),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Jenis Kelamin", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_primaryPassenger!.jenisKelamin, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tanggal Lahir", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(_primaryPassenger!.tanggalLahir.toDate()),
                          style: const TextStyle(fontSize: 16)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, VoidCallback onUbah) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton(onPressed: onUbah, child: const Text("UBAH")),
          ],
        ),
      ),
    );
  }
}