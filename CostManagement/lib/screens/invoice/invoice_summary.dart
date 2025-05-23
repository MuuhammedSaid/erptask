import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InvoiceSummaryReportScreen extends StatefulWidget {
  @override
  _InvoiceSummaryReportScreenState createState() =>
      _InvoiceSummaryReportScreenState();
}

class _InvoiceSummaryReportScreenState
    extends State<InvoiceSummaryReportScreen> {
  DateTimeRange? selectedDateRange;
  String selectedStatus = 'All';
  String selectedClient = 'All';
  List<String> statusOptions = ['All', 'Paid', 'Unpaid', 'Overdue'];
  List<String> clientOptions = ['All'];
  bool isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    _fetchClientIds();
  }

  Future<void> _fetchClientIds() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('invoices').get();

      final clients = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final clientId = data['clientId'] ?? '';
        if (clientId.isNotEmpty) {
          clients.add(clientId);
        }
      }

      setState(() {
        clientOptions.addAll(clients.toList());
        isLoadingClients = false;
      });
    } catch (e) {
      print("Error fetching client IDs: $e");
      setState(() {
        isLoadingClients = false;
      });
    }
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Status Dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade900, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButton<String>(
              value: selectedStatus,
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue[900]),
              isExpanded: true,
              underline: SizedBox(),
              style: TextStyle(color: Colors.blue[900], fontSize: 16),
              onChanged: (val) => setState(() => selectedStatus = val!),
              items: statusOptions.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
            ),
          ),
          SizedBox(height: 16),

          // Client Dropdown
          isLoadingClients
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade900, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: selectedClient,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.blue[900]),
                    isExpanded: true,
                    underline: SizedBox(),
                    style: TextStyle(color: Colors.blue[900], fontSize: 16),
                    onChanged: (val) => setState(() => selectedClient = val!),
                    items: clientOptions.map((client) {
                      return DropdownMenuItem(
                          value: client, child: Text(client));
                    }).toList(),
                  ),
                ),

          SizedBox(height: 16),

          // Date Range Button
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.blue[900]!,
                        onPrimary: Colors.white,
                        onSurface: Colors.blue[900]!,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => selectedDateRange = picked);
              }
            },
            icon: Icon(Icons.date_range, color: Colors.white),
            label: Text(
              selectedDateRange == null
                  ? "Select Date Range"
                  : "${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)}",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('invoices').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final invoices = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          final clientId = data['clientId'] ?? '';
          final dueDate = (data['dueDate'] as Timestamp).toDate();

          bool matchesStatus =
              selectedStatus == 'All' || status == selectedStatus;
          bool matchesClient =
              selectedClient == 'All' || clientId == selectedClient;
          bool matchesDate = selectedDateRange == null ||
              (dueDate.isAfter(
                      selectedDateRange!.start.subtract(Duration(days: 1))) &&
                  dueDate
                      .isBefore(selectedDateRange!.end.add(Duration(days: 1))));

          return matchesStatus && matchesClient && matchesDate;
        }).toList();

        if (invoices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                "No invoices found.",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final doc = invoices[index];
            final data = doc.data() as Map<String, dynamic>;

            final total = (data['totalAmount'] ?? 0).toDouble();
            final paid = (data['paidAmount'] ?? 0).toDouble();
            final dueDate = (data['dueDate'] as Timestamp).toDate();
            final clientId = data['clientId'] ?? 'Unknown';

            String correctStatus;
            if (paid >= total) {
              correctStatus = "Paid";
            } else if (dueDate.isBefore(DateTime.now())) {
              correctStatus = "Overdue";
            } else {
              correctStatus = "Unpaid";
            }

            if (data['status'] != correctStatus) {
              FirebaseFirestore.instance
                  .collection('invoices')
                  .doc(doc.id)
                  .update({'status': correctStatus});
            }

            return Card(
              elevation: 4,
              margin:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.grey[50],
                title: Text("Invoice ID: ${doc.id}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue[900])),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text("Client: $clientId"),
                    Text(
                        "Paid: \$${paid.toStringAsFixed(2)} / \$${total.toStringAsFixed(2)}"),
                    Text("Due Date: ${DateFormat.yMMMd().format(dueDate)}"),
                    Text(
                      "Status: ${correctStatus}",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: correctStatus == 'Paid'
                              ? Colors.green
                              : correctStatus == 'Overdue'
                                  ? Colors.red
                                  : Colors.orange),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFilters(),
              Divider(thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Invoices List",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900]),
                ),
              ),
              _buildInvoiceList(),
            ],
          ),
        ),
      ),
    );
  }
}
