# Scaffold Flutter Feature

Scaffold a new Flutter feature for the HoosierCiv app following the established architecture pattern.

## Instructions

The user will provide a feature name (e.g. "town_hall", "volunteer", "micro_lesson").

1. Read `HoosierCiv_Flutter_MVP_Architecture.txt` to confirm the existing folder conventions.
2. Generate the following files for the feature using the naming and structure conventions from the architecture file:

**Feature folder:** `lib/features/<feature_name>/`

Files to create:
- `<feature_name>_screen.dart` — Main screen widget (StatelessWidget using BlocBuilder)
- `<feature_name>_cubit.dart` — Cubit with states: Initial, Loading, Loaded, Error
- `<feature_name>_state.dart` — Sealed state classes for the cubit

**Data layer:**
- `lib/data/models/<feature_name>_model.dart` — Dart model with `fromJson` / `toJson`
- `lib/data/repositories/<feature_name>_repository.dart` — Repository that calls Supabase

## Conventions to Follow
- Use `flutter_bloc` with Cubit (not full Bloc)
- Models use `freezed` or plain Dart classes with named constructors
- Repositories inject `SupabaseClient` via constructor
- Screens use `context.read<FeatureCubit>()` for event dispatch
- All screens accept no required constructor params (navigation args via GoRouter `extra`)
- Add a `// TODO: wire to router` comment in the screen file

## Output
Generate all files with placeholder implementation and clear TODO comments. Do not add files to the router — note that as a next step for the user.

$ARGUMENTS
