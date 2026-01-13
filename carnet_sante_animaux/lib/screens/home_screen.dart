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
import 'animal_poids_screen.dart';
import 'settings_screen.dart';
import 'reproduction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseAnimalService _animalService = FirebaseAnimalService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchControllerTraitements = TextEditingController();
  final TextEditingController _searchControllerVaccins = TextEditingController();
  final TextEditingController _searchControllerMaladies = TextEditingController();
  List<Animal> _animaux = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  late TabController _santeTabController;
  String _filtreEspece = 'Tous';
  String _searchQuery = '';
  String _filtreEspeceTraitements = 'Tous';
  String _searchQueryTraitements = '';
  String _filtreEspeceVaccins = 'Tous';
  String _searchQueryVaccins = '';
  String _filtreEspeceMaladies = 'Tous';
  String _searchQueryMaladies = '';
  bool _selectionMode = false;
  Set<String> _selectedAnimaux = {};

  @override
  void initState() {
    super.initState();
    _santeTabController = TabController(length: 3, vsync: this);
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
    _searchControllerTraitements.dispose();
    _searchControllerVaccins.dispose();
    _searchControllerMaladies.dispose();
    _santeTabController.dispose();
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : _selectedIndex == 1
              ? _buildTousLesAnimaux()
              : _selectedIndex == 2
                  ? _buildSanteScreen()
                  : const ReproductionScreen(),
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
            icon: Icon(Icons.health_and_safety),
            label: 'Santé',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Reproduction',
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
    final bebes = _animaux.where((a) => a.estBebe).toList();

    // Nouvelles statistiques
    final maladiesActives = _animaux.where((a) =>
      a.maladies.any((m) => !m.estGuerite)
    ).toList();

    final now = DateTime.now();
    final debutMois = DateTime(now.year, now.month, 1);
    final consultationsMois = _animaux.expand((a) => a.consultations)
      .where((c) => c.date.isAfter(debutMois))
      .length;

    // Répartition par espèce (normalisée pour éviter les doublons majuscule/minuscule)
    final especesMap = <String, int>{};
    for (var animal in _animaux) {
      // Normaliser : première lettre en majuscule, reste en minuscule
      final especeNormalisee = animal.espece.trim();
      final especeCapitalisee = especeNormalisee.isNotEmpty
          ? '${especeNormalisee[0].toUpperCase()}${especeNormalisee.substring(1).toLowerCase()}'
          : especeNormalisee;
      especesMap[especeCapitalisee] = (especesMap[especeCapitalisee] ?? 0) + 1;
    }
    final especesTopTrois = especesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prochains événements (7 jours)
    final prochainEvenements = _getProchainEvenements();

    return RefreshIndicator(
      onRefresh: _loadAnimaux,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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

          // Indicateur de santé globale
          _buildHealthIndicator(context, vaccinsUrgents, maladiesActives),
          const SizedBox(height: 16),

          // Statistiques principales
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
                  title: 'Maladies actives',
                  value: '${maladiesActives.length}',
                  icon: Icons.health_and_safety,
                  color: Colors.red,
                  onTap: () => setState(() => _selectedIndex = 4),
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
                  title: 'Bébés',
                  value: '${bebes.length}',
                  icon: Icons.child_care,
                  color: Colors.purple,
                  onTap: bebes.isEmpty ? null : () {
                    // Scroll vers la section bébés
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Consultations (mois)',
                  value: '$consultationsMois',
                  icon: Icons.medical_services,
                  color: Colors.cyan,
                  onTap: null,
                ),
              ),
            ],
          ),

          // Répartition par espèce
          if (especesTopTrois.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Répartition par espèce',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildEspecesRepartition(context, especesTopTrois),
          ],

          // Prochains événements
          if (prochainEvenements.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Prochains événements (7 jours)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildProchainEvenementsSection(context, prochainEvenements),
          ],
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
          if (bebes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Bébés à surveiller',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...bebes.map((animal) {
              return Card(
                color: Colors.purple[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    backgroundImage: animal.photoPath != null
                        ? FileImage(File(animal.photoPath!))
                        : null,
                    child: animal.photoPath == null
                        ? Icon(
                            _getAnimalIcon(animal.espece),
                            color: Colors.purple[700],
                          )
                        : null,
                  ),
                  title: Text(animal.nom),
                  subtitle: Row(
                    children: [
                      Text('${animal.ageEnMois} mois'),
                      if (animal.dernierPoids != null) ...[
                        const Text(' • '),
                        Text('${animal.dernierPoids!.poids} kg'),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalPoidsScreen(animal: animal),
                      ),
                    );
                    _loadAnimaux();
                  },
                ),
              );
            }).toList(),
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

    // Récupérer toutes les espèces uniques (normalisées)
    final especesUniques = [
      'Tous',
      ..._animaux.map((a) {
        final especeNormalisee = a.espece.trim();
        return especeNormalisee.isNotEmpty
            ? '${especeNormalisee[0].toUpperCase()}${especeNormalisee.substring(1).toLowerCase()}'
            : especeNormalisee;
      }).toSet().toList()..sort()
    ];

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
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
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

    // Construire le sous-titre avec les infos
    String subtitle = '${animal.espece} - ${animal.ageComplet}';
    if (hasTraitement) {
      subtitle += '\n${animal.traitementsEnCours.length} traitement${animal.traitementsEnCours.length > 1 ? 's' : ''} en cours';
    }
    if (prochainVaccin != null) {
      subtitle += '\nVaccin le ${DateFormat('dd/MM/yyyy').format(prochainVaccin.dateRappel!)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
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
        title: Text(
          animal.nom,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }

  Widget _buildSanteScreen() {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
          child: TabBar(
            controller: _santeTabController,
            tabs: const [
              Tab(icon: Icon(Icons.medication), text: 'Traitements'),
              Tab(icon: Icon(Icons.vaccines), text: 'Vaccins'),
              Tab(icon: Icon(Icons.health_and_safety), text: 'Maladies'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _santeTabController,
            children: [
              _buildTraitementsEnCours(),
              _buildVaccinsAVenir(),
              _buildMaladies(),
            ],
          ),
        ),
      ],
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
    var animauxFiltres = _filtreEspeceTraitements == 'Tous'
        ? _animaux
        : _animaux.where((a) => a.espece == _filtreEspeceTraitements).toList();

    // Filtrer par recherche
    if (_searchQueryTraitements.isNotEmpty) {
      animauxFiltres = animauxFiltres.where((a) =>
        a.nom.toLowerCase().contains(_searchQueryTraitements.toLowerCase()) ||
        a.race.toLowerCase().contains(_searchQueryTraitements.toLowerCase())
      ).toList();
    }

    // Récupérer toutes les espèces uniques (normalisées)
    final especesUniques = [
      'Tous',
      ..._animaux.map((a) {
        final especeNormalisee = a.espece.trim();
        return especeNormalisee.isNotEmpty
            ? '${especeNormalisee[0].toUpperCase()}${especeNormalisee.substring(1).toLowerCase()}'
            : especeNormalisee;
      }).toSet().toList()..sort()
    ];

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchControllerTraitements,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou race...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQueryTraitements.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchControllerTraitements.clear();
                          _searchQueryTraitements = '';
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
                _searchQueryTraitements = value;
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
              final isSelected = _filtreEspeceTraitements == espece;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(espece),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtreEspeceTraitements = espece;
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
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
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
    var animauxFiltres = _filtreEspeceVaccins == 'Tous'
        ? _animaux
        : _animaux.where((a) => a.espece == _filtreEspeceVaccins).toList();

    // Filtrer par recherche
    if (_searchQueryVaccins.isNotEmpty) {
      animauxFiltres = animauxFiltres.where((a) =>
        a.nom.toLowerCase().contains(_searchQueryVaccins.toLowerCase()) ||
        a.race.toLowerCase().contains(_searchQueryVaccins.toLowerCase())
      ).toList();
    }

    // Récupérer toutes les espèces uniques (normalisées)
    final especesUniques = [
      'Tous',
      ..._animaux.map((a) {
        final especeNormalisee = a.espece.trim();
        return especeNormalisee.isNotEmpty
            ? '${especeNormalisee[0].toUpperCase()}${especeNormalisee.substring(1).toLowerCase()}'
            : especeNormalisee;
      }).toSet().toList()..sort()
    ];

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchControllerVaccins,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou race...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQueryVaccins.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchControllerVaccins.clear();
                          _searchQueryVaccins = '';
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
                _searchQueryVaccins = value;
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
              final isSelected = _filtreEspeceVaccins == espece;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(espece),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtreEspeceVaccins = espece;
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
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
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
    var animauxFiltres = _filtreEspeceMaladies == 'Tous'
        ? _animaux
        : _animaux.where((a) => a.espece == _filtreEspeceMaladies).toList();

    // Filtrer par recherche
    if (_searchQueryMaladies.isNotEmpty) {
      animauxFiltres = animauxFiltres.where((a) =>
        a.nom.toLowerCase().contains(_searchQueryMaladies.toLowerCase()) ||
        a.race.toLowerCase().contains(_searchQueryMaladies.toLowerCase())
      ).toList();
    }

    // Récupérer toutes les espèces uniques (normalisées)
    final especesUniques = [
      'Tous',
      ..._animaux.map((a) {
        final especeNormalisee = a.espece.trim();
        return especeNormalisee.isNotEmpty
            ? '${especeNormalisee[0].toUpperCase()}${especeNormalisee.substring(1).toLowerCase()}'
            : especeNormalisee;
      }).toSet().toList()..sort()
    ];

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchControllerMaladies,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou race...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQueryMaladies.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchControllerMaladies.clear();
                          _searchQueryMaladies = '';
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
                _searchQueryMaladies = value;
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
              final isSelected = _filtreEspeceMaladies == espece;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(espece),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtreEspeceMaladies = espece;
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
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
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

    // Onglet Santé - Sous-onglet Traitements en mode sélection
    if (_selectedIndex == 2 && _santeTabController.index == 0 && _selectionMode && _selectedAnimaux.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _ajouterTraitementGroupe,
        icon: const Icon(Icons.medication),
        label: Text('Traiter ${_selectedAnimaux.length} animaux'),
      );
    }

    // Onglet Santé - Sous-onglet Traitements sans sélection
    if (_selectedIndex == 2 && _santeTabController.index == 0) {
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

    // Onglet Santé - Sous-onglet Vaccins en mode sélection
    if (_selectedIndex == 2 && _santeTabController.index == 1 && _selectionMode && _selectedAnimaux.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _ajouterVaccinGroupe,
        icon: const Icon(Icons.vaccines),
        label: Text('Vacciner ${_selectedAnimaux.length} animaux'),
      );
    }

    // Onglet Santé - Sous-onglet Vaccins sans sélection
    if (_selectedIndex == 2 && _santeTabController.index == 1) {
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

    // Onglet Santé - Sous-onglet Maladies en mode sélection
    if (_selectedIndex == 2 && _santeTabController.index == 2 && _selectionMode && _selectedAnimaux.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _ajouterMaladieGroupe,
        icon: const Icon(Icons.health_and_safety),
        label: Text('${_selectedAnimaux.length} animaux'),
      );
    }

    // Onglet Santé - Sous-onglet Maladies sans sélection
    if (_selectedIndex == 2 && _santeTabController.index == 2) {
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

  // Récupérer les prochains événements (vaccins et traitements) sur 7 jours
  List<Map<String, dynamic>> _getProchainEvenements() {
    final maintenant = DateTime.now();
    final dansSeptJours = maintenant.add(const Duration(days: 7));
    List<Map<String, dynamic>> evenements = [];

    for (var animal in _animaux) {
      // Ajouter les vaccins à venir
      if (animal.prochainVaccin != null &&
          animal.prochainVaccin!.dateRappel != null) {
        final dateRappel = animal.prochainVaccin!.dateRappel!;
        if (dateRappel.isAfter(maintenant) && dateRappel.isBefore(dansSeptJours)) {
          evenements.add({
            'type': 'vaccin',
            'animal': animal,
            'date': dateRappel,
            'nom': animal.prochainVaccin!.nom,
            'icon': Icons.vaccines,
            'color': Colors.blue,
          });
        }
      }

      // Ajouter les fins de traitement
      for (var traitement in animal.traitementsEnCours) {
        if (traitement.dateFin != null) {
          final dateFin = traitement.dateFin!;
          if (dateFin.isAfter(maintenant) && dateFin.isBefore(dansSeptJours)) {
            evenements.add({
              'type': 'traitement',
              'animal': animal,
              'date': dateFin,
              'nom': traitement.nom,
              'icon': Icons.medication,
              'color': Colors.orange,
            });
          }
        }
      }
    }

    // Trier par date
    evenements.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return evenements;
  }

  // Widget indicateur de santé globale
  Widget _buildHealthIndicator(BuildContext context, List<Animal> vaccinsUrgents, List<Animal> maladiesActives) {
    String status;
    Color statusColor;
    IconData statusIcon;
    String message;

    if (vaccinsUrgents.isNotEmpty || maladiesActives.length >= 3) {
      status = 'Attention requise';
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      message = 'Vous avez ${vaccinsUrgents.length} vaccin(s) urgent(s) et ${maladiesActives.length} animal/animaux malade(s)';
    } else if (maladiesActives.isNotEmpty || vaccinsUrgents.length > 0) {
      status = 'Surveillance nécessaire';
      statusColor = Colors.orange;
      statusIcon = Icons.info;
      message = 'Quelques points nécessitent votre attention';
    } else {
      status = 'Tout va bien !';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      message = 'Tous vos animaux sont en bonne santé';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget répartition par espèce
  Widget _buildEspecesRepartition(BuildContext context, List<MapEntry<String, int>> especes) {
    final total = _animaux.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: especes.take(5).map((entry) {
            final pourcentage = (entry.value / total * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${entry.value} ($pourcentage%)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: entry.value / total,
                    backgroundColor: Colors.grey[200],
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Widget section prochains événements
  Widget _buildProchainEvenementsSection(BuildContext context, List<Map<String, dynamic>> evenements) {
    return Card(
      child: Column(
        children: evenements.take(5).map((event) {
          final animal = event['animal'] as Animal;
          final date = event['date'] as DateTime;
          final jours = date.difference(DateTime.now()).inDays;

          String dateText;
          if (jours == 0) {
            dateText = 'Aujourd\'hui';
          } else if (jours == 1) {
            dateText = 'Demain';
          } else {
            dateText = 'Dans $jours jours';
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (event['color'] as Color).withOpacity(0.2),
              child: Icon(
                event['icon'] as IconData,
                color: event['color'] as Color,
              ),
            ),
            title: Text(animal.nom),
            subtitle: Text('${event['nom']} - ${DateFormat('dd/MM').format(date)}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (event['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  color: event['color'] as Color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimalDetailScreen(animal: animal),
                ),
              );
              _loadAnimaux();
            },
          );
        }).toList(),
      ),
    );
  }

  IconData _getAnimalIcon(String espece) {
    // Icône patte par défaut pour tous les animaux
    return Icons.pets;
  }
}
