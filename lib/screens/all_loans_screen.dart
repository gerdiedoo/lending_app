import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';

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

  static const List<String> _statuses = ['All', 'Active', 'Overdue', 'Pending', 'Paid'];

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthAbbr[d.month - 1]} ${d.year}';

  List<Loan> _filter(List<Loan> loans) {
    return loans.where((l) {
      final matchStatus = _selectedStatus == 'All' || l.status == _selectedStatus;
      final matchSearch = _searchQuery.isEmpty ||
          l.borrowerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.lenderName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();
  }

  // ── Detail bottom sheet ────────────────────────────────────────────────────

  void _showDetail(Loan loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _LoanDetailSheet(
        loan: loan,
        formatAmount: _formatAmount,
        formatDate: _formatDate,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          // ── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                    return _LoanCard(
                      loan: loan,
                      monthAbbr: _monthAbbr,
                      formatAmount: _formatAmount,
                      onTap: () => _showDetail(loan),
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

// ── Loan card ─────────────────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final List<String> monthAbbr;
  final String Function(double) formatAmount;
  final VoidCallback onTap;

  const _LoanCard({
    required this.loan,
    required this.monthAbbr,
    required this.formatAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final due = loan.dueDate;
    final dueLabel = '${monthAbbr[due.month - 1]} ${due.day}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _InitialsAvatar(name: loan.borrowerName),
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
                    'Due $dueLabel',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${formatAmount(loan.principalAmount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: loan.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loan detail bottom sheet ──────────────────────────────────────────────────

class _LoanDetailSheet extends StatelessWidget {
  final Loan loan;
  final String Function(double) formatAmount;
  final String Function(DateTime) formatDate;

  const _LoanDetailSheet({
    required this.loan,
    required this.formatAmount,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Avatar + name header
          Row(
            children: [
              _InitialsAvatar(name: loan.borrowerName, radius: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.borrowerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: loan.status),
                  ],
                ),
              ),
              Text(
                '₱${formatAmount(loan.principalAmount)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),

          // Detail rows
          _DetailRow(label: 'Lender',            value: loan.lenderName.isNotEmpty ? loan.lenderName : '—'),
          _DetailRow(label: 'Loan Date',          value: formatDate(loan.createdAt)),
          _DetailRow(label: 'Due Date',           value: formatDate(loan.dueDate)),
          _DetailRow(label: 'Duration',           value: '${loan.durationMonths} months'),
          _DetailRow(label: 'Principal Amount',   value: '₱${formatAmount(loan.principalAmount)}'),

          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 8),

          // Close button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
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

// ── Shared: initials avatar ───────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const _InitialsAvatar({required this.name, this.radius = 22});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  Color get _color {
    const palette = [
      Color(0xFF5B6EF5),
      Color(0xFF26A17B),
      Color(0xFFE8734A),
      Color(0xFFAA5CF5),
      Color(0xFF3AAFDA),
      Color(0xFFE85C8A),
    ];
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color.withOpacity(0.25),
      child: Text(
        _initials,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.55,
        ),
      ),
    );
  }
}

// ── Shared: status badge ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _bg {
    switch (status) {
      case 'Active':  return const Color(0xFF1A3A5C);
      case 'Overdue': return const Color(0xFF5C1A1A);
      case 'Paid':    return const Color(0xFF1A4A2E);
      case 'Pending': return const Color(0xFF4A3A1A);
      default:        return Colors.grey.shade800;
    }
  }

  Color get _fg {
    switch (status) {
      case 'Active':  return AppColors.primary;
      case 'Overdue': return const Color(0xFFEF5350);
      case 'Paid':    return AppColors.success;
      case 'Pending': return const Color(0xFFFFB300);
      default:        return Colors.grey;
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
      child: Text(
        status,
        style: TextStyle(
          color: _fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}