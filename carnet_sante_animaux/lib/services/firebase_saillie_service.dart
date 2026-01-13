import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal.dart';

class FirebaseSaillieService {
  final CollectionReference _sailliesCollection =
      FirebaseFirestore.instance.collection('saillies');

  // Récupérer toutes les saillies
  Future<List<Saillie>> getSaillies() async {
    try {
      final snapshot = await _sailliesCollection.get();
      return snapshot.docs
          .map((doc) => Saillie.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des saillies: $e');
      return [];
    }
  }

  // Récupérer une saillie par ID
  Future<Saillie?> getSaillie(String id) async {
    try {
      final doc = await _sailliesCollection.doc(id).get();
      if (doc.exists) {
        return Saillie.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la saillie: $e');
      return null;
    }
  }

  // Sauvegarder une saillie
  Future<void> saveSaillie(Saillie saillie) async {
    try {
      await _sailliesCollection.doc(saillie.id).set(saillie.toJson());
    } catch (e) {
      print('Erreur lors de la sauvegarde de la saillie: $e');
      rethrow;
    }
  }

  // Supprimer une saillie
  Future<void> deleteSaillie(String id) async {
    try {
      await _sailliesCollection.doc(id).delete();
    } catch (e) {
      print('Erreur lors de la suppression de la saillie: $e');
      rethrow;
    }
  }

  // Récupérer les saillies d'une mère spécifique
  Future<List<Saillie>> getSailliesByMere(String mereId) async {
    try {
      final snapshot = await _sailliesCollection
          .where('mereId', isEqualTo: mereId)
          .get();
      return snapshot.docs
          .map((doc) => Saillie.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des saillies de la mère: $e');
      return [];
    }
  }

  // Récupérer les saillies d'un père spécifique
  Future<List<Saillie>> getSailliesByPere(String pereId) async {
    try {
      final snapshot = await _sailliesCollection
          .where('pereId', isEqualTo: pereId)
          .get();
      return snapshot.docs
          .map((doc) => Saillie.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des saillies du père: $e');
      return [];
    }
  }

  // Récupérer les saillies par année
  Future<List<Saillie>> getSailliesByYear(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final snapshot = await _sailliesCollection
          .where('dateSaillie', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('dateSaillie', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => Saillie.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des saillies par année: $e');
      return [];
    }
  }
}
