// ============================================================
// lib/data/models/expense_model.dart
// ============================================================
class ExpenseModel {
  final int? id;
  final String expenseDate;
  final String category;
  final String? description;
  final double amount;
  final String createdAt;

  ExpenseModel({
    this.id,
    required this.expenseDate,
    required this.category,
    this.description,
    required this.amount,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
        id: map['id'],
        expenseDate: map['expense_date'],
        category: map['category'],
        description: map['description'],
        amount: (map['amount'] as num).toDouble(),
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'expense_date': expenseDate,
        'category': category,
        'description': description,
        'amount': amount,
        'created_at': createdAt,
      };
}