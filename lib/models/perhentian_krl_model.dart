import 'package:cloud_firestore/cloud_firestore.dart';

class PerhentianKrlModel {
  final String kodeStasiun;
  final String namaStasiun;
  final String? jamDatang; // Format "HH:mm", bisa null untuk stasiun pertama
  final String? jamBerangkat; // Format "HH:mm", bisa null untuk stasiun terakhir
  final int urutan;

  PerhentianKrlModel({
    required this.kodeStasiun,
    required this.namaStasiun,
    this.jamDatang,
    this.jamBerangkat,
    required this.urutan,
  });

  factory PerhentianKrlModel.fromMap(Map<String, dynamic> map) {
    return PerhentianKrlModel(
      kodeStasiun: map['kodeStasiun'] ?? '',
      namaStasiun: map['namaStasiun'] ?? '',
      jamDatang: map['jamDatang'],
      jamBerangkat: map['jamBerangkat'],
      urutan: map['urutan'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kodeStasiun': kodeStasiun,
      'namaStasiun': namaStasiun,
      'jamDatang': jamDatang,
      'jamBerangkat': jamBerangkat,
      'urutan': urutan,
    };
  }
}