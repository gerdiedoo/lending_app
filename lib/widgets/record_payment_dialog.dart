import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';
import '../models/loan_model.dart';
import '../screens/borrowers_screen.dart';

/// Shows the "Record Payment" dialog for a given borrower.
void showRecordPaymentDialog(BuildContext context, BorrowerSummary borrower) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => RecordPaymentDialog(borrower: borrower),
  );
}

class RecordPaymentDialog extends StatefulWidget {
  final BorrowerSummary borrower;

  const RecordPaymentDialog({super.key, required this.borrower});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _amountController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  bool _isPayingAll = false;
  bool _isPayingInterest = false;

  final _supabase = Supabase.instance.client;

  double get _totalInterestDue => widget.borrower.loans
      .where((l) => l.status != 'Paid')
      .fold<double>(0.0, (sum, l) => sum + l.interestOnlyAmount);

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Marks every outstanding loan for this borrower as 'Paid' and records
  /// a single payment entry covering the full outstanding amount.
  Future<void> _payAllLoans() async {
    final outstandingLoans =
        widget.borrower.loans.where((l) => l.status != 'Paid').toList();

    if (outstandingLoans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This borrower has no outstanding loans'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final totalOutstanding =
        outstandingLoans.fold<double>(0.0, (sum, l) => sum + l.fullSettlementAmount);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pay All Loans?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will mark all ${outstandingLoans.length} outstanding loan(s) for '
          '${widget.borrower.name} as Paid, totaling ₱${_formatAmount(totalOutstanding)}. '
          'This cannot be undone.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPayingAll = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please log in again.');
      }

      // Mark every outstanding loan as Paid, and record one payment
      // entry per loan (each linked via loan_id) so the ledger can be
      // traced back precisely even when a borrower has multiple loans.
      for (final loan in outstandingLoans) {
        await _supabase
            .from('loans')
            .update({'status': 'Paid'})
            .eq('id', loan.id)
            .eq('manager_id', currentUser.id);

        await _supabase.from('payments').insert({
          'manager_id': currentUser.id,
          'borrower_name': widget.borrower.name,
          'loan_id': loan.id,
          'amount_paid': loan.fullSettlementAmount,
          'kind': 'full',
          'payment_date': DateTime.utc(
            _paymentDate.year,
            _paymentDate.month,
            _paymentDate.day,
          ).toIso8601String(),
          'notes': _notesController.text.trim().isEmpty
              ? 'Full settlement'
              : _notesController.text.trim(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All loans for ${widget.borrower.name} marked as Paid'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: ${e.message}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pay all loans: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPayingAll = false);
    }
  }

  /// Pays just this cycle's interest for every outstanding loan: the
  /// principal stays the same, the loan's due date rolls forward one
  /// month, and any loan currently marked Overdue goes back to Active
  /// since the borrower has caught up on interest.
  Future<void> _payInterestOnly() async {
    final outstandingLoans =
        widget.borrower.loans.where((l) => l.status != 'Paid').toList();

    if (outstandingLoans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This borrower has no outstanding loans'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final totalInterest =
        outstandingLoans.fold<double>(0.0, (sum, l) => sum + l.interestOnlyAmount);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pay Interest Only?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This records an interest-only payment of ₱${_formatAmount(totalInterest)} '
          'for ${outstandingLoans.length} outstanding loan(s). The principal stays the '
          'same and the due date moves forward one month for each loan.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay Interest', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPayingInterest = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please log in again.');
      }

      // For each outstanding loan: push the due date forward a month,
      // bump the interest-cycles counter, flip Overdue back to Active
      // since the borrower has paid what's due this cycle, and record
      // one payment entry per loan (linked via loan_id) for an accurate
      // ledger even across borrowers with multiple loans.
      for (final loan in outstandingLoans) {
        final nextDueDate = DateTime.utc(
          loan.dueDate.year,
          loan.dueDate.month + 1,
          loan.dueDate.day,
        );

        await _supabase
            .from('loans')
            .update({
              'current_due_date': nextDueDate.toIso8601String(),
              'interest_cycles_paid': loan.interestCyclesPaid + 1,
              'status': loan.status == 'Overdue' ? 'Active' : loan.status,
            })
            .eq('id', loan.id)
            .eq('manager_id', currentUser.id);

        await _supabase.from('payments').insert({
          'manager_id': currentUser.id,
          'borrower_name': widget.borrower.name,
          'loan_id': loan.id,
          'amount_paid': loan.interestOnlyAmount,
          'kind': 'interest_only',
          'payment_date': DateTime.utc(
            _paymentDate.year,
            _paymentDate.month,
            _paymentDate.day,
          ).toIso8601String(),
          'notes': _notesController.text.trim().isEmpty
              ? 'Interest-only payment — rolled to next month'
              : _notesController.text.trim(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Interest payment recorded for ${widget.borrower.name}. Due dates moved forward.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: ${e.message}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record interest payment: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPayingInterest = false);
    }
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

  String get _dateLabel =>
      '${_paymentDate.month.toString().padLeft(2, '0')}/'
      '${_paymentDate.day.toString().padLeft(2, '0')}/'
      '${_paymentDate.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.surface,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid payment amount'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please log in again.');
      }

      await _supabase.from('payments').insert({
        'manager_id': currentUser.id,
        'borrower_name': widget.borrower.name,
        'amount_paid': amount,
        'kind': 'manual',
        'payment_date': DateTime.utc(
          _paymentDate.year,
          _paymentDate.month,
          _paymentDate.day,
        ).toIso8601String(),
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment recorded successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: ${e.message}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Record Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey, size: 22),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Amount paid ──────────────────────────────────────
            const Text(
              'Amount Paid',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Payment date ─────────────────────────────────────
            const Text(
              'Payment Date',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Notes ────────────────────────────────────────────
            const Text(
              'Notes',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g., Received at home office',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Confirm button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || _isPayingAll || _isPayingInterest) ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        'Confirm Payment',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Pay All Loans button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_isLoading || _isPayingAll || _isPayingInterest) ? null : _payAllLoans,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isPayingAll
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.success),
                      )
                    : Text(
                        'Pay All Loans (₱${_formatAmount(widget.borrower.totalOutstanding)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Pay Interest Only button ──────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_isLoading || _isPayingAll || _isPayingInterest) ? null : _payInterestOnly,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFB300),
                  side: const BorderSide(color: Color(0xFFFFB300)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isPayingInterest
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFFB300)),
                      )
                    : Text(
                        'Pay Interest Only (₱${_formatAmount(_totalInterestDue)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Cancel ───────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: (_isLoading || _isPayingAll || _isPayingInterest) ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}