import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/animal.dart';

class FirebaseAnimalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'animaux';

  // Récupère tous les animaux
  Future<List<Animal>> getAnimaux() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs
          .map((doc) => Animal.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des animaux: $e');
      return [];
    }
  }

  // Stream pour écouter les changements en temps réel
  Stream<List<Animal>> getAnimauxStream() {
    return _firestore.collection(_collection).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Animal.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Récupère un animal par son ID
  Future<Animal?> getAnimal(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Animal.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'animal: $e');
      return null;
    }
  }

  // Sauvegarde un animal (création ou mise à jour)
  Future<void> saveAnimal(Animal animal) async {
    try {
      final data = animal.toJson();
      data.remove('id'); // On ne sauvegarde pas l'ID dans les données

      await _firestore.collection(_collection).doc(animal.id).set(data);
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'animal: $e');
      rethrow;
    }
  }

  // Supprime un animal
  Future<void> deleteAnimal(String id) async {
    try {
      // Supprimer aussi la photo si elle existe
      final animal = await getAnimal(id);
      if (animal?.photoPath != null && animal!.photoPath!.startsWith('gs://')) {
        try {
          await _storage.refFromURL(animal.photoPath!).delete();
        } catch (e) {
          print('Erreur lors de la suppression de la photo: $e');
        }
      }

      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Erreur lors de la suppression de l\'animal: $e');
      rethrow;
    }
  }

  // Upload une photo vers Firebase Storage
  Future<String?> uploadPhoto(String animalId, String localPath) async {
    try {
      final file = File(localPath);
      final ref = _storage.ref().child('animaux/$animalId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Erreur lors de l\'upload de la photo: $e');
      return null;
    }
  }

  // Récupère les animaux avec traitements en cours
  Future<List<Animal>> getAnimauxAvecTraitementEnCours() async {
    final animaux = await getAnimaux();
    return animaux.where((a) => a.traitementsEnCours.isNotEmpty).toList();
  }

  // Récupère les animaux avec vaccins à venir
  Future<List<Animal>> getAnimauxAvecVaccinAVenir() async {
    final animaux = await getAnimaux();
    return animaux.where((a) => a.prochainVaccin != null).toList();
  }

  // Récupère les enfants d'un animal
  Future<List<Animal>> getEnfants(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where(Filter.or(
            Filter('pereId', isEqualTo: parentId),
            Filter('mereId', isEqualTo: parentId),
          ))
          .get();

      return querySnapshot.docs
          .map((doc) => Animal.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des enfants: $e');
      return [];
    }
  }

  // Récupère le père d'un animal
  Future<Animal?> getPere(String animalId) async {
    final animal = await getAnimal(animalId);
    if (animal?.pereId == null) return null;
    return await getAnimal(animal!.pereId!);
  }

  // Récupère la mère d'un animal
  Future<Animal?> getMere(String animalId) async {
    final animal = await getAnimal(animalId);
    if (animal?.mereId == null) return null;
    return await getAnimal(animal!.mereId!);
  }

  // Récupère les parents d'un animal
  Future<Map<String, Animal?>> getParents(String animalId) async {
    final animal = await getAnimal(animalId);
    if (animal == null) return {'pere': null, 'mere': null};

    Animal? pere;
    Animal? mere;

    if (animal.pereId != null) {
      pere = await getAnimal(animal.pereId!);
    }
    if (animal.mereId != null) {
      mere = await getAnimal(animal.mereId!);
    }

    return {'pere': pere, 'mere': mere};
  }

  // Récupère tous les animaux qui peuvent être parents
  Future<List<Animal>> getParentsPotentiels({String? sexe}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (sexe != null) {
        query = query.where('sexe', isEqualTo: sexe);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Animal.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des parents potentiels: $e');
      return [];
    }
  }
}
