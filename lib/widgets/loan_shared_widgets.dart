import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const List<String> kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> kLoanStatuses = ['Active', 'Overdue', 'Pending', 'Paid'];

// ── Helpers ───────────────────────────────────────────────────────────────────

String formatAmount(double amount) {
  final parts = amount.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
    buffer.write(parts[i]);
  }
  return buffer.toString();
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${kMonthAbbr[d.month - 1]} ${d.year}';

// ── Loan card (used in list views) ────────────────────────────────────────────

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;

  const LoanCard({super.key, required this.loan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final due = loan.dueDate;
    final dueLabel = '${kMonthAbbr[due.month - 1]} ${due.day}';

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
                LoanStatusBadge(status: loan.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loan row (compact, used in recent_loans inside a container) ───────────────

class LoanRow extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;

  const LoanRow({super.key, required this.loan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final due = loan.dueDate;
    final dueLabel = '${kMonthAbbr[due.month - 1]} ${due.day}';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                LoanStatusBadge(status: loan.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class LoanDetailSheet extends StatelessWidget {
  final Loan loan;
  final VoidCallback onEdit;

  const LoanDetailSheet({
    super.key,
    required this.loan,
    required this.onEdit,
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

          // Avatar + name + amount header
          Row(
            children: [
              LoanInitialsAvatar(name: loan.borrowerName, radius: 28),
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
                    LoanStatusBadge(status: loan.status),
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
          LoanDetailRow(label: 'Lender',           value: loan.lenderName.isNotEmpty ? loan.lenderName : '—'),
          LoanDetailRow(label: 'Loan Date',         value: formatDate(loan.loanDate)),
          LoanDetailRow(label: 'Due Date',          value: formatDate(loan.dueDate)),
          LoanDetailRow(label: 'Duration',          value: '${loan.durationMonths} months'),
          LoanDetailRow(label: 'Principal Amount',  value: '₱${formatAmount(loan.principalAmount)}'),
          LoanDetailRow(label: 'Interest Rate',     value: '${loan.interestRate.toStringAsFixed(1)}% / cycle'),
          if (loan.status != 'Paid') ...[
            LoanDetailRow(label: 'Interest This Cycle', value: '₱${formatAmount(loan.interestOnlyAmount)}'),
            LoanDetailRow(label: 'Full Settlement Due', value: '₱${formatAmount(loan.fullSettlementAmount)}'),
          ],
          if (loan.interestCyclesPaid > 0)
            LoanDetailRow(label: 'Rolled Over',     value: '${loan.interestCyclesPaid}× (interest-only)'),

          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Loan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
        ],
      ),
    );
  }
}

// ── Edit bottom sheet ─────────────────────────────────────────────────────────

class LoanEditSheet extends StatefulWidget {
  final Loan loan;
  final VoidCallback onSaved;

  const LoanEditSheet({
    super.key,
    required this.loan,
    required this.onSaved,
  });

  @override
  State<LoanEditSheet> createState() => _LoanEditSheetState();
}

class _LoanEditSheetState extends State<LoanEditSheet> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _borrowerCtrl;
  late final TextEditingController _lenderCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _durationCtrl;

  late String _selectedStatus;
  late DateTime _loanDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _borrowerCtrl   = TextEditingController(text: widget.loan.borrowerName);
    _lenderCtrl     = TextEditingController(text: widget.loan.lenderName);
    _amountCtrl     = TextEditingController(text: widget.loan.principalAmount.toStringAsFixed(0));
    _durationCtrl   = TextEditingController(text: widget.loan.durationMonths.toString());
    _selectedStatus = widget.loan.status;
    _loanDate       = widget.loan.loanDate;
  }

  @override
  void dispose() {
    _borrowerCtrl.dispose();
    _lenderCtrl.dispose();
    _amountCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLoanDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loanDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
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
      ),
    );
    if (picked != null) setState(() => _loanDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final loanDateUtc = DateTime.utc(
        _loanDate.year,
        _loanDate.month,
        _loanDate.day,
      );

      await _supabase
          .from('loans')
          .update({
            'borrower_name':    _borrowerCtrl.text.trim(),
            'lender_name':      _lenderCtrl.text.trim(),
            'principal_amount': double.parse(_amountCtrl.text.trim()),
            'duration_months':  int.parse(_durationCtrl.text.trim()),
            'status':           _selectedStatus,
            'loan_date':        loanDateUtc.toIso8601String(),
          })
          .eq('id', widget.loan.id);

      widget.onSaved();
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
            content: Text('Failed to update: $e'),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 40 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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

              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  LoanInitialsAvatar(name: widget.loan.borrowerName, radius: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Loan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 20),

              // Borrower Name
              LoanEditField(
                controller: _borrowerCtrl,
                label: 'Borrower Name',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Lender Name
              LoanEditField(
                controller: _lenderCtrl,
                label: 'Lender Name',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 14),

              // Principal Amount
              LoanEditField(
                controller: _amountCtrl,
                label: 'Principal Amount (₱)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Duration
              LoanEditField(
                controller: _durationCtrl,
                label: 'Duration (months)',
                icon: Icons.schedule_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Enter a whole number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Status dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        dropdownColor: AppColors.background,
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: kLoanStatuses.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: LoanStatusBadge(status: s),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedStatus = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Loan Date picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Loan Date', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickLoanDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 18),
                          const SizedBox(width: 10),
                          Text(
                            formatDate(_loanDate),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const Spacer(),
                          Icon(Icons.edit_outlined, color: Colors.grey[600], size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper: show detail then optionally edit ──────────────────────────────────

void showLoanDetail(BuildContext context, Loan loan) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (_) => LoanDetailSheet(
      loan: loan,
      onEdit: () {
        Navigator.pop(context); // close detail
        showLoanEdit(context, loan);
      },
    ),
  );
}

void showLoanEdit(BuildContext context, Loan loan) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (_) => LoanEditSheet(
      loan: loan,
      onSaved: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loan updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    ),
  );
}

// ── Detail row ────────────────────────────────────────────────────────────────

class LoanDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const LoanDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit field ────────────────────────────────────────────────────────────────

class LoanEditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const LoanEditField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 18),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF5350), fontSize: 11),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Initials avatar ───────────────────────────────────────────────────────────

class LoanInitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const LoanInitialsAvatar({super.key, required this.name, this.radius = 22});

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

// ── Status badge ──────────────────────────────────────────────────────────────

class LoanStatusBadge extends StatelessWidget {
  final String status;

  const LoanStatusBadge({super.key, required this.status});

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