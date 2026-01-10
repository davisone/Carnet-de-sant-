import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../services/firebase_animal_service.dart';
import 'animal_detail_screen.dart';
import 'add_animal_screen.dart';
import 'family_tree_screen.dart';
import 'animal_traitements_screen.dart';
import 'animal_vaccins_screen.dart';
import 'animal_maladies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAnimalService _animalService = FirebaseAnimalService();
  final TextEditingController _searchController = TextEditingController();
  List<Animal> _animaux = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  String _filtreEspece = 'Tous';
  String _searchQuery = '';
  bool _selectionMode = false;
  Set<String> _selectedAnimaux = {};

  @override
  void initState() {
    super.initState();
    _loadAnimaux();
  }

  Future<void> _loadAnimaux() async {
    setState(() => _isLoading = true);
    final animaux = await _animalService.getAnimaux();
    setState(() {
      _animaux = animaux;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet de Santé Animaux'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Arbre généalogique',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FamilyTreeScreen(),
                ),
              );
              _loadAnimaux();
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : _selectedIndex == 1
              ? _buildTousLesAnimaux()
              : _selectedIndex == 2
                  ? _buildTraitementsEnCours()
                  : _selectedIndex == 3
                      ? _buildVaccinsAVenir()
                      : _buildMaladies(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets),
            label: 'Animaux',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication),
            label: 'Traitements',
          ),
          NavigationDestination(
            icon: Icon(Icons.vaccines),
            label: 'Vaccins',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety),
            label: 'Maladies',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final animauxEnTraitement = _animaux.where((a) => a.traitementsEnCours.isNotEmpty).toList();
    final animauxAvecVaccin = _animaux.where((a) => a.prochainVaccin != null).toList();
    final vaccinsUrgents = animauxAvecVaccin.where((a) {
      final jours = a.prochainVaccin!.dateRappel!.difference(DateTime.now()).inDays;
      return jours <= 7;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAnimaux,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bienvenue !',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vue d\'ensemble de vos animaux',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Animaux',
                  value: '${_animaux.length}',
                  icon: Icons.pets,
                  color: Colors.teal,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'En traitement',
                  value: '${animauxEnTraitement.length}',
                  icon: Icons.medication,
                  color: Colors.orange,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Vaccins à venir',
                  value: '${animauxAvecVaccin.length}',
                  icon: Icons.vaccines,
                  color: Colors.blue,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Vaccins urgents',
                  value: '${vaccinsUrgents.length}',
                  icon: Icons.warning,
                  color: Colors.red,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),
            ],
          ),
          if (vaccinsUrgents.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Vaccins urgents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...vaccinsUrgents.map((animal) {
              final vaccin = animal.prochainVaccin!;
              final jours = vaccin.dateRappel!.difference(DateTime.now()).inDays;
              return Card(
                color: Colors.red[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.warning, color: Colors.white),
                  ),
                  title: Text(animal.nom),
                  subtitle: Text(
                    '${vaccin.nom} - ${jours == 0 ? 'Aujourd\'hui' : 'Dans $jours jour${jours > 1 ? 's' : ''}'}',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalDetailScreen(animal: animal),
                      ),
                    );
                    _loadAnimaux();
                  },
                ),
              );
            }).toList(),
          ],
          if (animauxEnTraitement.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Animaux en traitement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...animauxEnTraitement.take(3).map((animal) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: animal.photoPath != null
                        ? FileImage(File(animal.photoPath!))
                        : null,
                    child: animal.photoPath == null
                        ? Icon(
                            _getAnimalIcon(animal.espece),
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  title: Text(animal.nom),
                  subtitle: Text(
                    '${animal.traitementsEnCours.length} traitement${animal.traitementsEnCours.length > 1 ? 's' : ''} en cours',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalDetailScreen(animal: animal),
                      ),
                    );
                    _loadAnimaux();
                  },
                ),
              );
            }).toList(),
            if (animauxEnTraitement.length > 3)
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: Text('Voir tous les traitements (${animauxEnTraitement.length})'),
              ),
          ],
          if (_animaux.isEmpty) ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun animal enregistré',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour ajouter votre premier animal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTousLesAnimaux() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_animaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun animal enregistré',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour ajouter votre premier animal',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Filtrer les animaux selon l'espèce sélectionnée et la recherche
    var animauxFiltres = _filtreEspece == 'Tous'
        ? _animaux
        : _animaux.where((a) => a.espece == _filtreEspece).toList();

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      animauxFiltres = animauxFiltres.where((a) =>
        a.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a.race.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Récupérer toutes les espèces uniques
    final especesUniques = ['Tous', ..._animaux.map((a) => a.espece).toSet().toList()..sort()];

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou race...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        // Barre de filtres
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: especesUniques.length,
            itemBuilder: (context, index) {
              final espece = especesUniques[index];
              final isSelected = _filtreEspece == espece;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(espece),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtreEspece = espece;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        // Liste des animaux filtrés
        Expanded(
          child: animauxFiltres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun animal de type "$_filtreEspece"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnimaux,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: animauxFiltres.length,
                    itemBuilder: (context, index) {
                      final animal = animauxFiltres[index];
                      return _buildAnimalCard(animal);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final hasTraitement = animal.traitementsEnCours.isNotEmpty;
    final prochainVaccin = animal.prochainVaccin;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimalDetailScreen(animal: animal),
            ),
          );
          if (result == true) {
            _loadAnimaux();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: animal.photoPath != null
                    ? FileImage(File(animal.photoPath!))
                    : null,
                child: animal.photoPath == null
                    ? Icon(
                        _getAnimalIcon(animal.espece),
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${animal.espece} - ${animal.age} an${animal.age > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (hasTraitement || prochainVaccin != null)
                      const SizedBox(height: 4),
                    if (hasTraitement)
                      Row(
                        children: [
                          Icon(
                            Icons.medication,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${animal.traitementsEnCours.length} traitement${animal.traitementsEnCours.length > 1 ? 's' : ''} en cours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    if (prochainVaccin != null)
                      Row(
                        children: [
                          Icon(
                            Icons.vaccines,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vaccin le ${DateFormat('dd/MM/yyyy').format(prochainVaccin.dateRappel!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraitementsEnCours() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_animaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun animal enregistré',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Filtrer les animaux selon l'espèce sélectionnée et la recherche
    var animauxFiltres = _filtreEspece == 'Tous'
        ? _animaux
        : _animaux.where((a) => a.espece == _filtreEspece).toList();

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      animauxFiltres = animauxFiltres.where((a) =>
        a.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a.race.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Récupérer toutes les espèces uniques
    final especesUniques = ['Tous', ..._animaux.map((a) => a.espece).toSet().toList()..sort()];

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou race...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        // Barre de filtres
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: especesUniques.length,
            itemBuilder: (context, index) {
              final espece = especesUniques[index];
              final isSelected = _filtreEspece == espece;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(espece),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtreEspece = espece;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Text(
                  '${_selectedAnimaux.length} sélectionné${_selectedAnimaux.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedAnimaux.length == animauxFiltres.length) {
                        _selectedAnimaux.clear();
                      } else {
                        _selectedAnimaux = animauxFiltres.map((a) => a.id).toSet();
                      }
                    });
                  },
                  icon: Icon(
                    _selectedAnimaux.length == animauxFiltres.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  label: Text(
                    _selectedAnimaux.length == animauxFiltres.length
                        ? 'Tout désélectionner'
                        : 'Tout sélectionner',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedAnimaux.clear();
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        Expanded(
          child: animauxFiltres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun résultat',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnimaux,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: animauxFiltres.length,
                    itemBuilder: (context, index) {
                      final animal = animauxFiltres[index];
                      final nbTraitements = animal.traitements.length;
                      final nbTraitementsEnCours = animal.traitementsEnCours.length;
                      final isSelected = _selectedAnimaux.contains(animal.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                        child: ListTile(
                          leading: _selectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedAnimaux.add(animal.id);
                                      } else {
                                        _selectedAnimaux.remove(animal.id);
                                      }
                                    });
                                  },
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  backgroundImage: animal.photoPath != null
                                      ? FileImage(File(animal.photoPath!))
                                      : null,
                                  child: animal.photoPath == null
                                      ? Icon(
                                          _getAnimalIcon(animal.espece),
                                          size: 28,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                ),
                          title: Text(
                            animal.nom,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            nbTraitements == 0
                                ? 'Aucun traitement'
                                : '$nbTraitements traitement${nbTraitements > 1 ? 's' : ''}'
                                '${nbTraitementsEnCours > 0 ? ' ($nbTraitementsEnCours en cours)' : ''}',
                            style: TextStyle(
                              color: nbTraitementsEnCours > 0 ? Colors.orange[700] : Colors.grey[600],
                            ),
                          ),
                          trailing: _selectionMode ? null : const Icon(Icons.chevron_right),
                          onTap: () async {
                            if (_selectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedAnimaux.remove(animal.id);
                                } else {
                                  _selectedAnimaux.add(animal.id);
                                }
                              });
                            } else {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimalTraitementsScreen(animal: animal),
                                ),
                              );
                              _loadAnimaux();
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _selectionMode = true;
                              _selectedAnimaux.add(animal.id);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVaccinsAVenir() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_animaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vaccines,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun animal enregistré',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Filtrer les animaux selon l'espèce sélectionnée et la recherche
    var animauxFiltres = _filtreEspece == 'Tous'
        ? _animaux
        : _animaux.where((a) => a.espece == _filtreEspece).toList();

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      animauxFiltres = animauxFiltres.where((a) =>
        a.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a.race.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Récupérer toutes les espèces uniques
    final especesUniques = ['Tous', ..._animaux.map((a) => a.espece).toSet().toList()..sort()];

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou race...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        // Barre de filtres
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: especesUniques.length,
            itemBuilder: (context, index) {
              final espece = especesUniques[index];
              final isSelected = _filtreEspece == espece;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(espece),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtreEspece = espece;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Text(
                  '${_selectedAnimaux.length} sélectionné${_selectedAnimaux.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedAnimaux.length == animauxFiltres.length) {
                        _selectedAnimaux.clear();
                      } else {
                        _selectedAnimaux = animauxFiltres.map((a) => a.id).toSet();
                      }
                    });
                  },
                  icon: Icon(
                    _selectedAnimaux.length == animauxFiltres.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  label: Text(
                    _selectedAnimaux.length == animauxFiltres.length
                        ? 'Tout désélectionner'
                        : 'Tout sélectionner',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedAnimaux.clear();
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        Expanded(
          child: animauxFiltres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun résultat',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnimaux,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: animauxFiltres.length,
                    itemBuilder: (context, index) {
                      final animal = animauxFiltres[index];
                      final nbVaccins = animal.vaccins.length;
                      final prochainVaccin = animal.prochainVaccin;
                      final isSelected = _selectedAnimaux.contains(animal.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                        child: ListTile(
                          leading: _selectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedAnimaux.add(animal.id);
                                      } else {
                                        _selectedAnimaux.remove(animal.id);
                                      }
                                    });
                                  },
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  backgroundImage: animal.photoPath != null
                                      ? FileImage(File(animal.photoPath!))
                                      : null,
                                  child: animal.photoPath == null
                                      ? Icon(
                                          _getAnimalIcon(animal.espece),
                                          size: 28,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                ),
                          title: Text(
                            animal.nom,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            nbVaccins == 0
                                ? 'Aucun vaccin'
                                : '$nbVaccins vaccin${nbVaccins > 1 ? 's' : ''}'
                                '${prochainVaccin != null ? ' (rappel prévu)' : ''}',
                            style: TextStyle(
                              color: prochainVaccin != null ? Colors.blue[700] : Colors.grey[600],
                            ),
                          ),
                          trailing: _selectionMode ? null : const Icon(Icons.chevron_right),
                          onTap: () async {
                            if (_selectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedAnimaux.remove(animal.id);
                                } else {
                                  _selectedAnimaux.add(animal.id);
                                }
                              });
                            } else {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimalVaccinsScreen(animal: animal),
                                ),
                              );
                              _loadAnimaux();
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _selectionMode = true;
                              _selectedAnimaux.add(animal.id);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMaladies() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_animaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun animal enregistré',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Filtrer les animaux selon l'espèce sélectionnée et la recherche
    var animauxFiltres = _filtreEspece == 'Tous'
        ? _animaux
        : _animaux.where((a) => a.espece == _filtreEspece).toList();

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      animauxFiltres = animauxFiltres.where((a) =>
        a.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a.race.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Récupérer toutes les espèces uniques
    final especesUniques = ['Tous', ..._animaux.map((a) => a.espece).toSet().toList()..sort()];

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou race...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        // Barre de filtres
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: especesUniques.length,
            itemBuilder: (context, index) {
              final espece = especesUniques[index];
              final isSelected = _filtreEspece == espece;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(espece),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtreEspece = espece;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Text(
                  '${_selectedAnimaux.length} sélectionné${_selectedAnimaux.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedAnimaux.length == animauxFiltres.length) {
                        _selectedAnimaux.clear();
                      } else {
                        _selectedAnimaux = animauxFiltres.map((a) => a.id).toSet();
                      }
                    });
                  },
                  icon: Icon(
                    _selectedAnimaux.length == animauxFiltres.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  label: Text(
                    _selectedAnimaux.length == animauxFiltres.length
                        ? 'Tout désélectionner'
                        : 'Tout sélectionner',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedAnimaux.clear();
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        Expanded(
          child: animauxFiltres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun résultat',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnimaux,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: animauxFiltres.length,
                    itemBuilder: (context, index) {
                      final animal = animauxFiltres[index];
                      final nbMaladies = animal.maladies.length;
                      final maladiesActives = animal.maladies.where((m) => !m.estGuerite).length;
                      final isSelected = _selectedAnimaux.contains(animal.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                        child: ListTile(
                          leading: _selectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedAnimaux.add(animal.id);
                                      } else {
                                        _selectedAnimaux.remove(animal.id);
                                      }
                                    });
                                  },
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  backgroundImage: animal.photoPath != null
                                      ? FileImage(File(animal.photoPath!))
                                      : null,
                                  child: animal.photoPath == null
                                      ? Icon(
                                          _getAnimalIcon(animal.espece),
                                          size: 28,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                ),
                          title: Text(
                            animal.nom,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            nbMaladies == 0
                                ? 'Aucune maladie'
                                : '$nbMaladies maladie${nbMaladies > 1 ? 's' : ''}'
                                '${maladiesActives > 0 ? ' ($maladiesActives active${maladiesActives > 1 ? 's' : ''})' : ''}',
                            style: TextStyle(
                              color: maladiesActives > 0 ? Colors.red[700] : Colors.grey[600],
                            ),
                          ),
                          trailing: _selectionMode ? null : const Icon(Icons.chevron_right),
                          onTap: () async {
                            if (_selectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedAnimaux.remove(animal.id);
                                } else {
                                  _selectedAnimaux.add(animal.id);
                                }
                              });
                            } else {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimalMaladiesScreen(animal: animal),
                                ),
                              );
                              _loadAnimaux();
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _selectionMode = true;
                              _selectedAnimaux.add(animal.id);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    // Onglet Accueil ou Animaux : Ajouter un animal
    if (_selectedIndex == 0 || _selectedIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAnimalScreen()),
          );
          if (result == true) {
            _loadAnimaux();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un animal'),
      );
    }

    // Onglet Traitements en mode sélection
    if (_selectedIndex == 2 && _selectionMode && _selectedAnimaux.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _ajouterTraitementGroupe,
        icon: const Icon(Icons.medication),
        label: Text('Traiter ${_selectedAnimaux.length} animaux'),
      );
    }

    // Onglet Traitements sans sélection
    if (_selectedIndex == 2) {
      return FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _selectionMode = true;
          });
        },
        icon: const Icon(Icons.checklist),
        label: const Text('Sélectionner'),
      );
    }

    // Onglet Vaccins en mode sélection
    if (_selectedIndex == 3 && _selectionMode && _selectedAnimaux.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _ajouterVaccinGroupe,
        icon: const Icon(Icons.vaccines),
        label: Text('Vacciner ${_selectedAnimaux.length} animaux'),
      );
    }

    // Onglet Vaccins sans sélection
    if (_selectedIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _selectionMode = true;
          });
        },
        icon: const Icon(Icons.checklist),
        label: const Text('Sélectionner'),
      );
    }

    // Onglet Maladies en mode sélection
    if (_selectedIndex == 4 && _selectionMode && _selectedAnimaux.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _ajouterMaladieGroupe,
        icon: const Icon(Icons.health_and_safety),
        label: Text('${_selectedAnimaux.length} animaux'),
      );
    }

    // Onglet Maladies sans sélection
    if (_selectedIndex == 4) {
      return FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _selectionMode = true;
          });
        },
        icon: const Icon(Icons.checklist),
        label: const Text('Sélectionner'),
      );
    }

    return null;
  }

  Future<void> _ajouterTraitementGroupe() async {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    String description = '';
    String posologie = '';
    DateTime dateDebut = DateTime.now();
    DateTime? dateFin;
    String notes = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Traiter ${_selectedAnimaux.length} animaux'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nom du traitement'),
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
      ),
    );

    if (result == true) {
      // Ajouter le traitement à tous les animaux sélectionnés
      for (final animalId in _selectedAnimaux) {
        final animal = _animaux.firstWhere((a) => a.id == animalId);

        final newTraitement = Traitement(
          id: '${DateTime.now().millisecondsSinceEpoch}_$animalId',
          nom: nom,
          description: description,
          posologie: posologie,
          dateDebut: dateDebut,
          dateFin: dateFin,
          notes: notes.isEmpty ? null : notes,
        );

        final updatedAnimal = animal.copyWith(
          traitements: [...animal.traitements, newTraitement],
        );

        await _animalService.saveAnimal(updatedAnimal);
      }

      setState(() {
        _selectionMode = false;
        _selectedAnimaux.clear();
      });

      await _loadAnimaux();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Traitement ajouté à ${_selectedAnimaux.length} animaux'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _ajouterVaccinGroupe() async {
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
          title: Text('Vacciner ${_selectedAnimaux.length} animaux'),
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
      for (final animalId in _selectedAnimaux) {
        final animal = _animaux.firstWhere((a) => a.id == animalId);

        final newVaccin = Vaccin(
          id: '${DateTime.now().millisecondsSinceEpoch}_$animalId',
          nom: nom,
          dateAdministration: dateAdministration,
          dateRappel: dateRappel,
          numeroLot: numeroLot.isEmpty ? null : numeroLot,
          veterinaire: veterinaire.isEmpty ? null : veterinaire,
          notes: notes.isEmpty ? null : notes,
        );

        final updatedAnimal = animal.copyWith(
          vaccins: [...animal.vaccins, newVaccin],
        );

        await _animalService.saveAnimal(updatedAnimal);
      }

      setState(() {
        _selectionMode = false;
        _selectedAnimaux.clear();
      });

      await _loadAnimaux();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vaccin ajouté à ${_selectedAnimaux.length} animaux'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _ajouterMaladieGroupe() async {
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
          title: Text('Maladie pour ${_selectedAnimaux.length} animaux'),
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
                    title: const Text('Animaux guéris'),
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
      for (final animalId in _selectedAnimaux) {
        final animal = _animaux.firstWhere((a) => a.id == animalId);

        final newMaladie = Maladie(
          id: '${DateTime.now().millisecondsSinceEpoch}_$animalId',
          nom: nom,
          dateDiagnostic: dateDiagnostic,
          description: description.isEmpty ? null : description,
          estChronique: estChronique,
          estGuerite: estGuerite,
          dateGuerison: dateGuerison,
          traitement: traitement.isEmpty ? null : traitement,
          notes: notes.isEmpty ? null : notes,
        );

        final updatedAnimal = animal.copyWith(
          maladies: [...animal.maladies, newMaladie],
        );

        await _animalService.saveAnimal(updatedAnimal);
      }

      setState(() {
        _selectionMode = false;
        _selectedAnimaux.clear();
      });

      await _loadAnimaux();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maladie ajoutée à ${_selectedAnimaux.length} animaux'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  IconData _getAnimalIcon(String espece) {
    switch (espece.toLowerCase()) {
      case 'chien':
        return Icons.pets;
      case 'chat':
        return Icons.pets;
      case 'lapin':
        return Icons.cruelty_free;
      case 'oiseau':
        return Icons.flutter_dash;
      default:
        return Icons.pets;
    }
  }
}
