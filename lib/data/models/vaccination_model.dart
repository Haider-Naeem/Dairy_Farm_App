// lib/data/models/vaccination_model.dart
class VaccinationModel {
  final int? id;
  final int animalId;
  final String vaccineName;
  final String vaccinationDate;
  final String? nextDueDate;
  final String? givenBy;
  final String? notes;
  final String createdAt;
  final bool isDone;          // ← true once a due-date dose is marked completed

  String? animalTag;

  VaccinationModel({
    this.id,
    required this.animalId,
    required this.vaccineName,
    required this.vaccinationDate,
    this.nextDueDate,
    this.givenBy,
    this.notes,
    required this.createdAt,
    this.animalTag,
    this.isDone = false,
  });

  factory VaccinationModel.fromMap(Map<String, dynamic> map) => VaccinationModel(
        id: map['id'],
        animalId: map['animal_id'],
        vaccineName: map['vaccine_name'],
        vaccinationDate: map['vaccination_date'],
        nextDueDate: map['next_due_date'],
        givenBy: map['given_by'],
        notes: map['notes'],
        createdAt: map['created_at'],
        animalTag: map['tag_number'],
        isDone: (map['is_done'] ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'animal_id': animalId,
        'vaccine_name': vaccineName,
        'vaccination_date': vaccinationDate,
        'next_due_date': nextDueDate,
        'given_by': givenBy,
        'notes': notes,
        'created_at': createdAt,
        'is_done': isDone ? 1 : 0,
      };

  VaccinationModel copyWith({bool? isDone, String? givenBy, String? notes}) =>
      VaccinationModel(
        id: id,
        animalId: animalId,
        vaccineName: vaccineName,
        vaccinationDate: vaccinationDate,
        nextDueDate: nextDueDate,
        givenBy: givenBy ?? this.givenBy,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        animalTag: animalTag,
        isDone: isDone ?? this.isDone,
      );
}