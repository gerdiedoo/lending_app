class Loan {
  final String id;
  final String borrowerName;
  final String lenderName;
  final double principalAmount;
  final String status;
  final DateTime createdAt;
  final int durationMonths;

  Loan({
    required this.id,
    required this.borrowerName,
    required this.lenderName,
    required this.principalAmount,
    required this.status,
    required this.createdAt,
    required this.durationMonths,
  });

  /// The date by which the loan should be fully repaid.
  DateTime get dueDate {
    final m = createdAt.month + durationMonths;
    return DateTime(createdAt.year + (m - 1) ~/ 12, ((m - 1) % 12) + 1, createdAt.day);
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      borrowerName: json['borrower_name'],
      lenderName: json['lender_name'] ?? '',
      principalAmount: (json['principal_amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      durationMonths: (json['duration_months'] as num?)?.toInt() ?? 0,
    );
  }
}