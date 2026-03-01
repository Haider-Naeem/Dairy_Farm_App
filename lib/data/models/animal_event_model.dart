// lib/data/models/animal_event_model.dart

/// Supported event types for dairy farm management.
enum AnimalEventType {
  // ── Reproduction ──────────────────────────────────────────────────────────
  heat,               // Heat / Estrus detection
  insemination,       // AI or natural breeding
  breedingDate,       // Confirmed breeding date
  pregnancyCheck,     // Pregnancy diagnosis (PD)
  expectedDelivery,   // Estimated calving date
  delivery,           // Actual calving / parturition
  birth,              // Calf birth record (linked to calf)

  // ── Lactation ─────────────────────────────────────────────────────────────
  lactationStart,     // First milking after calving
  dryOff,             // Start of dry period
  lactationEnd,       // End of lactation

  // ── Health ────────────────────────────────────────────────────────────────
  illness,
  treatment,          // Medication / treatment
  deworming,          // Antiparasitic treatment
  vaccination,        // Quick note (detailed records in vaccinations tab)
  surgery,
  injury,

  // ── Monitoring ────────────────────────────────────────────────────────────
  weightCheck,
  milkTest,           // Milk quality / mastitis / SCC test
  bodyConditionScore, // BCS assessment
  heatDetection,      // Estrus observation log

  other;

  String get label {
    switch (this) {
      // Reproduction
      case AnimalEventType.heat:              return 'Heat / Estrus';
      case AnimalEventType.insemination:      return 'Insemination / Breeding';
      case AnimalEventType.breedingDate:      return 'Breeding Date';
      case AnimalEventType.pregnancyCheck:    return 'Pregnancy Check (PD)';
      case AnimalEventType.expectedDelivery:  return 'Expected Delivery Date';
      case AnimalEventType.delivery:          return 'Delivery / Calving';
      case AnimalEventType.birth:             return 'Birth Record';
      // Lactation
      case AnimalEventType.lactationStart:    return 'Lactation Start';
      case AnimalEventType.dryOff:            return 'Dry Off';
      case AnimalEventType.lactationEnd:      return 'Lactation End';
      // Health
      case AnimalEventType.illness:           return 'Illness';
      case AnimalEventType.treatment:         return 'Treatment / Medication';
      case AnimalEventType.deworming:         return 'Deworming';
      case AnimalEventType.vaccination:       return 'Vaccination Note';
      case AnimalEventType.surgery:           return 'Surgery';
      case AnimalEventType.injury:            return 'Injury';
      // Monitoring
      case AnimalEventType.weightCheck:       return 'Weight Check';
      case AnimalEventType.milkTest:          return 'Milk Test';
      case AnimalEventType.bodyConditionScore:return 'Body Condition Score';
      case AnimalEventType.heatDetection:     return 'Heat Detection Log';
      case AnimalEventType.other:             return 'Other';
    }
  }

  /// Icon to show in the UI for each type.
  String get emoji {
    switch (this) {
      case AnimalEventType.heat:
      case AnimalEventType.heatDetection:     return '🌡️';
      case AnimalEventType.insemination:
      case AnimalEventType.breedingDate:      return '🔬';
      case AnimalEventType.pregnancyCheck:    return '🤰';
      case AnimalEventType.expectedDelivery:  return '📅';
      case AnimalEventType.delivery:
      case AnimalEventType.birth:             return '🐄';
      case AnimalEventType.lactationStart:    return '🥛';
      case AnimalEventType.dryOff:
      case AnimalEventType.lactationEnd:      return '⏹️';
      case AnimalEventType.illness:
      case AnimalEventType.injury:            return '🤒';
      case AnimalEventType.treatment:
      case AnimalEventType.surgery:           return '💊';
      case AnimalEventType.deworming:         return '🧪';
      case AnimalEventType.vaccination:       return '💉';
      case AnimalEventType.weightCheck:       return '⚖️';
      case AnimalEventType.milkTest:          return '🧫';
      case AnimalEventType.bodyConditionScore:return '📊';
      case AnimalEventType.other:             return '📝';
    }
  }

  /// Category grouping for the dropdown.
  static const Map<String, List<AnimalEventType>> groups = {
    'Reproduction': [
      AnimalEventType.heat,
      AnimalEventType.insemination,
      AnimalEventType.breedingDate,
      AnimalEventType.pregnancyCheck,
      AnimalEventType.expectedDelivery,
      AnimalEventType.delivery,
      AnimalEventType.birth,
    ],
    'Lactation': [
      AnimalEventType.lactationStart,
      AnimalEventType.dryOff,
      AnimalEventType.lactationEnd,
    ],
    'Health': [
      AnimalEventType.illness,
      AnimalEventType.treatment,
      AnimalEventType.deworming,
      AnimalEventType.vaccination,
      AnimalEventType.surgery,
      AnimalEventType.injury,
    ],
    'Monitoring': [
      AnimalEventType.weightCheck,
      AnimalEventType.milkTest,
      AnimalEventType.bodyConditionScore,
      AnimalEventType.heatDetection,
      AnimalEventType.other,
    ],
  };

  static AnimalEventType fromString(String s) {
    return AnimalEventType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AnimalEventType.other,
    );
  }
}

class AnimalEventModel {
  final int? id;
  final int animalId;
  final AnimalEventType eventType;
  final String eventDate;   // yyyy-MM-dd
  final String title;
  final String? description;
  final String? result;     // e.g. 'Positive', 'Negative', weight value, etc.
  final String? notes;
  final String createdAt;

  // Joined
  String? animalTag;
  String? animalName;

  AnimalEventModel({
    this.id,
    required this.animalId,
    required this.eventType,
    required this.eventDate,
    required this.title,
    this.description,
    this.result,
    this.notes,
    required this.createdAt,
    this.animalTag,
    this.animalName,
  });

  factory AnimalEventModel.fromMap(Map<String, dynamic> map) => AnimalEventModel(
        id: map['id'],
        animalId: map['animal_id'],
        eventType: AnimalEventType.fromString(map['event_type'] ?? 'other'),
        eventDate: map['event_date'],
        title: map['title'],
        description: map['description'],
        result: map['result'],
        notes: map['notes'],
        createdAt: map['created_at'],
        animalTag: map['tag_number'],
        animalName: map['animal_name'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'animal_id': animalId,
        'event_type': eventType.name,
        'event_date': eventDate,
        'title': title,
        'description': description,
        'result': result,
        'notes': notes,
        'created_at': createdAt,
      };
}