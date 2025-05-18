import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> addBook(Book book) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _db.collection('users').doc(uid).collection('books').add(book.toMap());
  }

  static Future<void> updateBook(String id, Book book) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _db.collection('users').doc(uid).collection('books').doc(id).update(book.toMap());
  }

  static Future<void> deleteBook(String id) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _db.collection('users').doc(uid).collection('books').doc(id).delete();
  }

  static Stream<List<BookWithId>> getBooks(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('books')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookWithId(id: doc.id, book: Book.fromMap(doc.data())))
        .toList());
  }
}