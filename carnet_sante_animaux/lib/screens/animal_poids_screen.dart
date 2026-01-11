import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../services/firebase_animal_service.dart';

class AnimalPoidsScreen extends StatefulWidget {
  final Animal animal;

  const AnimalPoidsScreen({super.key, required this.animal});

  @override
  State<AnimalPoidsScreen> createState() => _AnimalPoidsScreenState();
}

class _AnimalPoidsScreenState extends State<AnimalPoidsScreen> {
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

  Future<void> _ajouterMesure() async {
    final result = await _showMesureDialog();
    if (result != null) {
      final updatedAnimal = _animal.copyWith(
        historiquePoids: [..._animal.historiquePoids, result],
      );
      await _animalService.saveAnimal(updatedAnimal);
      await _loadAnimal();
    }
  }

  Future<void> _modifierMesure(MesurePoids mesure) async {
    final result = await _showMesureDialog(mesure: mesure);
    if (result != null) {
      final mesures = _animal.historiquePoids.map((m) {
        return m.id == result.id ? result : m;
      }).toList();

      final updatedAnimal = _animal.copyWith(historiquePoids: mesures);
      await _animalService.saveAnimal(updatedAnimal);
      await _loadAnimal();
    }
  }

  Future<void> _supprimerMesure(MesurePoids mesure) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la mesure du ${DateFormat('dd/MM/yyyy').format(mesure.date)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final mesures = _animal.historiquePoids.where((m) => m.id != mesure.id).toList();
      final updatedAnimal = _animal.copyWith(historiquePoids: mesures);
      await _animalService.saveAnimal(updatedAnimal);
      await _loadAnimal();
    }
  }

  Future<MesurePoids?> _showMesureDialog({MesurePoids? mesure}) async {
    final formKey = GlobalKey<FormState>();
    DateTime date = mesure?.date ?? DateTime.now();
    double? poids = mesure?.poids;
    String notes = mesure?.notes ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(mesure == null ? 'Ajouter une mesure' : 'Modifier la mesure'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Date de la mesure'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: _animal.dateNaissance,
                        lastDate: DateTime.now(),
                      );
                      if (newDate != null) {
                        setDialogState(() => date = newDate);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: poids?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Nombre invalide';
                      }
                      return null;
                    },
                    onSaved: (value) => poids = double.parse(value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes - optionnelles',
                      border: OutlineInputBorder(),
                    ),
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
              child: Text(mesure == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      return MesurePoids(
        id: mesure?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        poids: poids!,
        notes: notes.isEmpty ? null : notes,
      );
    }
    return null;
  }

  String _getEvolutionPoids() {
    if (_animal.historiquePoids.length < 2) return '';

    final mesures = List<MesurePoids>.from(_animal.historiquePoids)
      ..sort((a, b) => a.date.compareTo(b.date));

    final derniere = mesures.last;
    final avantDerniere = mesures[mesures.length - 2];

    final difference = derniere.poids - avantDerniere.poids;
    if (difference > 0) {
      return '+${difference.toStringAsFixed(1)} kg';
    } else if (difference < 0) {
      return '${difference.toStringAsFixed(1)} kg';
    }
    return 'Stable';
  }

  Color _getEvolutionColor() {
    if (_animal.historiquePoids.length < 2) return Colors.grey;

    final mesures = List<MesurePoids>.from(_animal.historiquePoids)
      ..sort((a, b) => a.date.compareTo(b.date));

    final derniere = mesures.last;
    final avantDerniere = mesures[mesures.length - 2];

    final difference = derniere.poids - avantDerniere.poids;
    if (difference > 0) {
      return Colors.green;
    } else if (difference < 0) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final mesures = _animal.historiquePoids.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Poids - ${_animal.nom}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // En-tête avec photo et infos de l'animal
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
                              '${_animal.espece} - ${_animal.ageEnMois} mois',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_animal.dernierPoids != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Dernier poids: ${_animal.dernierPoids!.poids} kg',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.teal[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_animal.historiquePoids.length >= 2) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getEvolutionColor().withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getEvolutionPoids(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getEvolutionColor(),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Liste des mesures
                Expanded(
                  child: mesures.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monitor_weight,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune mesure de poids',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Commencez à suivre le poids de ${_animal.nom}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: mesures.length,
                          itemBuilder: (context, index) {
                            final mesure = mesures[index];
                            final isRecent = index == 0;

                            // Calculer l'évolution par rapport à la mesure précédente
                            String? evolution;
                            Color? evolutionColor;
                            if (index < mesures.length - 1) {
                              final mesurePrecedente = mesures[index + 1];
                              final diff = mesure.poids - mesurePrecedente.poids;
                              if (diff > 0) {
                                evolution = '+${diff.toStringAsFixed(1)} kg';
                                evolutionColor = Colors.green;
                              } else if (diff < 0) {
                                evolution = '${diff.toStringAsFixed(1)} kg';
                                evolutionColor = Colors.orange;
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              elevation: isRecent ? 3 : 1,
                              child: ListTile(
                                leading: Icon(
                                  Icons.monitor_weight,
                                  color: isRecent ? Colors.teal[700] : Colors.grey,
                                  size: 32,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      '${mesure.poids} kg',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isRecent ? 18 : 16,
                                      ),
                                    ),
                                    if (evolution != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: evolutionColor?.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          evolution,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: evolutionColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(mesure.date),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (mesure.notes != null && mesure.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        mesure.notes!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'modifier',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Modifier'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'supprimer',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'modifier') {
                                      _modifierMesure(mesure);
                                    } else if (value == 'supprimer') {
                                      _supprimerMesure(mesure);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterMesure,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
