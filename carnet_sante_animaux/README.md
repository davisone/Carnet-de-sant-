# Carnet de Santé Animaux

Application Flutter pour gérer les carnets de santé des animaux de compagnie.

## Fonctionnalités

### Gestion des animaux
- Ajouter un nouvel animal avec ses informations (nom, espèce, race, date de naissance, etc.)
- Modifier les informations d'un animal
- Supprimer un animal
- Visualiser l'âge automatiquement calculé

### Traitements
- Ajouter des traitements médicaux avec dates de début et fin
- Visualiser les traitements en cours
- Voir l'historique complet des traitements
- Filtrer les animaux ayant des traitements en cours

### Vaccins
- Enregistrer les vaccins administrés
- Planifier les rappels de vaccins
- Recevoir des alertes visuelles pour les vaccins à venir
- Voir les vaccins par ordre chronologique

### Consultations vétérinaires
- Enregistrer les consultations avec diagnostic
- Suivre l'évolution du poids
- Conserver l'historique médical complet

## Installation

1. Assurez-vous d'avoir Flutter installé sur votre machine
2. Clonez ce projet
3. Installez les dépendances :
```bash
flutter pub get
```

## Lancer l'application

### Sur Android
```bash
flutter run
```

### Sur Chrome (web)
```bash
flutter run -d chrome
```

## Structure du projet

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── models/
│   └── animal.dart             # Modèles de données (Animal, Traitement, Vaccin, Consultation)
├── services/
│   └── animal_service.dart     # Service de gestion des données (stockage local)
└── screens/
    ├── home_screen.dart        # Écran principal avec liste des animaux
    ├── add_animal_screen.dart  # Écran d'ajout/modification d'un animal
    └── animal_detail_screen.dart # Écran de détails avec onglets
```

## Dépendances

- `shared_preferences` : Stockage local des données
- `uuid` : Génération d'identifiants uniques
- `intl` : Formatage des dates

## Fonctionnement

### Stockage des données
Les données sont stockées localement sur l'appareil en utilisant `shared_preferences`. Cela signifie que :
- Les données persistent entre les sessions
- Aucune connexion internet n'est requise
- Les données sont propres à chaque appareil

### Navigation
L'application utilise 3 onglets principaux :
1. **Tous** : Liste complète de tous les animaux
2. **Traitements** : Animaux ayant des traitements en cours
3. **Vaccins** : Animaux ayant des vaccins à venir

### Détails d'un animal
Chaque animal possède 4 onglets :
1. **Infos** : Informations générales
2. **Traitements** : Liste des traitements (en cours et historique)
3. **Vaccins** : Liste des vaccins avec rappels
4. **Consultations** : Historique des visites chez le vétérinaire

## Prochaines améliorations possibles

- Ajout de photos pour les animaux
- Notifications push pour les rappels de vaccins
- Export des données en PDF
- Synchronisation cloud
- Graphiques d'évolution du poids
- Partage de fiches entre utilisateurs (famille)
- Mode sombre
