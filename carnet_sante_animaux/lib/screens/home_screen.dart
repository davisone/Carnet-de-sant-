import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../services/animal_service.dart';
import 'animal_detail_screen.dart';
import 'add_animal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnimalService _animalService = AnimalService();
  List<Animal> _animaux = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet de Santé Animaux'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedIndex == 0
          ? _buildTousLesAnimaux()
          : _selectedIndex == 1
              ? _buildTraitementsEnCours()
              : _buildVaccinsAVenir(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets),
            label: 'Tous',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication),
            label: 'Traitements',
          ),
          NavigationDestination(
            icon: Icon(Icons.vaccines),
            label: 'Vaccins',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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

    return RefreshIndicator(
      onRefresh: _loadAnimaux,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _animaux.length,
        itemBuilder: (context, index) {
          final animal = _animaux[index];
          return _buildAnimalCard(animal);
        },
      ),
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
                child: Icon(
                  _getAnimalIcon(animal.espece),
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
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

    final animauxAvecTraitement =
        _animaux.where((a) => a.traitementsEnCours.isNotEmpty).toList();

    if (animauxAvecTraitement.isEmpty) {
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
              'Aucun traitement en cours',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: animauxAvecTraitement.length,
      itemBuilder: (context, index) {
        final animal = animauxAvecTraitement[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        _getAnimalIcon(animal.espece),
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      animal.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...animal.traitementsEnCours.map((traitement) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.medication, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                traitement.nom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                traitement.posologie,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (traitement.dateFin != null)
                                Text(
                                  'Fin: ${DateFormat('dd/MM/yyyy').format(traitement.dateFin!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVaccinsAVenir() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final animauxAvecVaccin =
        _animaux.where((a) => a.prochainVaccin != null).toList();

    animauxAvecVaccin.sort((a, b) {
      final dateA = a.prochainVaccin!.dateRappel!;
      final dateB = b.prochainVaccin!.dateRappel!;
      return dateA.compareTo(dateB);
    });

    if (animauxAvecVaccin.isEmpty) {
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
              'Aucun vaccin à venir',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: animauxAvecVaccin.length,
      itemBuilder: (context, index) {
        final animal = animauxAvecVaccin[index];
        final vaccin = animal.prochainVaccin!;
        final joursRestants =
            vaccin.dateRappel!.difference(DateTime.now()).inDays;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    _getAnimalIcon(animal.espece),
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
                        vaccin.nom,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: joursRestants <= 7
                                ? Colors.red
                                : joursRestants <= 30
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(vaccin.dateRappel!)} ($joursRestants jour${joursRestants > 1 ? 's' : ''})',
                            style: TextStyle(
                              fontSize: 12,
                              color: joursRestants <= 7
                                  ? Colors.red
                                  : joursRestants <= 30
                                      ? Colors.orange
                                      : Colors.blue,
                              fontWeight: joursRestants <= 7
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
