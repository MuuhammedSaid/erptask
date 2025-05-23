import 'package:documentmanager/screens/invoice/invoice_status.dart';
import 'package:documentmanager/screens/invoice/invoice_summary.dart';
import 'package:documentmanager/screens/payment/payment_history.dart';
import 'package:documentmanager/screens/payment/payment_logging.dart';
import 'package:documentmanager/screens/invoice/reciept_generation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyD0MWojZWiN6GE_BkAjz1hSgANSRkTw3W4",
          authDomain: "documentmanager-8bc79.firebaseapp.com",
          projectId: "documentmanager-8bc79",
          storageBucket: "documentmanager-8bc79.firebasestorage.app",
          messagingSenderId: "75816416281",
          appId: "1:75816416281:web:a3d3b39ebdfcf29964a688",
          measurementId: "G-SZ3KBY265V",
        ),
      );
    }
  } catch (e) {
    print('Firebase initialization skipped: $e');
  }

  runApp(CostManagementApp());
}

class CostManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cost Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo,
          elevation: 4,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      home: MainHome(),
    );
  }
}

class MainHome extends StatefulWidget {
  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PaymentLoggingScreen(),
    ReceiptScreen(),
    InvoiceStatusTrackingScreen(),
    PaymentHistoryLogScreen(),
    InvoiceSummaryReportScreen(),
  ];

  final List<String> _titles = [
    'Log Payment',
    'Generate Receipt',
    'Invoice Status Tracking',
    'Payment History',
    'Invoice Summary',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: _screens[_currentIndex],
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60,
        color: Colors.indigo,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: Colors.indigo.shade700,
        animationDuration: Duration(milliseconds: 300),
        items: const [
          Icon(Icons.payment, size: 30, color: Colors.white),
          Icon(Icons.receipt, size: 30, color: Colors.white),
          Icon(Icons.info, size: 30, color: Colors.white),
          Icon(Icons.history, size: 30, color: Colors.white),
          Icon(Icons.bar_chart, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
