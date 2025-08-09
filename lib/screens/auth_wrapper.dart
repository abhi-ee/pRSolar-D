import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_app/screens/splash_screen.dart';
import 'package:solar_app/screens/auth_screen.dart';

// Prefix the imports to disambiguate:
import 'package:solar_app/screens/icr_info_screen.dart' as icr_screen;
import 'package:solar_app/services/firestore_service.dart' as services;
import 'package:solar_app/screens/home_screen.dart' as home_screen;

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        } else if (snapshot.hasData && snapshot.data != null) {
          final String userId = snapshot.data!.uid;
          return FutureBuilder<bool>(
            future: services.FirestoreService().doesIcrInfoExist(userId),
            builder: (context, icrSnapshot) {
              if (icrSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (icrSnapshot.hasError) {
                print('Error checking ICR info: ${icrSnapshot.error}');
                return const Center(child: Text('Error loading user data.'));
              } else if (icrSnapshot.data == true) {
                // ICR info exists
                print(
                  'AuthWrapper: ICR info exists. Navigating to HomeScreen.',
                );
                return const home_screen.HomeScreen();
              } else {
                // ICR info does NOT exist
                print(
                  'AuthWrapper: ICR info missing. Navigating to IcrInfoScreen.',
                );
                return const icr_screen.IcrInfoScreen();
              }
            },
          );
        } else {
          print(
            'AuthWrapper: User is NOT signed in. Navigating to AuthScreen.',
          );
          return const AuthScreen();
        }
      },
    );
  }
}
