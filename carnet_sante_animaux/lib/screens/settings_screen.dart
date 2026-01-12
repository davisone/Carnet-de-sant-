import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/firebase_animal_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAnimalService _animalService = FirebaseAnimalService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Resynchroniser toutes les notifications'),
            subtitle: const Text(
              'Replanifie toutes les notifications pour tous les animaux',
            ),
            trailing: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onTap: _isLoading ? null : _resyncAllNotifications,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_off),
            title: const Text('Annuler toutes les notifications'),
            subtitle: const Text(
              'Supprime toutes les notifications planifiées',
            ),
            trailing: const Icon(Icons.delete),
            onTap: _isLoading ? null : _cancelAllNotifications,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Informations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('À propos'),
            subtitle: Text(
              'Les notifications sont planifiées automatiquement lors de l\'ajout ou modification de:\n'
              '• Vaccins (rappels 3 jours avant et le jour J)\n'
              '• Traitements (rappel le jour de fin)\n'
              '• Pesées pour bébés (rappel hebdomadaire)',
            ),
            isThreeLine: true,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Horaires des notifications'),
            subtitle: const Text(
              'Vaccins: 9h00\n'
              'Traitements: 10h00\n'
              'Pesées: 10h00',
            ),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }

  Future<void> _resyncAllNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer tous les animaux
      final animals = await _animalService.getAnimaux();

      // Resynchroniser toutes les notifications
      await _notificationService.rescheduleAllNotifications(animals);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${animals.length} animaux synchronisés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelAllNotifications() async {
    // Demander confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler toutes les notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _notificationService.cancelAllNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été annulées'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
