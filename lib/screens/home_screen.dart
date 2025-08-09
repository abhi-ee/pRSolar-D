import 'package:flutter/material.dart';
import 'package:solar_app/widgets/feature_card.dart';
import 'package:solar_app/screens/module_mounting_screen.dart';
import 'package:solar_app/screens/cable_schedule_screen.dart';
import 'package:solar_app/screens/module_reconciliation_screen.dart'; // Import the updated reconciliation screen
import 'package:solar_app/screens/info_screen.dart';
import 'package:solar_app/screens/quality_safety_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Project Dashboard'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          // Changed from GridView.count to ListView
          padding: const EdgeInsets.all(16.0),
          children: [
            FeatureCard(
              title: 'Module Mounting System',
              icon: Icons.solar_power,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModuleMountingScreen(),
                  ),
                );
              },
            ),
            FeatureCard(
              title: 'Cable Reconciliation',
              icon: Icons.cable,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CableScheduleScreen(),
                  ),
                );
              },
            ),
            FeatureCard(
              title: 'Module Reconciliation',
              icon: Icons.compare_arrows,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModuleReconciliationScreen(),
                  ),
                );
              },
            ),
            FeatureCard(
              title: 'Information',
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoScreen()),
                );
              },
            ),
            FeatureCard(
              title: 'Quality & Safety',
              icon: Icons.security,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QualitySafetyScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
