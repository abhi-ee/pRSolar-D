import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    // Set a max width for desktop-like views, allowing cards to be centered
    final cardWidth = screenWidth > 600
        ? 500.0
        : screenWidth * 0.9; // Max 500px or 90% of screen width

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // Consistent vertical margin
      child: InkWell(
        // Makes the entire card tappable with a ripple effect
        onTap: onTap,
        borderRadius: BorderRadius.circular(15), // Match card border radius
        child: Container(
          width: cardWidth, // Apply responsive width
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 60, // Larger icon size
                color: Theme.of(
                  context,
                ).primaryColor, // Use primary color for icons
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge, // Use theme's titleLarge style
              ),
            ],
          ),
        ),
      ),
    );
  }
}
