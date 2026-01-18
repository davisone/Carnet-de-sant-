class Animal {
  final String id;
  final String nom;
  final String espece; // chat, chien, lapin, etc.
  final String race;
  final DateTime dateNaissance;
  final String? sexe;
  final String? couleur;
  final String? numeroIdentification; // puce ou tatouage
  final String? photoPath;
  final String? pereId; // ID du père
  final String? mereId; // ID de la mère
  final List<Traitement> traitements;
  final List<Vaccin> vaccins;
  final List<ConsultationVeterinaire> consultations;
  final List<Maladie> maladies;
  final List<MesurePoids> historiquePoids;
  final String? notes;

  Animal({
    required this.id,
    required this.nom,
    required this.espece,
    required this.race,
    required this.dateNaissance,
    this.sexe,
    this.couleur,
    this.numeroIdentification,
    this.photoPath,
    this.pereId,
    this.mereId,
    this.traitements = const [],
    this.vaccins = const [],
    this.consultations = const [],
    this.maladies = const [],
    this.historiquePoids = const [],
    this.notes,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateNaissance.year;
    if (now.month < dateNaissance.month ||
        (now.month == dateNaissance.month && now.day < dateNaissance.day)) {
      age--;
    }
    return age;
  }

  // Retourne l'âge formaté avec années et mois (ex: "2 ans 3 mois")
  String get ageComplet {
    final now = DateTime.now();
    int annees = now.year - dateNaissance.year;
    int mois = now.month - dateNaissance.month;

    if (now.day < dateNaissance.day) {
      mois--;
    }

    if (mois < 0) {
      annees--;
      mois += 12;
    }

    if (annees == 0) {
      return '$mois mois';
    } else if (mois == 0) {
      return '$annees an${annees > 1 ? 's' : ''}';
    } else {
      return '$annees an${annees > 1 ? 's' : ''} $mois mois';
    }
  }

  // Vérifie si l'espèce est concernée par le suivi de poids
  bool get estEspeceSuiviePoids {
    final especesConcernees = ['chèvre', 'mouton', 'cheval'];
    return especesConcernees.contains(espece.toLowerCase());
  }

  // Détermine si l'animal est un bébé (moins de 1 an)
  // Uniquement pour chèvres, moutons et chevaux
  bool get estBebe {
    if (!estEspeceSuiviePoids) {
      return false;
    }
    return age < 1;
  }

  // Détermine si l'onglet Poids doit être affiché
  // Affiché si l'animal est un bébé OU s'il a un historique de poids
  bool get afficherOngletPoids {
    if (!estEspeceSuiviePoids) {
      return false;
    }
    return estBebe || historiquePoids.isNotEmpty;
  }

  // Détermine si on peut ajouter de nouvelles mesures de poids
  // Uniquement possible pour les bébés (< 1 an)
  bool get peutAjouterPoids => estBebe;

  // Âge en mois pour les bébés
  int get ageEnMois {
    final now = DateTime.now();
    int mois = (now.year - dateNaissance.year) * 12 + now.month - dateNaissance.month;
    if (now.day < dateNaissance.day) {
      mois--;
    }
    return mois;
  }

  // Dernière mesure de poids
  MesurePoids? get dernierPoids {
    if (historiquePoids.isEmpty) return null;
    final sorted = List<MesurePoids>.from(historiquePoids)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  List<Traitement> get traitementsEnCours {
    final now = DateTime.now();
    return traitements
        .where((t) =>
            t.dateDebut.isBefore(now) &&
            (t.dateFin == null || t.dateFin!.isAfter(now)))
        .toList();
  }

  Vaccin? get prochainVaccin {
    final now = DateTime.now();
    final vaccinsAVenir = vaccins
        .where((v) => v.dateRappel != null && v.dateRappel!.isAfter(now))
        .toList();

    if (vaccinsAVenir.isEmpty) return null;

    vaccinsAVenir.sort((a, b) => a.dateRappel!.compareTo(b.dateRappel!));
    return vaccinsAVenir.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'espece': espece,
      'race': race,
      'dateNaissance': dateNaissance.toIso8601String(),
      'sexe': sexe,
      'couleur': couleur,
      'numeroIdentification': numeroIdentification,
      'photoPath': photoPath,
      'pereId': pereId,
      'mereId': mereId,
      'traitements': traitements.map((t) => t.toJson()).toList(),
      'vaccins': vaccins.map((v) => v.toJson()).toList(),
      'consultations': consultations.map((c) => c.toJson()).toList(),
      'maladies': maladies.map((m) => m.toJson()).toList(),
      'historiquePoids': historiquePoids.map((p) => p.toJson()).toList(),
      'notes': notes,
    };
  }

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      nom: json['nom'],
      espece: json['espece'],
      race: json['race'],
      dateNaissance: DateTime.parse(json['dateNaissance']),
      sexe: json['sexe'],
      couleur: json['couleur'],
      numeroIdentification: json['numeroIdentification'],
      photoPath: json['photoPath'],
      pereId: json['pereId'],
      mereId: json['mereId'],
      traitements: (json['traitements'] as List?)
              ?.map((t) => Traitement.fromJson(t))
              .toList() ??
          [],
      vaccins: (json['vaccins'] as List?)
              ?.map((v) => Vaccin.fromJson(v))
              .toList() ??
          [],
      consultations: (json['consultations'] as List?)
              ?.map((c) => ConsultationVeterinaire.fromJson(c))
              .toList() ??
          [],
      maladies: (json['maladies'] as List?)
              ?.map((m) => Maladie.fromJson(m))
              .toList() ??
          [],
      historiquePoids: (json['historiquePoids'] as List?)
              ?.map((p) => MesurePoids.fromJson(p))
              .toList() ??
          [],
      notes: json['notes'],
    );
  }

  Animal copyWith({
    String? id,
    String? nom,
    String? espece,
    String? race,
    DateTime? dateNaissance,
    String? sexe,
    String? couleur,
    String? numeroIdentification,
    String? photoPath,
    String? pereId,
    String? mereId,
    List<Traitement>? traitements,
    List<Vaccin>? vaccins,
    List<ConsultationVeterinaire>? consultations,
    List<Maladie>? maladies,
    List<MesurePoids>? historiquePoids,
    String? notes,
  }) {
    return Animal(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      espece: espece ?? this.espece,
      race: race ?? this.race,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      sexe: sexe ?? this.sexe,
      couleur: couleur ?? this.couleur,
      numeroIdentification: numeroIdentification ?? this.numeroIdentification,
      photoPath: photoPath ?? this.photoPath,
      pereId: pereId ?? this.pereId,
      mereId: mereId ?? this.mereId,
      traitements: traitements ?? this.traitements,
      vaccins: vaccins ?? this.vaccins,
      consultations: consultations ?? this.consultations,
      maladies: maladies ?? this.maladies,
      historiquePoids: historiquePoids ?? this.historiquePoids,
      notes: notes ?? this.notes,
    );
  }
}

