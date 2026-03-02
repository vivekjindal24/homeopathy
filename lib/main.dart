import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env asset
  await dotenv.load(fileName: '.env');

  // Initialise Supabase — credentials come from .env, never hard-coded
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
      detectSessionInUri: false,
    ),
  );
  // ignore: avoid_print
  print('Supabase initialized successfully');

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

/// Convenience accessor — use `supabase.from(...)` anywhere in the app.
final supabase = Supabase.instance.client;
