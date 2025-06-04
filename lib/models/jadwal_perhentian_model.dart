import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Diperlukan untuk TimeOfDay
import 'package:intl/intl.dart';

class JadwalPerhentianModel {
  final String idStasiun; // Kode stasiun, contoh: "GMR", "CN", "YK", "SLO"
  final String namaStasiun; // Nama stasiun untuk display, contoh: "GAMBIR"
  final Timestamp? waktuTiba;    // Nullable untuk stasiun awal
  final Timestamp? waktuBerangkat; // Nullable untuk stasiun akhir
  final int urutan; // Urutan stasiun dalam rute (0 untuk asal, 1, 2, ... dst)
  // Tambahkan field lain jika perlu, misal: platform, keterangan

  JadwalPerhentianModel({
    required this.idStasiun,
    required this.namaStasiun, // Sebaiknya nama stasiun juga disimpan untuk kemudahan display
    this.waktuTiba,
    this.waktuBerangkat,
    required this.urutan,
  });

  // Helper untuk mendapatkan TimeOfDay, berguna untuk TimePicker
  TimeOfDay? get timeOfDayTiba => waktuTiba != null ? TimeOfDay.fromDateTime(waktuTiba!.toDate()) : null;
  TimeOfDay? get timeOfDayBerangkat => waktuBerangkat != null ? TimeOfDay.fromDateTime(waktuBerangkat!.toDate()) : null;

  // Helper untuk format tampilan
  String get waktuTibaFormatted => waktuTiba != null ? DateFormat('HH:mm (dd MMM)', 'id_ID').format(waktuTiba!.toDate()) : '-';
  String get waktuBerangkatFormatted => waktuBerangkat != null ? DateFormat('HH:mm (dd MMM)', 'id_ID').format(waktuBerangkat!.toDate()) : '-';


  factory JadwalPerhentianModel.fromMap(Map<String, dynamic> map, String stasiunNamaDefault) {
    return JadwalPerhentianModel(
      idStasiun: map['id_stasiun'] ?? '',
      namaStasiun: map['nama_stasiun'] ?? stasiunNamaDefault, // Fallback jika nama tidak disimpan
      waktuTiba: map['waktu_tiba'] as Timestamp?,
      waktuBerangkat: map['waktu_berangkat'] as Timestamp?,
      urutan: map['urutan'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_stasiun': idStasiun,
      'nama_stasiun': namaStasiun, // Simpan juga nama stasiun untuk kemudahan
      'waktu_tiba': waktuTiba,
      'waktu_berangkat': waktuBerangkat,
      'urutan': urutan,
    };
  }
}
