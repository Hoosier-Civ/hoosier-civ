import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hoosierciv/app/app_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet — google-services.json added in a later step.
  }
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
  runApp(const AppWidget());
}
