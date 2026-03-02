import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/app/theme.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Mascot — replace with Image.asset('assets/indy_cardinal.png')
              // once the illustration is available.
              const Text(
                '🐦',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 96),
              ),
              const SizedBox(height: 24),
              Text(
                'HoosierCiv',
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge?.copyWith(
                  color: AppTheme.cardinalRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Indiana civic engagement in your pocket.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () =>
                    context.go(AppConstants.routeOnboardingAddress),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text("Let's Go"),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
