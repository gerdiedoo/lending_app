class Loan {
  final String id;
  final String borrowerName;
  final double principalAmount;
  final String status;
  final DateTime createdAt;

  Loan({
    required this.id,
    required this.borrowerName,
    required this.principalAmount,
    required this.status,
    required this.createdAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      borrowerName: json['borrower_name'],
      principalAmount: (json['principal_amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}