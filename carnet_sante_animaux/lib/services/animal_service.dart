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
}
