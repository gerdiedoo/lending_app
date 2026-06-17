import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../widgets/loan_shared_widgets.dart';
import 'borrowers_screen.dart';
import '../widgets/record_payment_dialog.dart';

class BorrowerDetailScreen extends StatelessWidget {
  final BorrowerSummary borrower;

  const BorrowerDetailScreen({super.key, required this.borrower});

  String get _joinedLabel {
    final joined = borrower.loans
        .map((l) => l.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return '${kMonthAbbr[joined.month - 1]} ${joined.year}';
  }

  String get _phone {
    for (final loan in borrower.loans) {
      if (loan.borrowerPhone.isNotEmpty) return loan.borrowerPhone;
    }
    return '';
  }

  /// Simple heuristic credit score derived from the borrower's loan
  /// history: starts at 700 and is adjusted based on the proportion of
  /// loans that are Paid (good) vs Overdue (bad).
  int get _creditScore {
    final total = borrower.loans.length;
    if (total == 0) return 700;
    final paid = borrower.loans.where((l) => l.status == 'Paid').length;
    final overdue = borrower.loans.where((l) => l.status == 'Overdue').length;
    final score = 700 + (paid * 20) - (overdue * 40);
    return score.clamp(300, 850);
  }

  String get _creditLabel {
    final score = _creditScore;
    if (score >= 740) return 'Excellent';
    if (score >= 670) return 'Good';
    if (score >= 580) return 'Fair';
    return 'Poor';
  }

  Color get _creditColor {
    final score = _creditScore;
    if (score >= 670) return AppColors.success;
    if (score >= 580) return const Color(0xFFFFB300);
    return AppColors.danger;
  }

  Future<void> _call(BuildContext context) async {
    if (_phone.isEmpty) {
      _showNoPhoneMessage(context);
      return;
    }
    final uri = Uri(scheme: 'tel', path: _phone);
    if (!await launchUrl(uri)) {
      _showNoPhoneMessage(context);
    }
  }

  Future<void> _message(BuildContext context) async {
    if (_phone.isEmpty) {
      _showNoPhoneMessage(context);
      return;
    }
    final uri = Uri(scheme: 'sms', path: _phone);
    if (!await launchUrl(uri)) {
      _showNoPhoneMessage(context);
    }
  }

  void _showNoPhoneMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No phone number on file for this borrower'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLoans = borrower.loans.where((l) => l.status == 'Active').toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Borrower Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + name + joined date ───────────────────────
              Center(
                child: Column(
                  children: [
                    LoanInitialsAvatar(name: borrower.name, radius: 44),
                    const SizedBox(height: 16),
                    Text(
                      borrower.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined $_joinedLabel',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // ── Call / message buttons ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircleIconButton(
                          icon: Icons.call_outlined,
                          onTap: () => _call(context),
                        ),
                        const SizedBox(width: 16),
                        _CircleIconButton(
                          icon: Icons.chat_bubble_outline,
                          onTap: () => _message(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Record Payment button ─────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showRecordPaymentDialog(context, borrower),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    'Record Payment',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Total outstanding card ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Outstanding',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₱${formatAmount(borrower.totalOutstanding)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Total loans + credit score cards ──────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.description_outlined, color: Colors.grey[400], size: 20),
                          const SizedBox(height: 10),
                          Text(
                            'Total Loans',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${borrower.totalLoanCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_outlined, color: _creditColor, size: 20),
                          const SizedBox(height: 10),
                          Text(
                            'Credit Score',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_creditScore',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _creditLabel,
                                style: TextStyle(
                                  color: _creditColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Active loans ───────────────────────────────────────
              const Text(
                'Active Loans',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (activeLoans.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No active loans',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                )
              else
                ...activeLoans.map((loan) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActiveLoanRow(
                        loan: loan,
                        onTap: () => showLoanDetail(context, loan),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Circle icon button ───────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Active loan row ───────────────────────────────────────────────────────────

class _ActiveLoanRow extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;

  const _ActiveLoanRow({required this.loan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final due = loan.dueDate;
    final dueLabel = '${kMonthAbbr[due.month - 1]} ${due.day}';
    final rollovers = loan.interestCyclesPaid;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${formatAmount(loan.principalAmount)} principal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Due $dueLabel · ₱${formatAmount(loan.fullSettlementAmount)} to settle'
                    '${rollovers > 0 ? ' · rolled over $rollovers×' : ''}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            LoanStatusBadge(status: loan.status),
          ],
        ),
      ),
    );
  }
}