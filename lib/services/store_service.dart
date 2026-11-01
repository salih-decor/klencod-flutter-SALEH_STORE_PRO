import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreService {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Stream<DocumentSnapshot<Map<String, dynamic>>> myProfile() => db.collection('users').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> products() => db.collection('products').where('active', isEqualTo: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> orders() => db.collection('orders').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> transporters() => db.collection('transporters').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> sales() => db.collection('sales').orderBy('createdAt', descending: true).snapshots();

  Future<void> createSale(Map<String, int> quantities, List<QueryDocumentSnapshot<Map<String, dynamic>>> products) async {
    if (quantities.isEmpty) return;
    final selected = products.where((p) => (quantities[p.id] ?? 0) > 0).toList();
    if (selected.length != quantities.length) throw StateError('المنتجات تغيرت، يرجى تحديث السلة');
    final items = selected.map((p) => {'productId': p.id, 'name': p.data()['name'], 'quantity': quantities[p.id], 'unitPrice': p.data()['price']}).toList();
    final total = items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int) * (item['unitPrice'] as int));
    await db.collection('sales').add({'items': items, 'total': total, 'received': total, 'paymentMethod': 'cash', 'createdBy': uid, 'createdAt': FieldValue.serverTimestamp(), 'status': 'completed'});
  }

  Future<void> addProduct(String name, int price, String category) async {
    await db.collection('products').add({'name': name, 'price': price, 'category': category, 'active': true, 'imageUrl': '', 'createdAt': FieldValue.serverTimestamp()});
  }
  Future<void> addOrder(Map<String, dynamic> data) async {
    await db.collection('orders').add({...data, 'createdBy': uid, 'createdAt': FieldValue.serverTimestamp(), 'status': 'pending'});
  }
  Future<void> addTransporter(String name, String phone) async {
    await db.collection('transporters').add({'name': name, 'phone': phone, 'createdAt': FieldValue.serverTimestamp()});
  }
}
