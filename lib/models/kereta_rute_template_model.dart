import 'package:flutter/material.dart'; // Diperlukan untuk TimeOfDay

class KeretaRuteTemplateModel {
  String stasiunId;  // ID atau Kode Stasiun, e.g., "GMR"
  String namaStasiun; // Nama untuk display, e.g., "GAMBIR"
  TimeOfDay? jamTiba;    // Format jam tiba (HH:mm), bisa null untuk stasiun awal
  TimeOfDay? jamBerangkat; // Format jam berangkat (HH:mm), bisa null untuk stasiun akhir
  int urutan;

  KeretaRuteTemplateModel({
    required this.stasiunId,
    required this.namaStasiun,
    this.jamTiba,
    this.jamBerangkat,
    required this.urutan,
  });

  // Konversi dari Map (saat dibaca dari Firestore)
  factory KeretaRuteTemplateModel.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeString) {
      if (timeString == null) return null;
      try {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        return null;
      }
    }
    return KeretaRuteTemplateModel(
      stasiunId: map['stasiunId'] ?? '',
      namaStasiun: map['namaStasiun'] ?? '',
      jamTiba: parseTime(map['jamTiba']),
      jamBerangkat: parseTime(map['jamBerangkat']),
      urutan: map['urutan'] ?? 0,
    );
  }

  // Konversi ke Map (saat disimpan ke Firestore)
  Map<String, dynamic> toMap() {
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return {
      'stasiunId': stasiunId,
      'namaStasiun': namaStasiun,
      'jamTiba': formatTime(jamTiba),
      'jamBerangkat': formatTime(jamBerangkat),
      'urutan': urutan,
    };
  }
}