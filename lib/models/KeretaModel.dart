import 'package:cloud_firestore/cloud_firestore.dart';

class KeretaModel {
  final String id; // ID dokumen dari Firestore (bisa di-generate otomatis)
  final String nama; // Nama kereta, contoh: "ARGO WILIS"
  final String kelasUtama; // Kelas utama layanan kereta, contoh: "Eksekutif", "Ekonomi"
  final int jumlahKursi; // Total jumlah kursi pada kereta tersebut

  KeretaModel({
    required this.id,
    required this.nama,
    required this.kelasUtama,
    required this.jumlahKursi,
  });

  // Factory constructor untuk membuat instance KeretaModel dari Firestore DocumentSnapshot
  factory KeretaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Data kereta null untuk dokumen ID: ${snapshot.id}");
    }
    return KeretaModel(
      id: snapshot.id, // Mengambil ID dokumen dari snapshot
      nama: data['nama'] ?? '',
      kelasUtama: data['kelas'] ?? data['kelasUtama'] ?? '', // Fleksibel jika nama field 'kelas' atau 'kelasUtama'
      jumlahKursi: data['jumlah_kursi'] as int? ?? 0, // Pastikan tipe data int
    );
  }

  // Method untuk mengubah instance KeretaModel menjadi Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'kelas': kelasUtama, // Menyimpan sebagai 'kelas' di Firestore
      'jumlah_kursi': jumlahKursi,
      // ID tidak perlu dimasukkan di sini karena itu adalah ID dokumen
    };
  }
}