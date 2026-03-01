// lib/data/models/client_model.dart
class ClientModel {
  final int? id;
  final String name;
  final String? phone;
  final double allocatedLiters;
  final bool isActive;
  final bool isPayer; // false = milk is deducted but not billed
  final String createdAt;
  final int sortOrder;

  ClientModel({
    this.id,
    required this.name,
    this.phone,
    required this.allocatedLiters,
    this.isActive = true,
    this.isPayer = true,
    required this.createdAt,
    this.sortOrder = 0,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        allocatedLiters: (map['allocated_liters'] as num).toDouble(),
        isActive: map['is_active'] == 1,
        isPayer: (map['is_payer'] as int? ?? 1) == 1,
        createdAt: map['created_at'],
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'allocated_liters': allocatedLiters,
        'is_active': isActive ? 1 : 0,
        'is_payer': isPayer ? 1 : 0,
        'created_at': createdAt,
        'sort_order': sortOrder,
      };

  ClientModel copyWith({
    int? id,
    String? name,
    String? phone,
    double? allocatedLiters,
    bool? isActive,
    bool? isPayer,
    int? sortOrder,
  }) =>
      ClientModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        allocatedLiters: allocatedLiters ?? this.allocatedLiters,
        isActive: isActive ?? this.isActive,
        isPayer: isPayer ?? this.isPayer,
        createdAt: createdAt,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}