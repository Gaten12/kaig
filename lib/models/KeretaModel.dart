import 'package:cloud_firestore/cloud_firestore.dart';
import 'kereta_rute_template_model.dart';

class KeretaModel {
  final String id;
  final String nama;
  final List<String> idRangkaianGerbong;
  final List<KeretaRuteTemplateModel> templateRute;
  final int totalKursi;

  KeretaModel({
    required this.id,
    required this.nama,
    this.idRangkaianGerbong = const [],
    this.templateRute = const [],
    this.totalKursi = 0,
  });

  factory KeretaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("Data kereta null");

    List<KeretaRuteTemplateModel> rute = [];
    if (data['templateRute'] != null && data['templateRute'] is List) {
      rute = (data['templateRute'] as List)
          .map((item) => KeretaRuteTemplateModel.fromMap(item as Map<String, dynamic>))
          .toList();
      rute.sort((a,b) => a.urutan.compareTo(b.urutan));
    }

    return KeretaModel(
      id: snapshot.id,
      nama: data['nama'] ?? '',
      idRangkaianGerbong: List<String>.from(data['idRangkaianGerbong'] ?? []),
      templateRute: rute,
      totalKursi: data['totalKursi'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'idRangkaianGerbong': idRangkaianGerbong,
      'templateRute': templateRute.map((item) => item.toMap()).toList(),
      'totalKursi': totalKursi,
    };
  }
}