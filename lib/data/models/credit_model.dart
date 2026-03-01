// lib/data/models/credit_model.dart

class CreditModel {
  final int? id;
  final String personName;
  final String? phone;

  /// 'credit' = person owes us (took milk, not paid yet)
  /// 'debit'  = person paid (reduces their balance)
  final String entryType;

  final double amount;
  final double liters;
  final String? description;
  final String entryDate;
  final String createdAt;

  CreditModel({
    this.id,
    required this.personName,
    this.phone,
    required this.entryType,
    required this.amount,
    this.liters = 0.0,
    this.description,
    required this.entryDate,
    required this.createdAt,
  });

  bool get isCredit => entryType == 'credit';
  bool get isDebit  => entryType == 'debit';

  factory CreditModel.fromMap(Map<String, dynamic> map) => CreditModel(
        id: map['id'],
        personName: map['person_name'],
        phone: map['phone'],
        entryType: map['entry_type'],
        amount: (map['amount'] as num).toDouble(),
        liters: (map['liters'] as num? ?? 0).toDouble(),
        description: map['description'],
        entryDate: map['entry_date'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'person_name': personName,
        'phone': phone,
        'entry_type': entryType,
        'amount': amount,
        'liters': liters,
        'description': description,
        'entry_date': entryDate,
        'created_at': createdAt,
      };

  CreditModel copyWith({
    int? id,
    String? personName,
    String? phone,
    String? entryType,
    double? amount,
    double? liters,
    String? description,
    String? entryDate,
  }) =>
      CreditModel(
        id: id ?? this.id,
        personName: personName ?? this.personName,
        phone: phone ?? this.phone,
        entryType: entryType ?? this.entryType,
        amount: amount ?? this.amount,
        liters: liters ?? this.liters,
        description: description ?? this.description,
        entryDate: entryDate ?? this.entryDate,
        createdAt: createdAt,
      );
}