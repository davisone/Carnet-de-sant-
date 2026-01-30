import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../services/firebase_animal_service.dart';

class AnimalTraitementsScreen extends StatefulWidget {
  final Animal animal;

  const AnimalTraitementsScreen({super.key, required this.animal});

  @override
  State<AnimalTraitementsScreen> createState() => _AnimalTraitementsScreenState();
}

class _AnimalTraitementsScreenState extends State<AnimalTraitementsScreen> {
  final FirebaseAnimalService _animalService = FirebaseAnimalService();
  late Animal _animal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  Future<void> _loadAnimal() async {
    setState(() => _isLoading = true);
    final animaux = await _animalService.getAnimaux();
    final updatedAnimal = animaux.firstWhere((a) => a.id == _animal.id);
    setState(() {
      _animal = updatedAnimal;
      _isLoading = false;
    });
  }

  Future<void> _ajouterTraitement() async {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    String description = '';
    String posologie = '';
    DateTime dateDebut = DateTime.now();
    DateTime? dateFin;
    String notes = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un vermifuge'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom du vermifuge'),
                  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                  onSaved: (value) => nom = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                  onSaved: (value) => description = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Posologie'),
                  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                  onSaved: (value) => posologie = value!,
                ),
                ListTile(
                  title: const Text('Date de début'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateDebut,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => dateDebut = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Date de fin (optionnelle)'),
                  subtitle: Text(dateFin != null ? DateFormat('dd/MM/yyyy').format(dateFin!) : 'Non définie'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateFin ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => dateFin = date);
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notes (optionnelles)'),
                  maxLines: 3,
                  onSaved: (value) => notes = value ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context, true);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newTraitement = Traitement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: nom,
        description: description,
        posologie: posologie,
        dateDebut: dateDebut,
        dateFin: dateFin,
        notes: notes.isEmpty ? null : notes,
      );

      final updatedAnimal = _animal.copyWith(
        traitements: [..._animal.traitements, newTraitement],
      );

      await _animalService.saveAnimal(updatedAnimal);
      await _loadAnimal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final traitements = _animal.traitements;
    traitements.sort((a, b) => b.dateDebut.compareTo(a.dateDebut));

    return Scaffold(
      appBar: AppBar(
        title: Text('Vermifuges - ${_animal.nom}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // En-tête avec photo de l'animal
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: _animal.photoPath != null
                            ? FileImage(File(_animal.photoPath!))
                            : null,
                        child: _animal.photoPath == null
                            ? Icon(
                                Icons.pets,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _animal.nom,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_animal.espece} - ${_animal.race}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Liste des traitements
                Expanded(
                  child: traitements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medication,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun vermifuge',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: traitements.length,
                          itemBuilder: (context, index) {
                            final traitement = traitements[index];
                            final estEnCours = traitement.estEnCours;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.medication,
                                  color: estEnCours ? Colors.orange[700] : Colors.grey,
                                  size: 32,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        traitement.nom,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (estEnCours)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'En cours',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange[900],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(traitement.posologie),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Du ${DateFormat('dd/MM/yyyy').format(traitement.dateDebut)}'
                                      '${traitement.dateFin != null ? ' au ${DateFormat('dd/MM/yyyy').format(traitement.dateFin!)}' : ' (en cours)'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterTraitement,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
