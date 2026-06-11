import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class CreateLoanScreen extends StatefulWidget {
  const CreateLoanScreen({super.key});

  @override
  State<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends State<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to capture user input
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _durationController = TextEditingController();

  // State variables for the summary calculation
  double _totalRepayment = 0.0;
  double _monthlyInstallment = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to instantly recalculate when numbers change
    _amountController.addListener(_calculateSummary);
    _interestController.addListener(_calculateSummary);
    _durationController.addListener(_calculateSummary);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Reactive calculation logic
  void _calculateSummary() {
    double principal = double.tryParse(_amountController.text) ?? 0.0;
    double rate = double.tryParse(_interestController.text) ?? 0.0;
    int months = int.tryParse(_durationController.text) ?? 0;

    if (principal > 0 && rate > 0 && months > 0) {
      double totalInterest = principal * (rate / 100) * months;
      
      setState(() {
        _totalRepayment = principal + totalInterest;
        _monthlyInstallment = _totalRepayment / months;
      });
    } else {
      setState(() {
        _totalRepayment = 0.0;
        _monthlyInstallment = 0.0;
      });
    }
  }

  // >>> SUPABASE INTEGRATION HERE <<<
  Future<void> _submitLoan() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found. Please log in again.');
      }

      // Insert record into Supabase
      await supabase.from('loans').insert({
        'manager_id': currentUser.id,
        'borrower_name': _nameController.text.trim(),
        'borrower_phone': _phoneController.text.trim(),
        'principal_amount': double.parse(_amountController.text),
        'interest_rate': double.parse(_interestController.text),
        'duration_months': int.parse(_durationController.text),
        'total_repayment': _totalRepayment,
        'monthly_installment': _monthlyInstallment,
        'status': 'Active', // Default status for a new loan
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan created successfully!'), 
            backgroundColor: AppColors.success
          ),
        );
        Navigator.pop(context); // Return to Dashboard
      }
    } on PostgrestException catch (error) {
      // Catch Database-specific errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database Error: ${error.message}'), backgroundColor: AppColors.danger),
        );
      }
    } catch (error) {
      // Catch any other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper widget for standardizing text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[700]),
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              prefixText: prefixText,
              prefixStyle: const TextStyle(color: Colors.white, fontSize: 16),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Create New Loan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Borrower Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter full name',
                icon: Icons.person_outline,
              ),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              const Text('Loan Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _amountController,
                label: 'Principal Amount',
                hint: '0.00',
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _interestController,
                      label: 'Interest Rate (%)',
                      hint: '0',
                      icon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _durationController,
                      label: 'Duration (Months)',
                      hint: '0',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Repayment', style: TextStyle(color: Colors.grey)),
                        Text('₱${_totalRepayment.toStringAsFixed(2)}', 
                          style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.grey, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Installment', style: TextStyle(color: Colors.grey)),
                        Text('₱${_monthlyInstallment.toStringAsFixed(2)}', 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLoan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CREATE LOAN RECORD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}