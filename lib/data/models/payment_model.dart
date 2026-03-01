// lib/data/models/payment_model.dart
class PaymentModel {
  final int? id;
  final int clientId;
  final int year;
  final int month;
  final double amountPaid;
  final String paymentDate;
  final String? notes;
  final String createdAt;
  final String? clientName; // populated via JOIN in repository queries

  const PaymentModel({
    this.id,
    required this.clientId,
    required this.year,
    required this.month,
    required this.amountPaid,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    this.clientName,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
        id:          map['id'] as int?,
        clientId:    (map['client_id'] as num).toInt(),
        year:        (map['year'] as num).toInt(),
        month:       (map['month'] as num).toInt(),
        amountPaid:  (map['amount_paid'] as num).toDouble(),
        paymentDate: map['payment_date'] as String,
        notes:       map['notes'] as String?,
        createdAt:   map['created_at'] as String,
        clientName:  map['client_name'] as String?, // from JOIN, null when not joined
      );

  /// clientName is intentionally excluded — it is a derived JOIN value,
  /// not a column in the payments table.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'client_id':    clientId,
        'year':         year,
        'month':        month,
        'amount_paid':  amountPaid,
        'payment_date': paymentDate,
        'notes':        notes,
        'created_at':   createdAt,
      };
}