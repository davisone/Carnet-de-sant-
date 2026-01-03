import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/animal.dart';
import '../services/firebase_animal_service.dart';

class AddAnimalScreen extends StatefulWidget {
  final Animal? animal;

  const AddAnimalScreen({super.key, this.animal});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAnimalService _animalService = FirebaseAnimalService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nomController;
  late TextEditingController _especeController;
  late TextEditingController _raceController;
  late TextEditingController _couleurController;
  late TextEditingController _numeroIdController;
  late TextEditingController _notesController;

  DateTime? _dateNaissance;
  String? _sexe;
  String? _photoPath;
  String? _pereId;
  String? _mereId;
  List<Animal> _animaux = [];

  final List<String> _especesSuggestions = [
    'Chien',
    'Chat',
    'Lapin',
    'Oiseau',
    'Hamster',
    'Cochon d\'Inde',
    'Cheval',
    'Tortue',
  ];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.animal?.nom ?? '');
    _especeController =
        TextEditingController(text: widget.animal?.espece ?? '');
    _raceController = TextEditingController(text: widget.animal?.race ?? '');
    _couleurController =
        TextEditingController(text: widget.animal?.couleur ?? '');
    _numeroIdController =
        TextEditingController(text: widget.animal?.numeroIdentification ?? '');
    _notesController = TextEditingController(text: widget.animal?.notes ?? '');
    _dateNaissance = widget.animal?.dateNaissance;
    _sexe = widget.animal?.sexe;
    _photoPath = widget.animal?.photoPath;
    _pereId = widget.animal?.pereId;
    _mereId = widget.animal?.mereId;
    _loadAnimaux();
  }

  Future<void> _loadAnimaux() async {
    final animaux = await _animalService.getAnimaux();
    setState(() {
      _animaux = animaux;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _especeController.dispose();
    _raceController.dispose();
    _couleurController.dispose();
    _numeroIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animal == null
            ? 'Ajouter un animal'
            : 'Modifier ${widget.animal!.nom}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: _photoPath != null
                          ? FileImage(File(_photoPath!))
                          : null,
                      child: _photoPath == null
                          ? Icon(
                              Icons.pets,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _especesSuggestions;
                }
                return _especesSuggestions.where((String option) {
                  return option
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _especeController.text = selection;
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted) {
                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Espèce',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  onChanged: (value) {
                    _especeController.text = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une espèce';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _raceController,
              decoration: const InputDecoration(
                labelText: 'Race',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une race';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateNaissance ?? DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _dateNaissance = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateNaissance != null
                      ? '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}'
                      : 'Sélectionner une date',
                  style: TextStyle(
                    color: _dateNaissance != null ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sexe,
              decoration: const InputDecoration(
                labelText: 'Sexe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'Mâle', child: Text('Mâle')),
                DropdownMenuItem(value: 'Femelle', child: Text('Femelle')),
              ],
              onChanged: (value) {
                setState(() => _sexe = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _pereId,
              decoration: const InputDecoration(
                labelText: 'Père',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.male),
                hintText: 'Sélectionner le père (optionnel)',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Aucun'),
                ),
                ..._animaux
                    .where((a) =>
                        a.sexe == 'Mâle' &&
                        a.id != widget.animal?.id)
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.nom} (${a.race})'),
                        )),
              ],
              onChanged: (value) {
                setState(() => _pereId = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mereId,
              decoration: const InputDecoration(
                labelText: 'Mère',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.female),
                hintText: 'Sélectionner la mère (optionnel)',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Aucun'),
                ),
                ..._animaux
                    .where((a) =>
                        a.sexe == 'Femelle' &&
                        a.id != widget.animal?.id)
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.nom} (${a.race})'),
                        )),
              ],
              onChanged: (value) {
                setState(() => _mereId = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _couleurController,
              decoration: const InputDecoration(
                labelText: 'Couleur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroIdController,
              decoration: const InputDecoration(
                labelText: 'Numéro d\'identification (puce/tatouage)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fingerprint),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAnimal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAnimal() async {
    if (_formKey.currentState!.validate()) {
      if (_dateNaissance == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une date de naissance'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final animal = Animal(
        id: widget.animal?.id ?? const Uuid().v4(),
        nom: _nomController.text,
        espece: _especeController.text,
        race: _raceController.text,
        dateNaissance: _dateNaissance!,
        sexe: _sexe,
        couleur: _couleurController.text.isEmpty
            ? null
            : _couleurController.text,
        numeroIdentification: _numeroIdController.text.isEmpty
            ? null
            : _numeroIdController.text,
        photoPath: _photoPath,
        pereId: _pereId,
        mereId: _mereId,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        traitements: widget.animal?.traitements ?? [],
        vaccins: widget.animal?.vaccins ?? [],
        consultations: widget.animal?.consultations ?? [],
      );

      await _animalService.saveAnimal(animal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.animal == null
                ? 'Animal ajouté avec succès'
                : 'Animal modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }
}
