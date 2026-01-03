import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal.dart';

class AnimalService {
  static const String _storageKey = 'animaux';

  Future<List<Animal>> getAnimaux() async {
    final prefs = await SharedPreferences.getInstance();
    final String? animauxJson = prefs.getString(_storageKey);

    if (animauxJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(animauxJson);
    return decoded.map((json) => Animal.fromJson(json)).toList();
  }

  Future<Animal?> getAnimal(String id) async {
    final animaux = await getAnimaux();
    try {
      return animaux.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveAnimal(Animal animal) async {
    final animaux = await getAnimaux();
    final index = animaux.indexWhere((a) => a.id == animal.id);

    if (index != -1) {
      animaux[index] = animal;
    } else {
      animaux.add(animal);
    }

    await _saveAnimaux(animaux);
  }

  Future<void> deleteAnimal(String id) async {
    final animaux = await getAnimaux();
    animaux.removeWhere((a) => a.id == id);
    await _saveAnimaux(animaux);
  }

  Future<void> _saveAnimaux(List<Animal> animaux) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(animaux.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<List<Animal>> getAnimauxAvecTraitementEnCours() async {
    final animaux = await getAnimaux();
    return animaux.where((a) => a.traitementsEnCours.isNotEmpty).toList();
  }

  Future<List<Animal>> getAnimauxAvecVaccinAVenir() async {
    final animaux = await getAnimaux();
    return animaux.where((a) => a.prochainVaccin != null).toList();
  }

  // Récupère les enfants d'un animal
  Future<List<Animal>> getEnfants(String parentId) async {
    final animaux = await getAnimaux();
    return animaux
        .where((a) => a.pereId == parentId || a.mereId == parentId)
        .toList();
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

  // Récupère tous les animaux qui peuvent être parents (adultes uniquement, optionnel)
  Future<List<Animal>> getParentsPotentiels({String? sexe}) async {
    final animaux = await getAnimaux();
    return animaux.where((a) {
      if (sexe != null && a.sexe != sexe) return false;
      return true;
    }).toList();
  }
}
