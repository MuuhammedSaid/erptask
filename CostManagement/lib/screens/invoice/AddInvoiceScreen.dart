import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddInvoiceScreen extends StatefulWidget {
  @override
  _AddInvoiceScreenState createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  DateTime? _dueDate;

  Future<void> _addInvoice() async {
    if (_formKey.currentState!.validate() && _dueDate != null) {
      final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;

      await FirebaseFirestore.instance.collection('invoices').add({
        'clientId': _clientIdController.text.trim(),
        'totalAmount': totalAmount,
        'paidAmount': 0.0,
        'dueDate': Timestamp.fromDate(_dueDate!),
        'status': 'Unpaid',
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invoice Added")));
      Navigator.pop(context);
    } else if (_dueDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please select a due date")));
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validatorMsg,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.isEmpty ? validatorMsg : null,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.blue[900]) : null,
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.blue[900], fontWeight: FontWeight.w600, fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue[900]!, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
      style: TextStyle(fontSize: 16, color: Colors.blue[900]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.blue[900],
          elevation: 8,
          centerTitle: true,
          title: Text(
            'Add Invoice',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 2),
                  blurRadius: 4,
                )
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: SingleChildScrollView(
          key: ValueKey('form'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _clientIdController,
                  label: 'Client Name',
                  validatorMsg: 'Enter Client Name',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _totalAmountController,
                  label: 'Total Amount',
                  validatorMsg: 'Enter Amount',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.attach_money_outlined,
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _dueDate == null
                            ? Colors.grey.shade400
                            : Colors.blue.shade900,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade50,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dueDate == null
                              ? 'Select Due Date'
                              : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _dueDate == null
                                ? Colors.grey[600]
                                : Colors.blue[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.calendar_today, color: Colors.blue[900]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _addInvoice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.blue[700],
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  child: Text(
                    'Add Invoice',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
