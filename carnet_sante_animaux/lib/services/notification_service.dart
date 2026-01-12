import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/animal.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialiser les timezones
    tz.initializeTimeZones();

    // Obtenir la timezone locale
    // Pour l'Europe/Paris, utilisez 'Europe/Paris'
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));

    // Configuration Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// Demande les permissions pour les notifications
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Callback quand une notification est tapée
  void _onNotificationTap(NotificationResponse notificationResponse) {
    // Ici vous pouvez naviguer vers une page spécifique
    // selon le payload de la notification
    print('Notification tapée: ${notificationResponse.payload}');
  }

  /// Planifie une notification à une date précise
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'animal_health_channel',
          'Santé des animaux',
          channelDescription: 'Notifications pour les rappels de santé',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Planifie un rappel de vaccin
  Future<void> scheduleVaccineReminder({
    required String animalId,
    required String animalName,
    required String vaccineName,
    required DateTime dateRappel,
  }) async {
    // Notification 3 jours avant
    final threeDaysBefore = dateRappel.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _generateVaccineNotificationId(animalId, vaccineName, -3),
        title: 'Rappel vaccin - $animalName',
        body: 'Vaccin "$vaccineName" prévu dans 3 jours',
        scheduledDate: threeDaysBefore.copyWith(hour: 9, minute: 0),
        payload: 'vaccine:$animalId',
      );
    }

    // Notification le jour même
    if (dateRappel.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _generateVaccineNotificationId(animalId, vaccineName, 0),
        title: 'Vaccin aujourd\'hui - $animalName',
        body: 'Rappel du vaccin "$vaccineName"',
        scheduledDate: dateRappel.copyWith(hour: 9, minute: 0),
        payload: 'vaccine:$animalId',
      );
    }
  }

  /// Annule les rappels de vaccin pour un animal
  Future<void> cancelVaccineReminders(String animalId, String vaccineName) async {
    await cancelNotification(_generateVaccineNotificationId(animalId, vaccineName, -3));
    await cancelNotification(_generateVaccineNotificationId(animalId, vaccineName, 0));
  }

  /// Planifie une alerte de fin de traitement
  Future<void> scheduleTreatmentEndReminder({
    required String animalId,
    required String animalName,
    required String treatmentName,
    required DateTime dateFin,
  }) async {
    // Notification le jour de fin de traitement
    if (dateFin.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _generateTreatmentNotificationId(animalId, treatmentName),
        title: 'Fin de traitement - $animalName',
        body: 'Le traitement "$treatmentName" se termine aujourd\'hui',
        scheduledDate: dateFin.copyWith(hour: 10, minute: 0),
        payload: 'treatment:$animalId',
      );
    }
  }

  /// Annule l'alerte de fin de traitement
  Future<void> cancelTreatmentReminder(String animalId, String treatmentName) async {
    await cancelNotification(_generateTreatmentNotificationId(animalId, treatmentName));
  }

  /// Planifie un rappel pour peser un bébé animal
  Future<void> scheduleBabyWeightReminder({
    required String animalId,
    required String animalName,
    required DateTime nextWeighingDate,
  }) async {
    if (nextWeighingDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _generateBabyWeightNotificationId(animalId),
        title: 'Pesée - $animalName',
        body: 'Il est temps de peser $animalName',
        scheduledDate: nextWeighingDate.copyWith(hour: 10, minute: 0),
        payload: 'weight:$animalId',
      );
    }
  }

  /// Annule le rappel de pesée
  Future<void> cancelBabyWeightReminder(String animalId) async {
    await cancelNotification(_generateBabyWeightNotificationId(animalId));
  }

  /// Planifie un rappel de consultation vétérinaire
  Future<void> scheduleConsultationReminder({
    required String animalId,
    required String animalName,
    required DateTime consultationDate,
    required String motif,
  }) async {
    // Notification la veille
    final oneDayBefore = consultationDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _generateConsultationNotificationId(animalId, -1),
        title: 'Consultation demain - $animalName',
        body: 'Rendez-vous vétérinaire: $motif',
        scheduledDate: oneDayBefore.copyWith(hour: 18, minute: 0),
        payload: 'consultation:$animalId',
      );
    }

    // Notification 2h avant
    final twoHoursBefore = consultationDate.subtract(const Duration(hours: 2));
    if (twoHoursBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _generateConsultationNotificationId(animalId, 0),
        title: 'Consultation dans 2h - $animalName',
        body: 'Rendez-vous vétérinaire: $motif',
        scheduledDate: twoHoursBefore,
        payload: 'consultation:$animalId',
      );
    }
  }

  /// Annule les rappels de consultation
  Future<void> cancelConsultationReminders(String animalId) async {
    await cancelNotification(_generateConsultationNotificationId(animalId, -1));
    await cancelNotification(_generateConsultationNotificationId(animalId, 0));
  }

  /// Replanifie toutes les notifications pour tous les animaux
  Future<void> rescheduleAllNotifications(List<Animal> animals) async {
    // Annuler toutes les notifications existantes
    await cancelAllNotifications();

    // Replanifier pour chaque animal
    for (final animal in animals) {
      // Vaccins
      for (final vaccin in animal.vaccins) {
        if (vaccin.dateRappel != null && vaccin.dateRappel!.isAfter(DateTime.now())) {
          await scheduleVaccineReminder(
            animalId: animal.id,
            animalName: animal.nom,
            vaccineName: vaccin.nom,
            dateRappel: vaccin.dateRappel!,
          );
        }
      }

      // Traitements
      for (final traitement in animal.traitements) {
        if (traitement.dateFin != null &&
            traitement.dateFin!.isAfter(DateTime.now()) &&
            traitement.estEnCours) {
          await scheduleTreatmentEndReminder(
            animalId: animal.id,
            animalName: animal.nom,
            treatmentName: traitement.nom,
            dateFin: traitement.dateFin!,
          );
        }
      }

      // Pesée pour les bébés
      if (animal.estBebe && animal.dernierPoids != null) {
        // Planifier une pesée hebdomadaire
        final nextWeighingDate = animal.dernierPoids!.date.add(const Duration(days: 7));
        if (nextWeighingDate.isAfter(DateTime.now())) {
          await scheduleBabyWeightReminder(
            animalId: animal.id,
            animalName: animal.nom,
            nextWeighingDate: nextWeighingDate,
          );
        }
      }
    }
  }

  // ========== Méthodes utilitaires pour générer des IDs uniques ==========

  int _generateVaccineNotificationId(String animalId, String vaccineName, int dayOffset) {
    // Générer un ID unique basé sur l'animalId, le nom du vaccin et l'offset
    final combined = '$animalId-$vaccineName-vaccine-$dayOffset';
    return combined.hashCode.abs();
  }

  int _generateTreatmentNotificationId(String animalId, String treatmentName) {
    final combined = '$animalId-$treatmentName-treatment';
    return combined.hashCode.abs();
  }

  int _generateBabyWeightNotificationId(String animalId) {
    final combined = '$animalId-weight';
    return combined.hashCode.abs();
  }

  int _generateConsultationNotificationId(String animalId, int dayOffset) {
    final combined = '$animalId-consultation-$dayOffset';
    return combined.hashCode.abs();
  }
}
