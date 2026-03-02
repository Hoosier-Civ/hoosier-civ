import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hoosierciv/app/router.dart';
import 'package:hoosierciv/app/theme.dart';
import 'package:hoosierciv/core/services/auth_service.dart';
import 'package:hoosierciv/data/repositories/district_repository.dart';
import 'package:hoosierciv/data/repositories/profile_repository.dart';
import 'package:hoosierciv/features/onboarding/onboarding_cubit.dart';
import 'package:hoosierciv/state/gamification_cubit.dart';
import 'package:hoosierciv/state/missions_cubit.dart';
import 'package:hoosierciv/state/user_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserCubit()),
        BlocProvider(create: (_) => MissionsCubit()),
        BlocProvider(create: (_) => GamificationCubit()),
        BlocProvider(
          create: (context) => OnboardingCubit(
            districtRepository: DistrictRepository(
              supabase: Supabase.instance.client,
            ),
            profileRepository: ProfileRepository(
              supabase: Supabase.instance.client,
            ),
            gamificationCubit: context.read<GamificationCubit>(),
            authService: SupabaseAuthService(Supabase.instance.client),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'HoosierCiv',
        theme: AppTheme.light(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
