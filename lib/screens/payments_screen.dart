import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../widgets/loan_shared_widgets.dart';

/// A real, recorded payment transaction from the `payments` table.
class PaymentRecord {
  final String id;
  final String borrowerName;
  final double amountPaid;
  final String kind; // 'manual' | 'full' | 'interest_only'
  final DateTime paymentDate;
  final String notes;

  PaymentRecord({
    required this.id,
    required this.borrowerName,
    required this.amountPaid,
    required this.kind,
    required this.paymentDate,
    required this.notes,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'],
      borrowerName: json['borrower_name'],
      amountPaid: (json['amount_paid'] as num).toDouble(),
      kind: json['kind'] ?? 'manual',
      paymentDate: DateTime.parse(json['payment_date']),
      notes: json['notes'] ?? '',
    );
  }

  String get kindLabel {
    switch (kind) {
      case 'full':
        return 'Full Settlement';
      case 'interest_only':
        return 'Interest Only';
      default:
        return 'Payment';
    }
  }
}

/// An outstanding loan not yet fully paid, shown as a "Due" row so
/// managers can see what's still owed alongside what's already collected.
class OutstandingEntry {
  final Loan loan;

  OutstandingEntry(this.loan);

  String get borrowerName => loan.borrowerName;
  double get amount => loan.fullSettlementAmount;
  String get status => loan.status == 'Overdue' ? 'Overdue' : 'Pending';
  DateTime get dueDate => loan.dueDate;
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
          builder: (context, loanSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('payments')
                  .stream(primaryKey: ['id'])
                  .order('payment_date', ascending: false),
              builder: (context, paymentSnapshot) {
                if (loanSnapshot.connectionState == ConnectionState.waiting ||
                    paymentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final loans = (loanSnapshot.data ?? []).map((j) => Loan.fromJson(j)).toList();
                final payments =
                    (paymentSnapshot.data ?? []).map((j) => PaymentRecord.fromJson(j)).toList();

                final outstanding = loans
                    .where((l) => l.status != 'Paid')
                    .map((l) => OutstandingEntry(l))
                    .toList();

                // ── Summary calculations ──────────────────────────────
                final now = DateTime.now();
                final collectedThisMonth = payments
                    .where((p) =>
                        p.paymentDate.year == now.year && p.paymentDate.month == now.month)
                    .fold<double>(0.0, (sum, p) => sum + p.amountPaid);

                final remainingToCollect =
                    outstanding.fold<double>(0.0, (sum, e) => sum + e.amount);

                // ── Build a unified, filterable list ───────────────────
                final showPaid = _selectedStatus == 'All' || _selectedStatus == 'Paid';
                final showPending = _selectedStatus == 'All' || _selectedStatus == 'Pending';
                final showOverdue = _selectedStatus == 'All' || _selectedStatus == 'Overdue';

                final filteredPayments = showPaid
                    ? payments
                        .where((p) => _searchQuery.isEmpty ||
                            p.borrowerName.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList()
                    : <PaymentRecord>[];

                final filteredOutstanding = outstanding.where((e) {
                  final matchStatus =
                      (e.status == 'Pending' && showPending) || (e.status == 'Overdue' && showOverdue);
                  final matchSearch = _searchQuery.isEmpty ||
                      e.borrowerName.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchStatus && matchSearch;
                }).toList()
                  ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

                final hasAnyResults = filteredPayments.isNotEmpty || filteredOutstanding.isNotEmpty;

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
                                  '${outstanding.length} pending loan${outstanding.length == 1 ? '' : 's'}',
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

                      // ── List ───────────────────────────────────────────
                      if (!hasAnyResults)
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
                      else ...[
                        // Outstanding (Pending/Overdue) loans first, soonest due date on top
                        ...filteredOutstanding.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OutstandingRow(entry: entry),
                            )),
                        // Then actual recorded payment transactions, most recent first
                        ...filteredPayments.map((record) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PaymentRecordRow(record: record),
                            )),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Outstanding loan row (Pending / Overdue) ──────────────────────────────────

class _OutstandingRow extends StatelessWidget {
  final OutstandingEntry entry;

  const _OutstandingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final loan = entry.loan;
    final date = entry.dueDate;
    final dateLabel = '${kMonthAbbr[date.month - 1]} ${date.day}, ${date.year}';

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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Due $dateLabel',
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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

// ── Real payment record row ───────────────────────────────────────────────────

class _PaymentRecordRow extends StatelessWidget {
  final PaymentRecord record;

  const _PaymentRecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = record.paymentDate;
    final dateLabel = '${kMonthAbbr[date.month - 1]} ${date.day}, ${date.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          LoanInitialsAvatar(name: record.borrowerName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.borrowerName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Paid $dateLabel · ${record.kindLabel}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${formatAmount(record.amountPaid)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const _PaymentStatusChip(status: 'Paid'),
            ],
          ),
        ],
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