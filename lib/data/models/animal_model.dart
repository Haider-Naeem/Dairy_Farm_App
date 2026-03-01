// lib/data/models/animal_model.dart
class AnimalModel {
  final int? id;
  final String tagNumber;
  final String? name;
  final String? breed;
  final String? dateOfBirth;
  final String gender;
  final int? motherId;
  final String? fatherTag;
  final String? purchaseDate;
  final double? purchasePrice;
  final bool isActive;
  final bool inProduction; // true = show in production tab
  final String? notes;
  final String createdAt;

  AnimalModel({
    this.id,
    required this.tagNumber,
    this.name,
    this.breed,
    this.dateOfBirth,
    this.gender = 'Female',
    this.motherId,
    this.fatherTag,
    this.purchaseDate,
    this.purchasePrice,
    this.isActive = true,
    bool? inProduction,
    this.notes,
    required this.createdAt,
  }) : inProduction = inProduction ?? (motherId == null);
  // Non-calves default to inProduction=true; calves default to false
  // until explicitly added to production.

  int? get ageInMonths {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return null;
    final now = DateTime.now();
    return (now.year - dob.year) * 12 + (now.month - dob.month);
  }

  bool get isCalf => motherId != null;

  factory AnimalModel.fromMap(Map<String, dynamic> map) => AnimalModel(
        id: map['id'],
        tagNumber: map['tag_number'],
        name: map['name'],
        breed: map['breed'],
        dateOfBirth: map['date_of_birth'],
        gender: map['gender'] ?? 'Female',
        motherId: map['mother_id'],
        fatherTag: map['father_tag'],
        purchaseDate: map['purchase_date'],
        purchasePrice: map['purchase_price'] != null
            ? (map['purchase_price'] as num).toDouble()
            : null,
        isActive: map['is_active'] == 1,
        inProduction: map['in_production'] != null
            ? map['in_production'] == 1
            : map['mother_id'] == null, // fallback if column missing
        notes: map['notes'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tag_number': tagNumber,
        'name': name,
        'breed': breed,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'mother_id': motherId,
        'father_tag': fatherTag,
        'purchase_date': purchaseDate,
        'purchase_price': purchasePrice,
        'is_active': isActive ? 1 : 0,
        'in_production': inProduction ? 1 : 0,
        'notes': notes,
        'created_at': createdAt,
      };

  AnimalModel copyWith({
    int? id,
    String? tagNumber,
    String? name,
    String? breed,
    String? dateOfBirth,
    String? gender,
    int? motherId,
    String? fatherTag,
    String? purchaseDate,
    double? purchasePrice,
    bool? isActive,
    bool? inProduction,
    String? notes,
    String? createdAt,
  }) =>
      AnimalModel(
        id: id ?? this.id,
        tagNumber: tagNumber ?? this.tagNumber,
        name: name ?? this.name,
        breed: breed ?? this.breed,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        motherId: motherId ?? this.motherId,
        fatherTag: fatherTag ?? this.fatherTag,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        isActive: isActive ?? this.isActive,
        inProduction: inProduction ?? this.inProduction,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}