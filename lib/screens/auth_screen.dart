// lib/screens/auth_screen.dart (NEW FILE)
import 'package:flutter/material.dart';
import 'package:solar_app/screens/sign_in_screen.dart';
import 'package:solar_app/screens/sign_up_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Light sky-blue background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Company Name (ReNew) - Replicated from Splash Screen for branding
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Re',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF006400), // Dark green
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'New',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF32CD32), // Light green
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'Welcome to Solar Project App!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.blueGrey[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    55,
                  ), // Full width button
                ),
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                // Using OutlinedButton for sign up to differentiate
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  side: const BorderSide(
                    color: Colors.blueAccent,
                    width: 2,
                  ), // Blue border
                  foregroundColor: Colors.blueAccent, // Blue text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
