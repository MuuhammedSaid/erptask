import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceStatusTrackingScreen extends StatefulWidget {
  @override
  _InvoiceStatusTrackingScreenState createState() =>
      _InvoiceStatusTrackingScreenState();
}

class _InvoiceStatusTrackingScreenState
    extends State<InvoiceStatusTrackingScreen> {
  String filterInvoiceId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter Invoice ID to filter',
                labelStyle: TextStyle(
                    color: Colors.blue[900], fontWeight: FontWeight.w600),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
                suffixIcon: filterInvoiceId.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.blue[900]),
                        onPressed: () {
                          setState(() {
                            filterInvoiceId = '';
                          });
                        },
                      )
                    : null,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue[900]!, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              style: TextStyle(fontSize: 16, color: Colors.blue[900]),
              onChanged: (val) {
                setState(() {
                  filterInvoiceId = val.trim();
                });
              },
            ),

            SizedBox(height: 16),

            // Invoice List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('invoices')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                      'Error loading invoices',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child:
                            CircularProgressIndicator(color: Colors.blue[900]));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(
                      'No invoices found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ));
                  }

                  final allInvoices = snapshot.data!.docs;
                  final invoices = filterInvoiceId.isEmpty
                      ? allInvoices
                      : allInvoices
                          .where((doc) => doc.id
                              .toLowerCase()
                              .contains(filterInvoiceId.toLowerCase()))
                          .toList();

                  if (invoices.isEmpty) {
                    return Center(
                        child: Text(
                      'No matching invoices found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ));
                  }

                  return ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final doc = invoices[index];
                      final data = doc.data()! as Map<String, dynamic>;

                      print('Data for invoice ${doc.id}: $data'); // 👈 Debug

                      final totalAmount = double.tryParse(
                              data['totalAmount']?.toString() ?? '') ??
                          0.0;
                      final paidAmount = double.tryParse(
                              data['paidAmount']?.toString() ?? '') ??
                          0.0;
                      final remainingAmount = totalAmount - paidAmount;

                      final status = data['status'] ?? 'Unknown Status';

                      Color statusColor;
                      switch (status.toLowerCase()) {
                        case 'paid':
                          statusColor = Colors.green;
                          break;
                        case 'overdue':
                          statusColor = Colors.red;
                          break;
                        case 'unpaid':
                          statusColor = Colors.orange;
                          break;
                        default:
                          statusColor = Colors.grey;
                      }

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        shadowColor: Colors.blue[100],
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          tileColor: Colors.white,
                          title: Text(
                            'Invoice ID: ${doc.id}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900]),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Total Amount: \$${totalAmount.toStringAsFixed(2)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                    'Paid Amount: \$${paidAmount.toStringAsFixed(2)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                    'Remaining: \$${remainingAmount.toStringAsFixed(2)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 14, color: statusColor),
                                    SizedBox(width: 6),
                                    Text('Status: $status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: statusColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
