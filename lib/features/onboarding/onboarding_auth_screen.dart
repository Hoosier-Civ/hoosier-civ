import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/features/onboarding/onboarding_cubit.dart';

// Stub — implemented in issue #8.
class OnboardingAuthScreen extends StatelessWidget {
  const OnboardingAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<OnboardingCubit>().reset();
              context.go(AppConstants.routeOnboarding);
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: const Center(child: Text('OnboardingAuthScreen')),
    );
  }
}
