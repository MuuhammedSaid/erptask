import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentHistoryLogScreen extends StatefulWidget {
  @override
  _PaymentFilterScreenState createState() => _PaymentFilterScreenState();
}

class _PaymentFilterScreenState extends State<PaymentHistoryLogScreen> {
  final _invoiceIdController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _filteredPayments = [];
  bool _loading = false;
  String? _error;

  final List<String> _paymentMethods = ['Cash', 'Credit', 'Bank'];

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _searchPayments() async {
    final invoiceId = _invoiceIdController.text.trim();
    if (invoiceId.isEmpty) {
      setState(() => _error = "Please enter an invoice ID");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _filteredPayments = [];
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('payments')
          .where('invoiceId', isEqualTo: invoiceId);

      if (_selectedMethod != null && _selectedMethod!.isNotEmpty) {
        query = query.where('method', isEqualTo: _selectedMethod);
      }

      if (_amountController.text.isNotEmpty) {
        final amount = double.tryParse(_amountController.text);
        if (amount != null) {
          query = query.where('amount', isEqualTo: amount);
        }
      }

      if (_startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
      }
      if (_endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
      }

      final snapshot = await query.get();

      final payments = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _filteredPayments = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error fetching payments: $e";
        _loading = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      labelStyle: TextStyle(color: Colors.indigo),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.indigo, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _invoiceIdController,
                      decoration: _inputDecoration('Invoice ID', Icons.receipt),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                          'Amount (optional)', Icons.attach_money),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      decoration: _inputDecoration(
                          'Payment Method', Icons.account_balance_wallet),
                      items: [null, ..._paymentMethods].map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(method ?? 'Any'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedMethod = val),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickStartDate,
                            icon: Icon(Icons.date_range),
                            label: Text(_startDate == null
                                ? "Start Date"
                                : DateFormat.yMd().format(_startDate!)),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickEndDate,
                            icon: Icon(Icons.event),
                            label: Text(_endDate == null
                                ? "End Date"
                                : DateFormat.yMd().format(_endDate!)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _searchPayments,
                        icon: Icon(Icons.search, color: Colors.white),
                        label: Text(
                          "Search Payments",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_loading) Center(child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!,
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            if (!_loading && _filteredPayments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('No payments found',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            if (_filteredPayments.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _filteredPayments.length,
                itemBuilder: (context, index) {
                  final payment = _filteredPayments[index];
                  final date = (payment['date'] as Timestamp).toDate();
                  final formattedDate =
                      DateFormat.yMMMd().add_jm().format(date);
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      leading: Icon(Icons.payments, color: Colors.indigo),
                      title: Text("Amount: \${payment['amount']}"),
                      subtitle: Text(
                          "Method: ${payment['method']} • Date: $formattedDate"),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
