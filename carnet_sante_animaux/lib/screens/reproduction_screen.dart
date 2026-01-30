import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../services/firebase_saillie_service.dart';
import '../services/firebase_animal_service.dart';

class ReproductionScreen extends StatefulWidget {
  const ReproductionScreen({super.key});

  @override
  State<ReproductionScreen> createState() => _ReproductionScreenState();
}

class _ReproductionScreenState extends State<ReproductionScreen> {
  final FirebaseSaillieService _saillieService = FirebaseSaillieService();
  final FirebaseAnimalService _animalService = FirebaseAnimalService();
  List<Saillie> _saillies = [];
  List<Animal> _animaux = [];
  bool _isLoading = true;
  int? _filtreAnnee;
  final List<int> _annees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final saillies = await _saillieService.getSaillies();
    final animaux = await _animalService.getAnimaux();

    // Générer la liste des années disponibles
    final anneesSet = <int>{};
    for (var saillie in saillies) {
      anneesSet.add(saillie.dateSaillie.year);
    }
    final anneesList = anneesSet.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _saillies = saillies;
      _animaux = animaux;
      _annees.clear();
      _annees.addAll(anneesList);
      _isLoading = false;
    });
  }

  List<Saillie> get _sailliesFiltrees {
    if (_filtreAnnee == null) return _saillies;
    return _saillies
        .where((s) => s.dateSaillie.year == _filtreAnnee)
        .toList();
  }

  Animal? _getAnimalById(String id) {
    try {
      return _animaux.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _ajouterSaillie() async {
    final result = await _showSaillieDialog();
    if (result != null) {
      await _saillieService.saveSaillie(result);
      _loadData();
    }
  }

  Future<void> _modifierSaillie(Saillie saillie) async {
    final result = await _showSaillieDialog(saillie: saillie);
    if (result != null) {
      await _saillieService.saveSaillie(result);
      _loadData();
    }
  }

  Future<void> _supprimerSaillie(Saillie saillie) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Voulez-vous vraiment supprimer cette saillie ?'),
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
      await _saillieService.deleteSaillie(saillie.id);
      _loadData();
    }
  }

  Future<Saillie?> _showSaillieDialog({Saillie? saillie}) async {
    final formKey = GlobalKey<FormState>();
    String? mereId = saillie?.mereId;
    String? pereId = saillie?.pereId;
    DateTime dateSaillie = saillie?.dateSaillie ?? DateTime.now();
    String type = saillie?.type ?? 'naturelle';
    String statut = saillie?.statut ?? 'en_attente';
    DateTime? dateMiseBas = saillie?.dateMiseBas;
    int? nombreBebes = saillie?.nombreBebes;
    List<String> bebesIds = List.from(saillie?.bebesIds ?? []);
    String notes = saillie?.notes ?? '';

    // Filtrer les animaux : femelles pour mères, mâles pour pères
    final femelles = _animaux.where((a) => a.sexe?.toLowerCase() == 'femelle').toList();
    final males = _animaux.where((a) => a.sexe?.toLowerCase() == 'mâle' || a.sexe?.toLowerCase() == 'male').toList();

    // Pour les bébés, on peut prendre tous les animaux sauf mère et père
    final bebesPotentiels = _animaux.where((a) =>
      a.id != mereId && a.id != pereId
    ).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(saillie == null ? 'Ajouter une saillie' : 'Modifier la saillie'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélection de la mère
                  DropdownButtonFormField<String>(
                    value: mereId,
                    decoration: const InputDecoration(
                      labelText: 'Mère',
                      border: OutlineInputBorder(),
                    ),
                    items: femelles.map((animal) {
                      return DropdownMenuItem(
                        value: animal.id,
                        child: Text('${animal.nom} (${animal.espece})'),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => mereId = value),
                    validator: (value) => value == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),

                  // Sélection du père
                  DropdownButtonFormField<String>(
                    value: pereId,
                    decoration: const InputDecoration(
                      labelText: 'Père',
                      border: OutlineInputBorder(),
                    ),
                    items: males.map((animal) {
                      return DropdownMenuItem(
                        value: animal.id,
                        child: Text('${animal.nom} (${animal.espece})'),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => pereId = value),
                    validator: (value) => value == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),

                  // Date de saillie
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de saillie'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(dateSaillie)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: dateSaillie,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (newDate != null) {
                        setDialogState(() => dateSaillie = newDate);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Type
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'naturelle', child: Text('Naturelle')),
                      DropdownMenuItem(value: 'artificielle', child: Text('Artificielle')),
                    ],
                    onChanged: (value) => setDialogState(() => type = value!),
                  ),
                  const SizedBox(height: 12),

                  // Statut
                  DropdownButtonFormField<String>(
                    value: statut,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                      DropdownMenuItem(value: 'reussie', child: Text('Réussie')),
                      DropdownMenuItem(value: 'echouee', child: Text('Échouée')),
                    ],
                    onChanged: (value) => setDialogState(() => statut = value!),
                  ),
                  const SizedBox(height: 12),

                  // Date de mise bas (si réussie)
                  if (statut == 'reussie') ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date de mise bas'),
                      subtitle: Text(dateMiseBas != null
                          ? DateFormat('dd/MM/yyyy').format(dateMiseBas!)
                          : 'Non renseignée'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: dateMiseBas ?? dateSaillie.add(const Duration(days: 150)),
                          firstDate: dateSaillie,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (newDate != null) {
                          setDialogState(() => dateMiseBas = newDate);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Nombre de bébés
                    TextFormField(
                      initialValue: nombreBebes?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de bébés',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        setDialogState(() => nombreBebes = parsed);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Sélection des bébés
                    Text('Bébés (${bebesIds.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: bebesIds.map((bebeId) {
                        final bebe = _getAnimalById(bebeId);
                        return Chip(
                          label: Text(bebe?.nom ?? 'Inconnu'),
                          onDeleted: () {
                            setDialogState(() => bebesIds.remove(bebeId));
                          },
                        );
                      }).toList(),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sélectionner un bébé'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: bebesPotentiels.map((animal) {
                                  return ListTile(
                                    title: Text(animal.nom),
                                    subtitle: Text('${animal.espece} - ${animal.ageComplet}'),
                                    onTap: () => Navigator.pop(context, animal.id),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                        if (selected != null && !bebesIds.contains(selected)) {
                          setDialogState(() => bebesIds.add(selected));
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un bébé'),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Notes
                  TextFormField(
                    initialValue: notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => notes = value,
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
                  Navigator.pop(context, true);
                }
              },
              child: Text(saillie == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mereId != null && pereId != null) {
      return Saillie(
        id: saillie?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        mereId: mereId!,
        pereId: pereId!,
        dateSaillie: dateSaillie,
        type: type,
        statut: statut,
        dateMiseBas: dateMiseBas,
        nombreBebes: nombreBebes,
        bebesIds: bebesIds,
        notes: notes.isEmpty ? null : notes,
      );
    }
    return null;
  }

  Widget _buildStatistiques() {
    final sailliesAffichees = _sailliesFiltrees;
    final reussies = sailliesAffichees.where((s) => s.statut == 'reussie').length;
    final enAttente = sailliesAffichees.where((s) => s.statut == 'en_attente').length;
    final echouees = sailliesAffichees.where((s) => s.statut == 'echouee').length;
    final totalBebes = sailliesAffichees.fold<int>(
      0,
      (sum, s) => sum + (s.nombreBebes ?? 0),
    );

    final tauxReussite = sailliesAffichees.isNotEmpty
        ? (reussies / sailliesAffichees.length * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Statistiques ${_filtreAnnee != null ? _filtreAnnee.toString() : "globales"}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total', sailliesAffichees.length.toString(), Colors.blue),
                _buildStatCard('Réussies', reussies.toString(), Colors.green),
                _buildStatCard('En attente', enAttente.toString(), Colors.orange),
                _buildStatCard('Échouées', echouees.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Taux réussite', '$tauxReussite%', Colors.teal),
                _buildStatCard('Bébés', totalBebes.toString(), Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sailliesAffichees = _sailliesFiltrees
      ..sort((a, b) => b.dateSaillie.compareTo(a.dateSaillie));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // Filtre par année
            if (_annees.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Année : ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Toutes'),
                              selected: _filtreAnnee == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _filtreAnnee = null);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ..._annees.map((annee) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(annee.toString()),
                                    selected: _filtreAnnee == annee,
                                    onSelected: (selected) {
                                      setState(() => _filtreAnnee = selected ? annee : null);
                                    },
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Statistiques
            _buildStatistiques(),

            // Liste des saillies
            Expanded(
              child: sailliesAffichees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune saillie enregistrée',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: sailliesAffichees.length,
                      itemBuilder: (context, index) {
                        final saillie = sailliesAffichees[index];
                        final mere = _getAnimalById(saillie.mereId);
                        final pere = _getAnimalById(saillie.pereId);

                        Color statutColor = Colors.orange;
                        IconData statutIcon = Icons.hourglass_empty;
                        if (saillie.statut == 'reussie') {
                          statutColor = Colors.green;
                          statutIcon = Icons.check_circle;
                        } else if (saillie.statut == 'echouee') {
                          statutColor = Colors.red;
                          statutIcon = Icons.cancel;
                        }

                        final joursRestants = saillie.joursRestantsAvantNaissance;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(statutIcon, color: statutColor, size: 40),
                            title: Text(
                              '${mere?.nom ?? "Inconnu"} × ${pere?.nom ?? "Inconnu"}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Saillie : ${DateFormat('dd/MM/yyyy').format(saillie.dateSaillie)}'),
                                Text('Type : ${saillie.type.capitalize()}'),
                                if (saillie.statut == 'en_attente') ...[
                                  Text(
                                    'Naissance prévue : ${DateFormat('dd/MM/yyyy').format(saillie.dateNaissancePrevue)}',
                                  ),
                                  const SizedBox(height: 4),
                                  if (joursRestants >= 0) ...[
                                    Text(
                                      '${saillie.joursEcoules} jour${saillie.joursEcoules > 1 ? 's' : ''} écoulé${saillie.joursEcoules > 1 ? 's' : ''} — $joursRestants jour${joursRestants > 1 ? 's' : ''} restant${joursRestants > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: joursRestants <= 7 ? Colors.red : Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: saillie.joursEcoules / Saillie.dureeGestationJours,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          joursRestants <= 7 ? Colors.red : Colors.orange,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ] else
                                    const Text(
                                      'Terme dépassé',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                                if (saillie.statut == 'reussie' && saillie.dateMiseBas != null)
                                  Text('Mise bas : ${DateFormat('dd/MM/yyyy').format(saillie.dateMiseBas!)}'),
                                if (saillie.nombreBebes != null)
                                  Text('Bébés : ${saillie.nombreBebes}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  _modifierSaillie(saillie);
                                } else if (value == 'supprimer') {
                                  _supprimerSaillie(saillie);
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterSaillie,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
