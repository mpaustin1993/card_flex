import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a card to user's collection
  Future<void> addCardToCollection(Map<String, dynamic> cardData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final cardId = cardData['id'] as String;

    // Reference to user's cards collection
    final cardRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(cardId);

    // Check if card already exists
    final doc = await cardRef.get();
    
    if (doc.exists) {
      // Increment quantity if card already exists
      await cardRef.update({
        'quantity': FieldValue.increment(1),
        'lastAdded': FieldValue.serverTimestamp(),
      });
    } else {
      // Add new card
      await cardRef.set({
        'cardId': cardId,
        'name': cardData['name'],
        'imageUrl': cardData['images']?['small'],
        'imageUrlLarge': cardData['images']?['large'],
        'set': cardData['set']?['name'],
        'setId': cardData['set']?['id'],
        'rarity': cardData['rarity'],
        'types': cardData['types'],
        'hp': cardData['hp'],
        'supertype': cardData['supertype'],
        'subtypes': cardData['subtypes'],
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
        'lastAdded': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get user's card collection
  Stream<QuerySnapshot> getUserCards() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cards')
        .orderBy('lastAdded', descending: true)
        .snapshots();
  }

  /// Get specific card details
  Future<DocumentSnapshot> getCard(String cardId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(cardId)
        .get();
  }

  /// Remove card from collection
  Future<void> removeCard(String cardId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(cardId)
        .delete();
  }

  /// Update card quantity
  Future<void> updateCardQuantity(String cardId, int quantity) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    if (quantity <= 0) {
      return removeCard(cardId);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(cardId)
        .update({'quantity': quantity});
  }

  /// Get total card count
  Future<int> getTotalCardCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cards')
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['quantity'] as int?) ?? 1;
    }

    return total;
  }
}
