import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/app/theme.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';

class OnboardingValuePropScreen extends StatelessWidget {
  const OnboardingValuePropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Stay connected to your government.',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              const _ValueRow(
                icon: Icons.people,
                title: 'Know who represents you',
                description:
                    'See your officials at every level — federal, state, and local — all in one place.',
              ),
              const _ValueRow(
                icon: Icons.notifications_active,
                title: 'Follow bills that matter',
                description:
                    'Get plain-English summaries of Indiana legislation and track how your officials vote.',
              ),
              const _ValueRow(
                icon: Icons.emoji_events,
                title: 'Earn badges for civic action',
                description:
                    'Call your legislators, attend town halls, and register to vote — every action earns XP.',
              ),
              const _ValueRow(
                icon: Icons.lock_outline,
                title: 'Private by default',
                description:
                    'Your data is never sold. Your account is only used to save your preferences and progress.',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppConstants.routeOnboardingAuth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardinalRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Continue to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.cardinalRed, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
