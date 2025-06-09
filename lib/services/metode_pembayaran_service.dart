import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';

class MetodePembayaranService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<MetodePembayaranModel> _getCollection(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('metodePembayaran')
        .withConverter<MetodePembayaranModel>(
      fromFirestore: (snapshot, _) => MetodePembayaranModel.fromFirestore(snapshot),
      toFirestore: (model, _) => model.toFirestore(),
    );
  }

  Stream<List<MetodePembayaranModel>> getMetodePembayaranStream(String userId) {
    return _getCollection(userId).snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> tambahMetodePembayaran(String userId, MetodePembayaranModel metode) async {
    await _getCollection(userId).add(metode);
  }

  Future<void> hapusMetodePembayaran(String userId, String metodeId) async {
    await _getCollection(userId).doc(metodeId).delete();
  }
}
