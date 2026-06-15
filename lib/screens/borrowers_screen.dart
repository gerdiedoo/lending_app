import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../widgets/loan_shared_widgets.dart';
import 'borrower_detail_screen.dart';

/// Aggregated view of all loans belonging to a single borrower.
class BorrowerSummary {
  final String name;
  final List<Loan> loans;

  BorrowerSummary({required this.name, required this.loans});

  int get activeLoanCount => loans.where((l) => l.status == 'Active').length;
  int get overdueCount => loans.where((l) => l.status == 'Overdue').length;
  int get totalLoanCount => loans.length;

  /// Sum of principal for loans that are still outstanding
  /// (i.e. not fully Paid).
  double get totalOutstanding => loans
      .where((l) => l.status != 'Paid')
      .fold(0.0, (sum, l) => sum + l.principalAmount);

  /// Most recent activity across all of this borrower's loans.
  DateTime get lastActivity =>
      loans.map((l) => l.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

  /// Overall badge status: Overdue > Pending > Active > Paid.
  String get overallStatus {
    if (loans.any((l) => l.status == 'Overdue')) return 'Overdue';
    if (loans.any((l) => l.status == 'Pending')) return 'Pending';
    if (loans.any((l) => l.status == 'Active')) return 'Active';
    return 'Paid';
  }

  /// Subtitle text shown under the borrower's name, e.g.
  /// "2 Active Loans" or "3 Loans • 1 Overdue".
  String get subtitle {
    if (overdueCount > 0) {
      return '$totalLoanCount ${totalLoanCount == 1 ? 'Loan' : 'Loans'} • $overdueCount Overdue';
    }
    if (activeLoanCount > 0) {
      return '$activeLoanCount Active ${activeLoanCount == 1 ? 'Loan' : 'Loans'}';
    }
    return '0 Active Loans';
  }
}

enum BorrowerSort {
  recentActivity,
  nameAZ,
  nameZA,
  amountHigh,
  amountLow,
}

extension BorrowerSortLabel on BorrowerSort {
  String get label {
    switch (this) {
      case BorrowerSort.recentActivity:
        return 'Recent Activity';
      case BorrowerSort.nameAZ:
        return 'Name (A-Z)';
      case BorrowerSort.nameZA:
        return 'Name (Z-A)';
      case BorrowerSort.amountHigh:
        return 'Outstanding (High to Low)';
      case BorrowerSort.amountLow:
        return 'Outstanding (Low to High)';
    }
  }

  IconData get icon {
    switch (this) {
      case BorrowerSort.recentActivity:
        return Icons.access_time;
      case BorrowerSort.nameAZ:
      case BorrowerSort.nameZA:
        return Icons.sort_by_alpha;
      case BorrowerSort.amountHigh:
      case BorrowerSort.amountLow:
        return Icons.payments_outlined;
    }
  }
}

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key});

  @override
  State<BorrowersScreen> createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  String _selectedStatus = 'All';
  String _searchQuery = '';
  BorrowerSort _sort = BorrowerSort.recentActivity;

  static const List<String> _statuses = ['All', 'Active', 'Overdue', 'Paid'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BorrowerSummary> _groupByBorrower(List<Loan> loans) {
    final Map<String, List<Loan>> grouped = {};
    for (final loan in loans) {
      grouped.putIfAbsent(loan.borrowerName, () => []).add(loan);
    }
    return grouped.entries
        .map((e) => BorrowerSummary(name: e.key, loans: e.value))
        .toList();
  }

  List<BorrowerSummary> _filterAndSort(List<BorrowerSummary> borrowers) {
    final filtered = borrowers.where((b) {
      final matchStatus = _selectedStatus == 'All' || b.overallStatus == _selectedStatus;
      final matchSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case BorrowerSort.recentActivity:
          return b.lastActivity.compareTo(a.lastActivity);
        case BorrowerSort.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case BorrowerSort.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case BorrowerSort.amountHigh:
          return b.totalOutstanding.compareTo(a.totalOutstanding);
        case BorrowerSort.amountLow:
          return a.totalOutstanding.compareTo(b.totalOutstanding);
      }
    });

    return filtered;
  }

  bool get _hasActiveFilters => _selectedStatus != 'All' || _sort != BorrowerSort.recentActivity;

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedStatus = 'All';
                            _sort = BorrowerSort.recentActivity;
                          });
                          setState(() {});
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Status section ───────────────────────────────
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((s) {
                      final active = s == _selectedStatus;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => _selectedStatus = s);
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.background,
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
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Sort section ─────────────────────────────────
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...BorrowerSort.values.map((sort) {
                    final active = sort == _sort;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => _sort = sort);
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? AppColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sort.icon,
                              size: 18,
                              color: active ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              sort.label,
                              style: TextStyle(
                                color: active ? Colors.white : Colors.grey[300],
                                fontSize: 14,
                                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (active)
                              const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Borrowers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
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
        child: Column(
          children: [
            // ── Search bar + filter button ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search borrower or ID...',
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
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openFilterSheet,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: _hasActiveFilters ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Status filter tabs ───────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
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

            // ── Active sort indicator ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(_sort.icon, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Sorted by: ${_sort.label}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Borrowers list ────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase
                    .from('loans')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _EmptyState(isFiltered: false);
                  }

                  final loans = snapshot.data!.map((j) => Loan.fromJson(j)).toList();
                  final borrowers = _filterAndSort(_groupByBorrower(loans));

                  if (borrowers.isEmpty) {
                    return _EmptyState(isFiltered: true);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: borrowers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final borrower = borrowers[index];
                      return _BorrowerCard(
                        borrower: borrower,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BorrowerDetailScreen(borrower: borrower),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Borrower card ────────────────────────────────────────────────────────────

class _BorrowerCard extends StatelessWidget {
  final BorrowerSummary borrower;
  final VoidCallback onTap;

  const _BorrowerCard({required this.borrower, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasOverdue = borrower.overdueCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: hasOverdue
              ? Border.all(color: AppColors.danger.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            LoanInitialsAvatar(name: borrower.name, radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    borrower.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    borrower.subtitle,
                    style: TextStyle(
                      color: hasOverdue ? AppColors.danger : Colors.grey[500],
                      fontSize: 12,
                      fontWeight: hasOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${formatAmount(borrower.totalOutstanding)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                LoanStatusBadge(status: borrower.overallStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;

  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No borrowers match your search' : 'No borrowers yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }
}