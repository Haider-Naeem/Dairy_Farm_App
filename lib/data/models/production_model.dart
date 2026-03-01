


// ============================================================
// lib/data/models/production_model.dart
// ============================================================
class ProductionModel {
  final int? id;
  final int animalId;
  final String productionDate;
  final double morning;
  final double afternoon;
  final double evening;
  final String? notes;
  final String createdAt;

  // Joined
  String? animalTag;
  String? animalName;

  ProductionModel({
    this.id,
    required this.animalId,
    required this.productionDate,
    this.morning = 0.0,
    this.afternoon = 0.0,
    this.evening = 0.0,
    this.notes,
    required this.createdAt,
    this.animalTag,
    this.animalName,
  });

  double get total => morning + afternoon + evening;

  factory ProductionModel.fromMap(Map<String, dynamic> map) => ProductionModel(
        id: map['id'],
        animalId: map['animal_id'],
        productionDate: map['production_date'],
        morning: (map['morning'] as num).toDouble(),
        afternoon: (map['afternoon'] as num).toDouble(),
        evening: (map['evening'] as num).toDouble(),
        notes: map['notes'],
        createdAt: map['created_at'],
        animalTag: map['tag_number'],
        animalName: map['animal_name'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'animal_id': animalId,
        'production_date': productionDate,
        'morning': morning,
        'afternoon': afternoon,
        'evening': evening,
        'notes': notes,
        'created_at': createdAt,
      };
}