import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hoosierciv/app/router.dart';
import 'package:hoosierciv/app/theme.dart';
import 'package:hoosierciv/state/gamification_cubit.dart';
import 'package:hoosierciv/state/missions_cubit.dart';
import 'package:hoosierciv/state/user_cubit.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserCubit()),
        BlocProvider(create: (_) => MissionsCubit()),
        BlocProvider(create: (_) => GamificationCubit()),
      ],
      child: MaterialApp.router(
        title: 'HoosierCiv',
        theme: AppTheme.light(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
