import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ReceiptScreen extends StatefulWidget {
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  String? selectedPaymentId;
  Map<String, dynamic>? selectedPayment;
  Map<String, String> invoiceClientMap = {};

  @override
  void initState() {
    super.initState();
  }

  Future<List<QueryDocumentSnapshot>> fetchPayments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .orderBy('date', descending: true)
        .get();

    final payments = snapshot.docs;

    for (var payment in payments) {
      final invoiceId = payment['invoiceId'];
      final invoiceSnapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (invoiceSnapshot.exists) {
        invoiceClientMap[invoiceId] = invoiceSnapshot['clientId'];
      }
    }

    return payments;
  }

  Future<pw.Document> generateReceiptPdf(
      Map<String, dynamic> payment, String paymentId) async {
    final date = (payment['date'] as Timestamp).toDate();
    final formattedDate = DateFormat.yMMMd().add_jm().format(date);
    final invoiceId = payment['invoiceId'];
    final clientId = invoiceClientMap[invoiceId] ?? "Unknown";

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("🧾 Payment Receipt",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              ..._buildPdfText([
                "Client ID: $clientId",
                "Invoice ID: $invoiceId",
                "Payment ID: $paymentId",
                "Amount Paid: \$${payment['amount']}",
                "Payment Method: ${payment['method']}",
                "Date: $formattedDate",
              ]),
              pw.SizedBox(height: 20),
              pw.Text("Thank you for your payment!",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  List<pw.Widget> _buildPdfText(List<String> lines) {
    return lines.map((line) => pw.Text(line)).toList();
  }

  Widget _buildReceiptCard(Map<String, dynamic> payment) {
    final date = (payment['date'] as Timestamp).toDate();
    final formattedDate = DateFormat.yMMMd().add_jm().format(date);
    final invoiceId = payment['invoiceId'];
    final clientId = invoiceClientMap[invoiceId] ?? "Unknown";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🧾 Payment Receipt",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ..._buildText([
              "Client ID: $clientId",
              "Invoice ID: $invoiceId",
              "Payment ID: $selectedPaymentId",
              "Amount Paid: \$${payment['amount']}",
              "Payment Method: ${payment['method']}",
              "Date: $formattedDate",
            ]),
            SizedBox(height: 10),
            Text("Thank you for your payment!",
                style: TextStyle(fontStyle: FontStyle.italic)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.picture_as_pdf),
              label: Text("Export as PDF"),
              onPressed: () async {
                final pdf =
                    await generateReceiptPdf(payment, selectedPaymentId!);
                await Printing.layoutPdf(onLayout: (format) => pdf.save());
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildText(List<String> lines) {
    return lines.map((line) => Text(line)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: fetchPayments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(labelText: 'Select a Payment'),
                value: selectedPaymentId,
                items: payments.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final invoiceId = data['invoiceId'];
                  final clientId = invoiceClientMap[invoiceId] ?? "Unknown";
                  final date = (data['date'] as Timestamp).toDate();
                  final formatted = DateFormat.yMd().add_jm().format(date);

                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      '$clientId - \$${data['amount']} on $formatted',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedPaymentId = val;
                    selectedPayment = payments
                        .firstWhere((doc) => doc.id == val!)
                        .data() as Map<String, dynamic>;
                  });
                },
              ),
              if (selectedPayment != null) _buildReceiptCard(selectedPayment!),
            ],
          ),
        );
      },
    );
  }
}
