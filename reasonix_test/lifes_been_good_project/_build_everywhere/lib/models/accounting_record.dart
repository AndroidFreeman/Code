class AccountingRecord {
  final String id;
  final String studentId;
  final double amount;
  final int type; // 0 for income, 1 for expense
  final String category;
  final String description;
  final String timestamp;

  const AccountingRecord({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.timestamp,
  });

  factory AccountingRecord.fromJson(Map<String, dynamic> json) {
    return AccountingRecord(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: int.tryParse(json['type']?.toString() ?? '1') ?? 1,
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'timestamp': timestamp,
    };
  }
}
