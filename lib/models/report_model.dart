class ReportData {
  final double totalPrincipal;
  final double totalInterestEarned;
  final double projectedRevenue;
  final double collectionRate;

  final int activeLoans;
  final int paidLoans;
  final int overdueLoans;
  final int pendingLoans;

  const ReportData({
    required this.totalPrincipal,
    required this.totalInterestEarned,
    required this.projectedRevenue,
    required this.collectionRate,
    required this.activeLoans,
    required this.paidLoans,
    required this.overdueLoans,
    required this.pendingLoans,
  });
}