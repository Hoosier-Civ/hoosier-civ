import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/app/theme.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/features/onboarding/onboarding_cubit.dart';

/// Available civic interest categories.
enum CivicInterest {
  voting(label: 'Voting', icon: Icons.how_to_vote),
  legislation(label: 'Legislation', icon: Icons.gavel),
  community(label: 'Community', icon: Icons.people),
  education(label: 'Education', icon: Icons.school);

  const CivicInterest({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class InterestSelectScreen extends StatefulWidget {
  const InterestSelectScreen({super.key});

  @override
  State<InterestSelectScreen> createState() => _InterestSelectScreenState();
}

class _InterestSelectScreenState extends State<InterestSelectScreen> {
  final Set<CivicInterest> _selected = {};

  void _toggle(CivicInterest interest) {
    setState(() {
      if (_selected.contains(interest)) {
        _selected.remove(interest);
      } else {
        _selected.add(interest);
      }
    });
  }

  void _continue(BuildContext context) {
    context.read<OnboardingCubit>().selectInterests(
          _selected.map((i) => i.name).toList(),
        );
    context.go(AppConstants.routeOnboardingAuth);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Interests')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What topics matter most to you?',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select at least one to personalize your experience.',
                style:
                    textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: CivicInterest.values
                      .map(
                        (interest) => _InterestCard(
                          interest: interest,
                          selected: _selected.contains(interest),
                          onTap: () => _toggle(interest),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _selected.isEmpty ? null : () => _continue(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  static const Color _selectedShadowColor = Color.fromARGB(51, 200, 16, 46);

  final CivicInterest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppTheme.cardinalRed : Colors.white,
          border: Border.all(
            color: selected ? AppTheme.cardinalRed : Colors.black26,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _selectedShadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              interest.icon,
              size: 40,
              color: selected ? Colors.white : colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              interest.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
