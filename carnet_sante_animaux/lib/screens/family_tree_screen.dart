import 'dart:io';
import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../services/firebase_animal_service.dart';
import 'animal_detail_screen.dart';

class FamilyTreeScreen extends StatefulWidget {
  final Animal? initialAnimal;

  const FamilyTreeScreen({super.key, this.initialAnimal});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final FirebaseAnimalService _animalService = FirebaseAnimalService();
  Animal? _selectedAnimal;
  Animal? _pere;
  Animal? _mere;
  List<Animal> _enfants = [];
  List<Animal> _animaux = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _animaux = await _animalService.getAnimaux();

    if (widget.initialAnimal != null) {
      // Trouver l'animal correspondant dans la liste pour éviter les problèmes de référence
      _selectedAnimal = _animaux.firstWhere(
        (a) => a.id == widget.initialAnimal!.id,
        orElse: () => widget.initialAnimal!,
      );
    } else if (_animaux.isNotEmpty) {
      _selectedAnimal = _animaux.first;
    }

    await _loadFamilyData();

    setState(() => _isLoading = false);
  }

  Future<void> _loadFamilyData() async {
    if (_selectedAnimal == null) return;

    final parents = await _animalService.getParents(_selectedAnimal!.id);
    _pere = parents['pere'];
    _mere = parents['mere'];
    _enfants = await _animalService.getEnfants(_selectedAnimal!.id);

    setState(() {});
  }

  Future<void> _selectAnimal(Animal animal) async {
    // Trouver l'animal correspondant dans la liste pour éviter les problèmes de référence
    final animalFromList = _animaux.firstWhere(
      (a) => a.id == animal.id,
      orElse: () => animal,
    );

    setState(() {
      _selectedAnimal = animalFromList;
      _isLoading = true;
    });
    await _loadFamilyData();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arbre Généalogique'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _animaux.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun animal enregistré',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Row(
                        children: [
                          const Icon(Icons.pets),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<Animal>(
                              value: _selectedAnimal,
                              decoration: const InputDecoration(
                                labelText: 'Sélectionner un animal',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _animaux
                                  .map((a) => DropdownMenuItem(
                                        value: a,
                                        child: Text('${a.nom} (${a.espece})'),
                                      ))
                                  .toList(),
                              onChanged: (animal) {
                                if (animal != null) _selectAnimal(animal);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _selectedAnimal == null
                            ? const Center(
                                child: Text('Sélectionnez un animal'))
                            : Column(
                                children: [
                                  // Parents
                                  if (_pere != null || _mere != null) ...[
                                    const Text(
                                      'Parents',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (_pere != null)
                                          Expanded(
                                            child: _buildAnimalCard(
                                              _pere!,
                                              'Père',
                                              Icons.male,
                                              Colors.blue,
                                            ),
                                          ),
                                        if (_pere != null && _mere != null)
                                          const SizedBox(width: 12),
                                        if (_mere != null)
                                          Expanded(
                                            child: _buildAnimalCard(
                                              _mere!,
                                              'Mère',
                                              Icons.female,
                                              Colors.pink,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    const Icon(Icons.arrow_downward, size: 32),
                                    const SizedBox(height: 24),
                                  ],
                                  // Animal sélectionné
                                  const Text(
                                    'Animal',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAnimalCard(
                                    _selectedAnimal!,
                                    '',
                                    Icons.pets,
                                    Theme.of(context).colorScheme.primary,
                                    isMain: true,
                                  ),
                                  // Enfants
                                  if (_enfants.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    const Icon(Icons.arrow_downward, size: 32),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Enfants',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: _enfants
                                          .map((enfant) => SizedBox(
                                                width: (MediaQuery.of(context)
                                                            .size
                                                            .width -
                                                        56) /
                                                    2,
                                                child: _buildAnimalCard(
                                                  enfant,
                                                  'Enfant',
                                                  Icons.child_care,
                                                  Colors.green,
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                  if (_pere == null &&
                                      _mere == null &&
                                      _enfants.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Text(
                                        'Aucune relation familiale enregistrée pour cet animal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAnimalCard(
    Animal animal,
    String label,
    IconData icon,
    Color color, {
    bool isMain = false,
  }) {
    return Card(
      elevation: isMain ? 8 : 4,
      child: InkWell(
        onTap: () async {
          if (isMain) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimalDetailScreen(animal: animal),
              ),
            );
            if (result == true) {
              _loadData();
            }
          } else {
            _selectAnimal(animal);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (label.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              if (label.isNotEmpty) const SizedBox(height: 8),
              CircleAvatar(
                radius: isMain ? 50 : 40,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                backgroundImage:
                    animal.photoPath != null ? FileImage(File(animal.photoPath!)) : null,
                child: animal.photoPath == null
                    ? Icon(
                        Icons.pets,
                        size: isMain ? 50 : 40,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                animal.nom,
                style: TextStyle(
                  fontSize: isMain ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                animal.espece,
                style: TextStyle(
                  fontSize: isMain ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                animal.race,
                style: TextStyle(
                  fontSize: isMain ? 14 : 12,
                  color: Colors.grey[600],
                ),
              ),
              if (animal.sexe != null)
                Text(
                  animal.sexe!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              Text(
                animal.ageComplet,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
