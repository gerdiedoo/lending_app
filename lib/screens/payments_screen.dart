import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../widgets/loan_shared_widgets.dart';

/// Represents a single installment/payment record derived from a loan.
///
/// Each loan maps to one payment row:
///  - status 'Paid'    -> shown as "Paid {loanDate}"
///  - status 'Overdue' -> shown as "Due {dueDate}" (Overdue)
///  - everything else  -> shown as "Due {dueDate}" (Pending)
class PaymentEntry {
  final Loan loan;

  PaymentEntry(this.loan);

  String get borrowerName => loan.borrowerName;
  double get amount => loan.monthlyInstallment > 0 ? loan.monthlyInstallment : loan.principalAmount;

  /// Normalized status for this screen: Paid, Pending, or Overdue.
  String get status {
    if (loan.status == 'Paid') return 'Paid';
    if (loan.status == 'Overdue') return 'Overdue';
    return 'Pending';
  }

  /// The relevant date: when it was paid, or when it's due.
  DateTime get relevantDate => status == 'Paid' ? loan.loanDate : loan.dueDate;
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  String _selectedStatus = 'All';
  String _searchQuery = '';

  static const List<String> _statuses = ['All', 'Paid', 'Pending', 'Overdue'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentEntry> _filter(List<PaymentEntry> entries) {
    final filtered = entries.where((e) {
      final matchStatus = _selectedStatus == 'All' || e.status == _selectedStatus;
      final matchSearch = _searchQuery.isEmpty ||
          e.borrowerName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();

    filtered.sort((a, b) => b.relevantDate.compareTo(a.relevantDate));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Payments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
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
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase
              .from('loans')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final loans = (snapshot.data ?? []).map((j) => Loan.fromJson(j)).toList();
            final entries = loans.map((l) => PaymentEntry(l)).toList();

            // ── Summary calculations ──────────────────────────────
            final now = DateTime.now();
            final collectedThisMonth = entries
                .where((e) =>
                    e.status == 'Paid' &&
                    e.loan.loanDate.year == now.year &&
                    e.loan.loanDate.month == now.month)
                .fold(0.0, (sum, e) => sum + e.amount);

            final pendingEntries = entries.where((e) => e.status != 'Paid').toList();
            final remainingToCollect =
                pendingEntries.fold(0.0, (sum, e) => sum + e.amount);

            final filtered = _filter(entries);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Total collected this month ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL COLLECTED THIS MONTH',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${formatAmount(collectedThisMonth)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.trending_up, color: AppColors.success, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '+12% vs last month',
                              style: TextStyle(color: AppColors.success, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Remaining to collect ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REMAINING TO COLLECT',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${formatAmount(remainingToCollect)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[500], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${pendingEntries.length} pending payments',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Status filter tabs ───────────────────────────
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statuses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final s = _statuses[i];
                        final active = s == _selectedStatus;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStatus = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: active ? Colors.white : Colors.grey,
                                fontSize: 13,
                                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Search bar ────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search payments...',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, color: Colors.grey[500], size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Payments list ─────────────────────────────────
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[700]),
                            const SizedBox(height: 12),
                            Text(
                              'No payments found',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PaymentRow(entry: entry),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Payment row ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final PaymentEntry entry;

  const _PaymentRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final loan = entry.loan;
    final date = entry.relevantDate;
    final dateLabel = '${kMonthAbbr[date.month - 1]} ${date.day}, ${date.year}';
    final dateLine = entry.status == 'Paid' ? 'Paid $dateLabel' : 'Due $dateLabel';

    return GestureDetector(
      onTap: () => showLoanDetail(context, loan),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            LoanInitialsAvatar(name: loan.borrowerName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.borrowerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateLine,
                    style: TextStyle(
                      color: entry.status == 'Overdue' ? AppColors.danger : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${formatAmount(entry.amount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _PaymentStatusChip(status: entry.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment status chip (with icon) ───────────────────────────────────────────

class _PaymentStatusChip extends StatelessWidget {
  final String status;

  const _PaymentStatusChip({required this.status});

  Color get _bg {
    switch (status) {
      case 'Paid':    return const Color(0xFF1A4A2E);
      case 'Pending': return const Color(0xFF1A3A5C);
      case 'Overdue': return const Color(0xFF5C1A1A);
      default:        return Colors.grey.shade800;
    }
  }

  Color get _fg {
    switch (status) {
      case 'Paid':    return AppColors.success;
      case 'Pending': return AppColors.primary;
      case 'Overdue': return const Color(0xFFEF5350);
      default:        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'Paid':    return Icons.check_circle_outline;
      case 'Pending': return Icons.access_time;
      case 'Overdue': return Icons.warning_amber_rounded;
      default:        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}