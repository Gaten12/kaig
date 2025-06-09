import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/keranjang_model.dart';

class KeranjangService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<KeranjangModel> _getKeranjangCollection(String userId) {
    return _db.collection('users').doc(userId).collection('keranjang').withConverter<KeranjangModel>(
      fromFirestore: (snapshot, _) => KeranjangModel.fromFirestore(snapshot),
      toFirestore: (model, _) => model.toFirestore(),
    );
  }

  Stream<List<KeranjangModel>> getKeranjangStream(String userId) {
    return _getKeranjangCollection(userId)
        .orderBy('waktuDitambahkan', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> tambahKeKeranjang(KeranjangModel item) async {
    await _getKeranjangCollection(item.userId).add(item);
  }

  Future<void> hapusDariKeranjang(String userId, String itemId) async {
    await _getKeranjangCollection(userId).doc(itemId).delete();
  }

  Future<void> hapusBeberapaDariKeranjang(String userId, List<String> itemIds) async {
    final WriteBatch batch = _db.batch();
    final collection = _getKeranjangCollection(userId);
    for (final id in itemIds) {
      batch.delete(collection.doc(id));
    }
    await batch.commit();
  }
}