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
  final DateTime? currentDueDate;
  final int interestCyclesPaid;

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
    this.currentDueDate,
    this.interestCyclesPaid = 0,
  });

  /// The amount due for a single interest-only ("rollover") payment:
  /// the borrower pays just this cycle's interest, the principal stays
  /// the same, and the due date moves forward one month.
  double get interestOnlyAmount => principalAmount * (interestRate / 100);

  /// The amount due to fully settle the loan this cycle: principal plus
  /// the current cycle's interest.
  double get fullSettlementAmount => principalAmount + interestOnlyAmount;

  /// The next date this loan is due. Uses the rolling `current_due_date`
  /// if the DB has one (set on creation and advanced by each interest-only
  /// payment); falls back to the original loanDate + durationMonths
  /// calculation for legacy rows that predate this column.
  DateTime get dueDate {
    if (currentDueDate != null) return currentDueDate!;
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
      currentDueDate:  json['current_due_date'] != null
          ? DateTime.parse(json['current_due_date'])
          : null,
      interestCyclesPaid: (json['interest_cycles_paid'] as num?)?.toInt() ?? 0,
    );
  }
}