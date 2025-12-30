import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/animal.dart';
import '../services/animal_service.dart';
import 'add_animal_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnimalService _animalService = AnimalService();
  late Animal _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadAnimal() async {
    final animal = await _animalService.getAnimal(_animal.id);
    if (animal != null) {
      setState(() => _animal = animal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_animal.nom),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAnimalScreen(animal: _animal),
                ),
              );
              if (result == true) {
                _reloadAnimal();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Infos', icon: Icon(Icons.info)),
            Tab(text: 'Traitements', icon: Icon(Icons.medication)),
            Tab(text: 'Vaccins', icon: Icon(Icons.vaccines)),
            Tab(text: 'Consultations', icon: Icon(Icons.medical_services)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildTraitementsTab(),
          _buildVaccinsTab(),
          _buildConsultationsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: _animal.photoPath != null
                        ? FileImage(File(_animal.photoPath!))
                        : null,
                    child: _animal.photoPath == null
                        ? Icon(
                            Icons.pets,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoRow('Nom', _animal.nom),
                _buildInfoRow('Espèce', _animal.espece),
                _buildInfoRow('Race', _animal.race),
                _buildInfoRow(
                  'Date de naissance',
                  DateFormat('dd/MM/yyyy').format(_animal.dateNaissance),
                ),
                _buildInfoRow('Âge', '${_animal.age} an${_animal.age > 1 ? 's' : ''}'),
                if (_animal.sexe != null) _buildInfoRow('Sexe', _animal.sexe!),
                if (_animal.couleur != null)
                  _buildInfoRow('Couleur', _animal.couleur!),
                if (_animal.numeroIdentification != null)
                  _buildInfoRow(
                      'N° identification', _animal.numeroIdentification!),
                if (_animal.notes != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_animal.notes!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitementsTab() {
    return Column(
      children: [
        Expanded(
          child: _animal.traitements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun traitement enregistré',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _animal.traitements.length,
                  itemBuilder: (context, index) {
                    final traitement = _animal.traitements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: traitement.estEnCours
                              ? Colors.orange
                              : Colors.grey,
                          child: Icon(
                            Icons.medication,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(traitement.nom),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(traitement.description),
                            const SizedBox(height: 4),
                            Text(
                              'Posologie: ${traitement.posologie}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Du ${DateFormat('dd/MM/yyyy').format(traitement.dateDebut)}${traitement.dateFin != null ? ' au ${DateFormat('dd/MM/yyyy').format(traitement.dateFin!)}' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: traitement.estEnCours
                            ? const Chip(
                                label: Text('En cours',
                                    style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.orange,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : null,
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _addTraitement(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un traitement'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinsTab() {
    final vaccins = List<Vaccin>.from(_animal.vaccins);
    vaccins.sort((a, b) => b.dateAdministration.compareTo(a.dateAdministration));

    return Column(
      children: [
        Expanded(
          child: vaccins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vaccines, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun vaccin enregistré',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vaccins.length,
                  itemBuilder: (context, index) {
                    final vaccin = vaccins[index];
                    final aRappel = vaccin.dateRappel != null &&
                        vaccin.dateRappel!.isAfter(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              aRappel ? Colors.blue : Colors.green,
                          child: const Icon(
                            Icons.vaccines,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(vaccin.nom),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administré le ${DateFormat('dd/MM/yyyy').format(vaccin.dateAdministration)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (vaccin.dateRappel != null)
                              Text(
                                'Rappel le ${DateFormat('dd/MM/yyyy').format(vaccin.dateRappel!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: aRappel ? Colors.blue : Colors.grey,
                                ),
                              ),
                            if (vaccin.veterinaire != null)
                              Text(
                                'Par: ${vaccin.veterinaire}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _addVaccin(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un vaccin'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationsTab() {
    final consultations = List<ConsultationVeterinaire>.from(_animal.consultations);
    consultations.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        Expanded(
          child: consultations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune consultation enregistrée',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: consultations.length,
                  itemBuilder: (context, index) {
                    final consultation = consultations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(consultation.motif),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(consultation.date)} - ${consultation.veterinaire}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildConsultationInfo(
                                    'Diagnostic', consultation.diagnostic),
                                if (consultation.poids != null)
                                  _buildConsultationInfo(
                                      'Poids', '${consultation.poids} kg'),
                                if (consultation.traitement != null)
                                  _buildConsultationInfo(
                                      'Traitement', consultation.traitement!),
                                if (consultation.notes != null)
                                  _buildConsultationInfo(
                                      'Notes', consultation.notes!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _addConsultation(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une consultation'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  void _addTraitement() {
    showDialog(
      context: context,
      builder: (context) => _TraitementDialog(
        onSave: (traitement) async {
          final updatedAnimal = _animal.copyWith(
            traitements: [..._animal.traitements, traitement],
          );
          await _animalService.saveAnimal(updatedAnimal);
          _reloadAnimal();
        },
      ),
    );
  }

  void _addVaccin() {
    showDialog(
      context: context,
      builder: (context) => _VaccinDialog(
        onSave: (vaccin) async {
          final updatedAnimal = _animal.copyWith(
            vaccins: [..._animal.vaccins, vaccin],
          );
          await _animalService.saveAnimal(updatedAnimal);
          _reloadAnimal();
        },
      ),
    );
  }

  void _addConsultation() {
    showDialog(
      context: context,
      builder: (context) => _ConsultationDialog(
        onSave: (consultation) async {
          final updatedAnimal = _animal.copyWith(
            consultations: [..._animal.consultations, consultation],
          );
          await _animalService.saveAnimal(updatedAnimal);
          _reloadAnimal();
        },
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer ${_animal.nom} ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _animalService.deleteAnimal(_animal.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraitementDialog extends StatefulWidget {
  final Function(Traitement) onSave;

  const _TraitementDialog({required this.onSave});

  @override
  State<_TraitementDialog> createState() => _TraitementDialogState();
}

class _TraitementDialogState extends State<_TraitementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _posologieController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un traitement'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _posologieController,
                decoration: const InputDecoration(labelText: 'Posologie'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dateDebut = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date de début'),
                  child: Text(
                    _dateDebut != null
                        ? DateFormat('dd/MM/yyyy').format(_dateDebut!)
                        : 'Sélectionner',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateDebut ?? DateTime.now(),
                    firstDate: _dateDebut ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dateFin = date);
                },
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Date de fin (optionnel)'),
                  child: Text(
                    _dateFin != null
                        ? DateFormat('dd/MM/yyyy').format(_dateFin!)
                        : 'Sélectionner',
                  ),
                ),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _dateDebut != null) {
              widget.onSave(Traitement(
                id: const Uuid().v4(),
                nom: _nomController.text,
                description: _descriptionController.text,
                posologie: _posologieController.text,
                dateDebut: _dateDebut!,
                dateFin: _dateFin,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _VaccinDialog extends StatefulWidget {
  final Function(Vaccin) onSave;

  const _VaccinDialog({required this.onSave});

  @override
  State<_VaccinDialog> createState() => _VaccinDialogState();
}

class _VaccinDialogState extends State<_VaccinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _numeroLotController = TextEditingController();
  final _veterinaireController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dateAdministration;
  DateTime? _dateRappel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un vaccin'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom du vaccin'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateAdministration = date);
                  }
                },
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Date d\'administration'),
                  child: Text(
                    _dateAdministration != null
                        ? DateFormat('dd/MM/yyyy').format(_dateAdministration!)
                        : 'Sélectionner',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateAdministration != null
                        ? _dateAdministration!.add(const Duration(days: 365))
                        : DateTime.now().add(const Duration(days: 365)),
                    firstDate: _dateAdministration ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _dateRappel = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Date de rappel (optionnel)'),
                  child: Text(
                    _dateRappel != null
                        ? DateFormat('dd/MM/yyyy').format(_dateRappel!)
                        : 'Sélectionner',
                  ),
                ),
              ),
              TextFormField(
                controller: _veterinaireController,
                decoration: const InputDecoration(labelText: 'Vétérinaire'),
              ),
              TextFormField(
                controller: _numeroLotController,
                decoration: const InputDecoration(labelText: 'Numéro de lot'),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _dateAdministration != null) {
              widget.onSave(Vaccin(
                id: const Uuid().v4(),
                nom: _nomController.text,
                dateAdministration: _dateAdministration!,
                dateRappel: _dateRappel,
                veterinaire: _veterinaireController.text.isEmpty
                    ? null
                    : _veterinaireController.text,
                numeroLot: _numeroLotController.text.isEmpty
                    ? null
                    : _numeroLotController.text,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _ConsultationDialog extends StatefulWidget {
  final Function(ConsultationVeterinaire) onSave;

  const _ConsultationDialog({required this.onSave});

  @override
  State<_ConsultationDialog> createState() => _ConsultationDialogState();
}

class _ConsultationDialogState extends State<_ConsultationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _diagnosticController = TextEditingController();
  final _veterinaireController = TextEditingController();
  final _poidsController = TextEditingController();
  final _traitementController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une consultation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _date = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(
                    _date != null
                        ? DateFormat('dd/MM/yyyy').format(_date!)
                        : 'Sélectionner',
                  ),
                ),
              ),
              TextFormField(
                controller: _motifController,
                decoration: const InputDecoration(labelText: 'Motif'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _diagnosticController,
                decoration: const InputDecoration(labelText: 'Diagnostic'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                maxLines: 2,
              ),
              TextFormField(
                controller: _veterinaireController,
                decoration: const InputDecoration(labelText: 'Vétérinaire'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _poidsController,
                decoration: const InputDecoration(labelText: 'Poids (kg)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _traitementController,
                decoration: const InputDecoration(labelText: 'Traitement prescrit'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _date != null) {
              widget.onSave(ConsultationVeterinaire(
                id: const Uuid().v4(),
                date: _date!,
                motif: _motifController.text,
                diagnostic: _diagnosticController.text,
                veterinaire: _veterinaireController.text,
                poids: _poidsController.text.isEmpty
                    ? null
                    : double.tryParse(_poidsController.text),
                traitement: _traitementController.text.isEmpty
                    ? null
                    : _traitementController.text,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