class Traitement {
  final String id;
  final String nom;
  final String description;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final String posologie;
  final String? notes;

  Traitement({
    required this.id,
    required this.nom,
    required this.description,
    required this.dateDebut,
    this.dateFin,
    required this.posologie,
    this.notes,
  });

  bool get estEnCours {
    final now = DateTime.now();
    return dateDebut.isBefore(now) &&
        (dateFin == null || dateFin!.isAfter(now));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'posologie': posologie,
      'notes': notes,
    };
  }

  factory Traitement.fromJson(Map<String, dynamic> json) {
    return Traitement(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      dateDebut: DateTime.parse(json['dateDebut']),
      dateFin: json['dateFin'] != null ? DateTime.parse(json['dateFin']) : null,
      posologie: json['posologie'],
      notes: json['notes'],
    );
  }
}

class Vaccin {
  final String id;
  final String nom;
  final DateTime dateAdministration;
  final DateTime? dateRappel;
  final String? numeroLot;
  final String? veterinaire;
  final String? notes;

  Vaccin({
    required this.id,
    required this.nom,
    required this.dateAdministration,
    this.dateRappel,
    this.numeroLot,
    this.veterinaire,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'dateAdministration': dateAdministration.toIso8601String(),
      'dateRappel': dateRappel?.toIso8601String(),
      'numeroLot': numeroLot,
      'veterinaire': veterinaire,
      'notes': notes,
    };
  }

  factory Vaccin.fromJson(Map<String, dynamic> json) {
    return Vaccin(
      id: json['id'],
      nom: json['nom'],
      dateAdministration: DateTime.parse(json['dateAdministration']),
      dateRappel:
          json['dateRappel'] != null ? DateTime.parse(json['dateRappel']) : null,
      numeroLot: json['numeroLot'],
      veterinaire: json['veterinaire'],
      notes: json['notes'],
    );
  }
}

class ConsultationVeterinaire {
  final String id;
  final DateTime date;
  final String motif;
  final String diagnostic;
  final String veterinaire;
  final double? poids;
  final String? traitement;
  final String? notes;

  ConsultationVeterinaire({
    required this.id,
    required this.date,
    required this.motif,
    required this.diagnostic,
    required this.veterinaire,
    this.poids,
    this.traitement,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'motif': motif,
      'diagnostic': diagnostic,
      'veterinaire': veterinaire,
      'poids': poids,
      'traitement': traitement,
      'notes': notes,
    };
  }

