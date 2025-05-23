import 'package:documentmanager/screens/invoice/AddInvoiceScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentLoggingScreen extends StatefulWidget {
  @override
  _PaymentLoggingScreenState createState() => _PaymentLoggingScreenState();
}

class _PaymentLoggingScreenState extends State<PaymentLoggingScreen> {
  String? selectedInvoiceId;
  final amountController = TextEditingController();
  String paymentMethod = 'Cash';
  final methods = ['Cash', 'Credit', 'Bank'];

  double totalAmount = 0.0;
  double paidAmount = 0.0;

  Future<void> logPayment() async {
    if (selectedInvoiceId == null || amountController.text.isEmpty) {
      _showSnackBar("Please select an invoice and enter amount");
      return;
    }

    final amount = double.tryParse(amountController.text);
    final remainingAmount = totalAmount - paidAmount;

    if (amount == null || amount <= 0 || amount > remainingAmount) {
      _showSnackBar(
          "Enter a valid amount up to ${remainingAmount.toStringAsFixed(2)}");
      return;
    }

    final paymentData = {
      'invoiceId': selectedInvoiceId,
      'amount': amount,
      'method': paymentMethod,
      'date': Timestamp.now(),
    };

    final invoiceRef = FirebaseFirestore.instance
        .collection('invoices')
        .doc(selectedInvoiceId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final invoiceSnapshot = await transaction.get(invoiceRef);

      if (!invoiceSnapshot.exists) throw Exception("Invoice not found");

      final currentPaid = (invoiceSnapshot.get('paidAmount') ?? 0).toDouble();

      transaction.set(
        FirebaseFirestore.instance.collection('payments').doc(),
        paymentData,
      );

      transaction.update(invoiceRef, {
        'paidAmount': currentPaid + amount,
      });
    });

    amountController.clear();
    _showSnackBar("Payment logged successfully");
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.indigo,
    ));
  }

  Future<void> fetchInvoiceDetails(String invoiceId) async {
    final invoiceRef =
        FirebaseFirestore.instance.collection('invoices').doc(invoiceId);
    final invoiceSnapshot = await invoiceRef.get();
    if (invoiceSnapshot.exists) {
      setState(() {
        totalAmount = (invoiceSnapshot.get('totalAmount') ?? 0).toDouble();
        paidAmount = (invoiceSnapshot.get('paidAmount') ?? 0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('invoices').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final invoices = snapshot.data!.docs;

          return AnimatedSwitcher(
            duration: Duration(milliseconds: 400),
            child: Padding(
              key: ValueKey(selectedInvoiceId),
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration(
                                'Select Invoice', Icons.receipt),
                            value: selectedInvoiceId,
                            items: invoices.map((doc) {
                              final id = doc.id;
                              return DropdownMenuItem(
                                value: id,
                                child: Text('Invoice: $id'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedInvoiceId = val;
                                fetchInvoiceDetails(val!);
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // 💰 المبلغ المدفوع
                          TextField(
                            controller: amountController,
                            decoration: _inputDecoration(
                                'Payment Amount', Icons.attach_money),
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 20),

                          // 🏦 طريقة الدفع
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration(
                                'Payment Method', Icons.account_balance_wallet),
                            value: paymentMethod,
                            items: methods.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => paymentMethod = val!),
                          ),
                          const SizedBox(height: 30),

                          // زرار تسجيل الدفع
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: logPayment,
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              label: Text("Log Payment",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddInvoiceScreen()));
        },
        icon: Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: Text("Add Invoice", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      labelStyle: TextStyle(color: Colors.indigo),
      filled: true,
      fillColor: Colors.grey.shade100,
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
}
