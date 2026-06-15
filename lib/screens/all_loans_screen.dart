import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../widgets/loan_shared_widgets.dart';

enum LoanSort {
  newest,
  oldest,
  dueSoonest,
  dueLatest,
  amountHigh,
  amountLow,
}

extension LoanSortLabel on LoanSort {
  String get label {
    switch (this) {
      case LoanSort.newest:
        return 'Newest First';
      case LoanSort.oldest:
        return 'Oldest First';
      case LoanSort.dueSoonest:
        return 'Due Date (Soonest)';
      case LoanSort.dueLatest:
        return 'Due Date (Latest)';
      case LoanSort.amountHigh:
        return 'Amount (High to Low)';
      case LoanSort.amountLow:
        return 'Amount (Low to High)';
    }
  }

  IconData get icon {
    switch (this) {
      case LoanSort.newest:
      case LoanSort.oldest:
        return Icons.schedule;
      case LoanSort.dueSoonest:
      case LoanSort.dueLatest:
        return Icons.event;
      case LoanSort.amountHigh:
      case LoanSort.amountLow:
        return Icons.payments_outlined;
    }
  }
}

class AllLoansScreen extends StatefulWidget {
  const AllLoansScreen({super.key});

  @override
  State<AllLoansScreen> createState() => _AllLoansScreenState();
}

class _AllLoansScreenState extends State<AllLoansScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  String _selectedStatus = 'All';
  String _searchQuery = '';
  LoanSort _sort = LoanSort.newest;

  static const List<String> _statuses = ['All', 'Active', 'Overdue', 'Pending', 'Paid'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Loan> _filter(List<Loan> loans) {
    final filtered = loans.where((l) {
      final matchStatus = _selectedStatus == 'All' || l.status == _selectedStatus;
      final matchSearch = _searchQuery.isEmpty ||
          l.borrowerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.lenderName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case LoanSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case LoanSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case LoanSort.dueSoonest:
          return a.dueDate.compareTo(b.dueDate);
        case LoanSort.dueLatest:
          return b.dueDate.compareTo(a.dueDate);
        case LoanSort.amountHigh:
          return b.principalAmount.compareTo(a.principalAmount);
        case LoanSort.amountLow:
          return a.principalAmount.compareTo(b.principalAmount);
      }
    });

    return filtered;
  }

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
                            _sort = LoanSort.newest;
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
                  ...LoanSort.values.map((sort) {
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

  bool get _hasActiveFilters => _selectedStatus != 'All' || _sort != LoanSort.newest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'All Loans',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
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
                      hintText: 'Search borrower or lender…',
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

          const SizedBox(height: 12),

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

          const SizedBox(height: 10),

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

          const SizedBox(height: 8),

          // ── Loans list ───────────────────────────────────────────
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
                  return _EmptyState(status: _selectedStatus);
                }

                final all = snapshot.data!.map((j) => Loan.fromJson(j)).toList();
                final filtered = _filter(all);

                if (filtered.isEmpty) {
                  return _EmptyState(status: _selectedStatus, isFiltered: true);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final loan = filtered[index];
                    return LoanCard(
                      loan: loan,
                      onTap: () => showLoanDetail(context, loan),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String status;
  final bool isFiltered;

  const _EmptyState({required this.status, this.isFiltered = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No loans match your search'
                : status == 'All'
                    ? 'No loans yet'
                    : 'No $status loans',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }
}