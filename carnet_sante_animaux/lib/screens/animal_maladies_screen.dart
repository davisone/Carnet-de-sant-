import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../services/firebase_animal_service.dart';

class AnimalMaladiesScreen extends StatefulWidget {
  final Animal animal;

  const AnimalMaladiesScreen({super.key, required this.animal});

  @override
  State<AnimalMaladiesScreen> createState() => _AnimalMaladiesScreenState();
}

class _AnimalMaladiesScreenState extends State<AnimalMaladiesScreen> {
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

  Future<void> _ajouterMaladie() async {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    String description = '';
    DateTime dateDiagnostic = DateTime.now();
    bool estChronique = false;
    bool estGuerite = false;
    DateTime? dateGuerison;
    String traitement = '';
    String notes = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter une maladie'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nom de la maladie'),
                    validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                    onSaved: (value) => nom = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    onSaved: (value) => description = value ?? '',
                  ),
                  ListTile(
                    title: const Text('Date de diagnostic'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(dateDiagnostic)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dateDiagnostic,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => dateDiagnostic = date);
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Maladie chronique'),
                    value: estChronique,
                    onChanged: (value) {
                      setState(() => estChronique = value ?? false);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Animal guéri'),
                    value: estGuerite,
                    onChanged: (value) {
                      setState(() => estGuerite = value ?? false);
                    },
                  ),
                  if (estGuerite)
                    ListTile(
                      title: const Text('Date de guérison'),
                      subtitle: Text(dateGuerison != null
                          ? DateFormat('dd/MM/yyyy').format(dateGuerison!)
                          : 'Non définie'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: dateGuerison ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => dateGuerison = date);
                        }
                      },
                    ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Traitement (optionnel)'),
                    maxLines: 2,
                    onSaved: (value) => traitement = value ?? '',
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
      ),
    );

    if (result == true) {
      final newMaladie = Maladie(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: nom,
        dateDiagnostic: dateDiagnostic,
        description: description.isEmpty ? null : description,
        estChronique: estChronique,
        estGuerite: estGuerite,
        dateGuerison: dateGuerison,
        traitement: traitement.isEmpty ? null : traitement,
        notes: notes.isEmpty ? null : notes,
      );

      final updatedAnimal = _animal.copyWith(
        maladies: [..._animal.maladies, newMaladie],
      );

      await _animalService.saveAnimal(updatedAnimal);
      await _loadAnimal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maladies = _animal.maladies;
    maladies.sort((a, b) => b.dateDiagnostic.compareTo(a.dateDiagnostic));

    return Scaffold(
      appBar: AppBar(
        title: Text('Maladies - ${_animal.nom}'),
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
                // Liste des maladies
                Expanded(
                  child: maladies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.health_and_safety,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune maladie enregistrée',
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
                          itemCount: maladies.length,
                          itemBuilder: (context, index) {
                            final maladie = maladies[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          maladie.estGuerite
                                              ? Icons.check_circle
                                              : maladie.estChronique
                                                  ? Icons.update
                                                  : Icons.health_and_safety,
                                          color: maladie.estGuerite
                                              ? Colors.green[700]
                                              : maladie.estChronique
                                                  ? Colors.orange[700]
                                                  : Colors.red[700],
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      maladie.nom,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (maladie.estChronique)
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
                                                        'Chronique',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.orange[900],
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  if (maladie.estGuerite)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green[100],
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        'Guéri',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.green[900],
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (maladie.description != null)
                                      Text(
                                        maladie.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Diagnostic: ${DateFormat('dd/MM/yyyy').format(maladie.dateDiagnostic)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (maladie.dateGuerison != null)
                                      Text(
                                        'Guérison: ${DateFormat('dd/MM/yyyy').format(maladie.dateGuerison!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    if (maladie.traitement != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Traitement: ${maladie.traitement}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterMaladie,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
