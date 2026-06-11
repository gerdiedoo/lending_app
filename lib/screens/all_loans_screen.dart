import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../widgets/loan_shared_widgets.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Loan> _filter(List<Loan> loans) {
    return loans.where((l) {
      final matchStatus = _selectedStatus == 'All' || l.status == _selectedStatus;
      final matchSearch = _searchQuery.isEmpty ||
          l.borrowerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.lenderName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();
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