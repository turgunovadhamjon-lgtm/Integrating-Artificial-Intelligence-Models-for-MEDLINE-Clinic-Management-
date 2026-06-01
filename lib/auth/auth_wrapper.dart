// lib/auth/auth_wrapper.dart - FIXED VERSION

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/admin_dashboard.dart';
import '../screens/doctor_dashboard.dart';
import '../screens/hospitalization_dashboard.dart';
import '../screens/laboratory_dashboard.dart' hide HospitalizationDashboard;
import '../screens/login_screen.dart';
import '../screens/pharmacy_dashboard.dart';
import '../screens/receptionist_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Agar user login qilmagan bo'lsa
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final userId = snapshot.data!.uid;

        // User ma'lumotlarini olish
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnap) {
            // Loading state
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Agar xatolik bo'lsa
            if (userSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Xatolik: ${userSnap.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Agar ma'lumot bo'lmasa
            if (!userSnap.hasData || !userSnap.data!.exists) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Foydalanuvchi topilmadi'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // User rolini olish
            final data = userSnap.data!.data() as Map<String, dynamic>?;
            final role = data?['role'] as String? ?? 'unknown';

            // Role ga qarab dashboard ni ko'rsatish
            return _buildDashboard(role);
          },
        );
      },
    );
  }

  // Dashboard qaytarish funksiyasi
  Widget _buildDashboard(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'doctor':
        return const DoctorDashboard();
      case 'receptionist':
        return const ReceptionistDashboard();
      case 'pharmacy':
        return const PharmacyDashboard();
      case 'laboratory':
        return const LaboratoryDashboard();
      case 'hospitalization':
        return const HospitalizationDashboard();
      default:
      // Agar rol noma'lum bo'lsa
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text('Noma\'lum rol: $role'),
                const SizedBox(height: 8),
                const Text('Iltimos admin bilan bog\'laning'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class LaboratoryPanelScreen {
  const LaboratoryPanelScreen();
}