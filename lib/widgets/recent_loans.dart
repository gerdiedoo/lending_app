import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../screens/all_loans_screen.dart';

class RecentLoans extends StatelessWidget {
  final _supabase = Supabase.instance.client;

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('loans')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        return Column(
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Loans',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllLoansScreen(),
                    ),
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── List container ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildBody(snapshot),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No recent loans', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final loans = snapshot.data!.map((j) => Loan.fromJson(j)).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loans.length,
      separatorBuilder: (_, __) => Divider(
        color: Colors.white.withOpacity(0.06),
        height: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (_, index) => _LoanRow(
        loan: loans[index],
        monthAbbr: _monthAbbr,
      ),
    );
  }
}

// ── Individual row ────────────────────────────────────────────────────────────

class _LoanRow extends StatelessWidget {
  final Loan loan;
  final List<String> monthAbbr;

  const _LoanRow({required this.loan, required this.monthAbbr});

  @override
  Widget build(BuildContext context) {
    final due = loan.dueDate;
    final dueLabel = '${monthAbbr[due.month - 1]} ${due.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                '₱${_formatAmount(loan.principalAmount)}',
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
    );
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}

// ── Initials avatar ───────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;

  const _InitialsAvatar({required this.name});

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
      radius: 22,
      backgroundColor: _color.withOpacity(0.25),
      child: Text(
        _initials,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

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