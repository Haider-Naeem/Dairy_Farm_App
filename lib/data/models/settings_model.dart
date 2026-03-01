





// ============================================================
// lib/data/models/settings_model.dart
// ============================================================
class SettingsModel {
  final int? id;
  final String farmName;
  final double ratePerLiter;
  final String? ownerName;
  final String? phone;
  final String? address;
  final String updatedAt;

  SettingsModel({
    this.id,
    required this.farmName,
    required this.ratePerLiter,
    this.ownerName,
    this.phone,
    this.address,
    required this.updatedAt,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) => SettingsModel(
        id: map['id'],
        farmName: map['farm_name'],
        ratePerLiter: (map['rate_per_liter'] as num).toDouble(),
        ownerName: map['owner_name'],
        phone: map['phone'],
        address: map['address'],
        updatedAt: map['updated_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'farm_name': farmName,
        'rate_per_liter': ratePerLiter,
        'owner_name': ownerName,
        'phone': phone,
        'address': address,
        'updated_at': updatedAt,
      };
}