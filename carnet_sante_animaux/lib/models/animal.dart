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
