class Loan {
  final String id;
  final String borrowerName;
  final String borrowerPhone;
  final String lenderName;
  final double principalAmount;
  final double interestRate;
  final double monthlyInstallment;
  final String status;
  final DateTime createdAt;
  final DateTime loanDate;
  final int durationMonths;

  Loan({
    required this.id,
    required this.borrowerName,
    required this.borrowerPhone,
    required this.lenderName,
    required this.principalAmount,
    required this.interestRate,
    required this.monthlyInstallment,
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
      borrowerPhone:   json['borrower_phone'] ?? '',
      lenderName:      json['lender_name'] ?? '',
      principalAmount: (json['principal_amount'] as num).toDouble(),
      interestRate:    (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      monthlyInstallment: (json['monthly_installment'] as num?)?.toDouble() ?? 0.0,
      status:          json['status'],
      createdAt:       createdAt,
      loanDate:        loanDate,
      durationMonths:  (json['duration_months'] as num?)?.toInt() ?? 0,
    );
  }
}