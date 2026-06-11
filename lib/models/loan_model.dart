class Loan {
  final String id;
  final String borrowerName;
  final String lenderName;
  final double principalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime loanDate;
  final int durationMonths;

  Loan({
    required this.id,
    required this.borrowerName,
    required this.lenderName,
    required this.principalAmount,
    required this.status,
    required this.createdAt,
    required this.loanDate,
    required this.durationMonths,
  });

  /// The date by which the loan should be fully repaid.
  /// Calculated from loanDate + durationMonths.
  DateTime get dueDate {
    final m = loanDate.month + durationMonths;
    return DateTime(loanDate.year + (m - 1) ~/ 12, ((m - 1) % 12) + 1, loanDate.day);
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at']);
    // loan_date is the new editable column; fall back to created_at for old rows
    final loanDate = json['loan_date'] != null
        ? DateTime.parse(json['loan_date'])
        : createdAt;

    return Loan(
      id:              json['id'],
      borrowerName:    json['borrower_name'],
      lenderName:      json['lender_name'] ?? '',
      principalAmount: (json['principal_amount'] as num).toDouble(),
      status:          json['status'],
      createdAt:       createdAt,
      loanDate:        loanDate,
      durationMonths:  (json['duration_months'] as num?)?.toInt() ?? 0,
    );
  }
}