  factory ConsultationVeterinaire.fromJson(Map<String, dynamic> json) {
    return ConsultationVeterinaire(
      id: json['id'],
      date: DateTime.parse(json['date']),
      motif: json['motif'],
      diagnostic: json['diagnostic'],
      veterinaire: json['veterinaire'],
      poids: json['poids']?.toDouble(),
      traitement: json['traitement'],
      notes: json['notes'],
    );
  }
}

class Maladie {
  final String id;
  final String nom;
  final DateTime dateDiagnostic;
  final String? description;
  final bool estChronique;
  final bool estGuerite;
  final DateTime? dateGuerison;
  final String? traitement;
  final String? notes;

  Maladie({
    required this.id,
    required this.nom,
    required this.dateDiagnostic,
    this.description,
    this.estChronique = false,
    this.estGuerite = false,
    this.dateGuerison,
    this.traitement,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'dateDiagnostic': dateDiagnostic.toIso8601String(),
      'description': description,
      'estChronique': estChronique,
      'estGuerite': estGuerite,
      'dateGuerison': dateGuerison?.toIso8601String(),
      'traitement': traitement,
      'notes': notes,
    };
  }

  factory Maladie.fromJson(Map<String, dynamic> json) {
    return Maladie(
      id: json['id'],
      nom: json['nom'],
      dateDiagnostic: DateTime.parse(json['dateDiagnostic']),
      description: json['description'],
      estChronique: json['estChronique'] ?? false,
      estGuerite: json['estGuerite'] ?? false,
      dateGuerison: json['dateGuerison'] != null
          ? DateTime.parse(json['dateGuerison'])
          : null,
      traitement: json['traitement'],
      notes: json['notes'],
    );
  }
}

class MesurePoids {
  final String id;
  final DateTime date;
  final double poids; // en kg
  final String? notes;

  MesurePoids({
    required this.id,
    required this.date,
    required this.poids,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'poids': poids,
      'notes': notes,
    };
  }

  factory MesurePoids.fromJson(Map<String, dynamic> json) {
    return MesurePoids(
      id: json['id'],
      date: DateTime.parse(json['date']),
      poids: json['poids'].toDouble(),
      notes: json['notes'],
    );
  }
}

class Saillie {
  final String id;
  final String mereId; // ID de la mère
  final String pereId; // ID du père
  final DateTime dateSaillie;
  final String type; // 'naturelle' ou 'artificielle'
  final String statut; // 'en_attente', 'reussie', 'echouee'
  final DateTime? dateMiseBas;
  final int? nombreBebes;
  final List<String> bebesIds; // IDs des bébés nés
  final String? notes;

  Saillie({
    required this.id,
    required this.mereId,
    required this.pereId,
    required this.dateSaillie,
    required this.type,
    this.statut = 'en_attente',
    this.dateMiseBas,
    this.nombreBebes,
    this.bebesIds = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mereId': mereId,
      'pereId': pereId,
      'dateSaillie': dateSaillie.toIso8601String(),
      'type': type,
      'statut': statut,
      'dateMiseBas': dateMiseBas?.toIso8601String(),
      'nombreBebes': nombreBebes,
      'bebesIds': bebesIds,
      'notes': notes,
    };
  }

  factory Saillie.fromJson(Map<String, dynamic> json) {
    return Saillie(
      id: json['id'],
      mereId: json['mereId'],
      pereId: json['pereId'],
      dateSaillie: DateTime.parse(json['dateSaillie']),
      type: json['type'],
      statut: json['statut'] ?? 'en_attente',
      dateMiseBas: json['dateMiseBas'] != null
          ? DateTime.parse(json['dateMiseBas'])
          : null,
      nombreBebes: json['nombreBebes'],
      bebesIds: (json['bebesIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'],
    );
  }

  Saillie copyWith({
    String? id,
    String? mereId,
    String? pereId,
    DateTime? dateSaillie,
    String? type,
    String? statut,
    DateTime? dateMiseBas,
    int? nombreBebes,
    List<String>? bebesIds,
    String? notes,
  }) {
    return Saillie(
      id: id ?? this.id,
      mereId: mereId ?? this.mereId,
      pereId: pereId ?? this.pereId,
      dateSaillie: dateSaillie ?? this.dateSaillie,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      dateMiseBas: dateMiseBas ?? this.dateMiseBas,
      nombreBebes: nombreBebes ?? this.nombreBebes,
      bebesIds: bebesIds ?? this.bebesIds,
      notes: notes ?? this.notes,
    );
  }
}
