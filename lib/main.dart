import 'package:barber/view/BarberDetailsPage.dart';
import 'package:barber/view/barber_pages.dart/BarberRegistrationPage.dart';
import 'package:barber/view/BookingPage.dart';
import 'package:barber/view/CreateBookingPage11.dart';
import 'package:barber/view/UserTypeSelectionPage.dart';
import 'package:barber/view/barber_pages.dart/BarberShopsPage.dart';
import 'package:barber/view/barber_pages.dart/BarberStatsPage.dart';
import 'package:barber/view/barber_pages.dart/ManageServicesPage.dart';
import 'package:barber/view/barber_pages.dart/ViewDailyStatsPage.dart';
import 'package:barber/view/barber_pages.dart/barberOwnerHomePage.dart';
import 'package:barber/view/barber_pages.dart/RegisterBarberEmail.dart';
import 'package:barber/view/customer_pages/BookingsPage.dart';
import 'package:barber/view/customer_pages/CustomerHomePage.dart';
import 'package:barber/view/customer_pages/CustomerProfilePage.dart';
import 'package:barber/view/customer_pages/NearbyBarbersPage.dart';
import 'package:barber/view/customer_pages/customer_details.dart';
import 'package:barber/view/customer_pages/customer_main_page.dart';
import 'package:barber/view/customer_pages/customer_signin.dart';
import 'package:barber/view/login_page.dart';
import 'package:barber/view/profile_page.dart';
import 'package:barber/view/registerUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDIFN3S14EMn9fWKF5XRXa-5T95slCWHzc",
      appId: "1:738264923480:android:10b0d55d9edf694547b92d",
      messagingSenderId: "738264923480",
      projectId: "barber-a09aa",
      storageBucket: "barber-a09aa.firebasestorage.app",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/customer_main': (context) => const CustomerMainPage(),
        '/barber_main': (context) => const BarberOwnerHomePage(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<Widget> _getInitialPage() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final user = auth.currentUser;
    if (user == null) {
      return const LoginPage();
    }

    try {
      // Check if user is a barber
      final barberDoc = await firestore
          .collection('BarbersDetails')
          .doc(user.email)
          .get()
          .timeout(const Duration(seconds: 5));

      if (barberDoc.exists) {
        return BarberOwnerHomePage();
      }

      // Check if user is a customer
      final customerDoc = await firestore
          .collection('CustomersDetails')
          .doc(user.email)
          .get()
          .timeout(const Duration(seconds: 5));

      if (customerDoc.exists) {
        return CustomerMainPage();
      }

      // User not found in either collection
      await auth.signOut(); // Sign out to prevent looping
      return const LoginPage();
    } catch (e) {
      print('Error checking user type: $e');
      await auth.signOut(); // Sign out on error to avoid stuck state
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cut, size: 80, color: Colors.blue),
                    const SizedBox(height: 20),
                    Text(
                      'THE BARBER',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Colors.blue),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          );
        }

        return snapshot.data ?? const LoginPage();
      },
    );
  }
}
