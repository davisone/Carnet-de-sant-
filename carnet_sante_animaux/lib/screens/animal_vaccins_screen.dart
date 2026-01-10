import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../services/firebase_animal_service.dart';

class AnimalVaccinsScreen extends StatefulWidget {
  final Animal animal;

  const AnimalVaccinsScreen({super.key, required this.animal});

  @override
  State<AnimalVaccinsScreen> createState() => _AnimalVaccinsScreenState();
}

class _AnimalVaccinsScreenState extends State<AnimalVaccinsScreen> {
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

  Future<void> _ajouterVaccin() async {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    DateTime dateAdministration = DateTime.now();
    DateTime? dateRappel;
    String numeroLot = '';
    String veterinaire = '';
    String notes = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un vaccin'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nom du vaccin'),
                    validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                    onSaved: (value) => nom = value!,
                  ),
                  ListTile(
                    title: const Text('Date d\'administration'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(dateAdministration)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dateAdministration,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => dateAdministration = date);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Date de rappel (optionnelle)'),
                    subtitle: Text(dateRappel != null ? DateFormat('dd/MM/yyyy').format(dateRappel!) : 'Non définie'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dateRappel ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => dateRappel = date);
                      }
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Numéro de lot (optionnel)'),
                    onSaved: (value) => numeroLot = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Vétérinaire (optionnel)'),
                    onSaved: (value) => veterinaire = value ?? '',
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
      final newVaccin = Vaccin(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: nom,
        dateAdministration: dateAdministration,
        dateRappel: dateRappel,
        numeroLot: numeroLot.isEmpty ? null : numeroLot,
        veterinaire: veterinaire.isEmpty ? null : veterinaire,
        notes: notes.isEmpty ? null : notes,
      );

      final updatedAnimal = _animal.copyWith(
        vaccins: [..._animal.vaccins, newVaccin],
      );

      await _animalService.saveAnimal(updatedAnimal);
      await _loadAnimal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaccins = _animal.vaccins;
    vaccins.sort((a, b) => b.dateAdministration.compareTo(a.dateAdministration));

    return Scaffold(
      appBar: AppBar(
        title: Text('Vaccins - ${_animal.nom}'),
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
                // Liste des vaccins
                Expanded(
                  child: vaccins.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.vaccines,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun vaccin enregistré',
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
                          itemCount: vaccins.length,
                          itemBuilder: (context, index) {
                            final vaccin = vaccins[index];
                            final aRappel = vaccin.dateRappel != null;
                            final rappelProche = aRappel &&
                                vaccin.dateRappel!.difference(DateTime.now()).inDays <= 30;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.vaccines,
                                  color: rappelProche ? Colors.orange[700] : Colors.blue[700],
                                  size: 32,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vaccin.nom,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (rappelProche)
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
                                          'Rappel proche',
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
                                    Text(
                                      'Administré le ${DateFormat('dd/MM/yyyy').format(vaccin.dateAdministration)}',
                                    ),
                                    if (aRappel)
                                      Text(
                                        'Rappel le ${DateFormat('dd/MM/yyyy').format(vaccin.dateRappel!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: rappelProche ? Colors.orange[700] : Colors.blue[700],
                                        ),
                                      ),
                                    if (vaccin.veterinaire != null)
                                      Text(
                                        'Par ${vaccin.veterinaire}',
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
        onPressed: _ajouterVaccin,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
