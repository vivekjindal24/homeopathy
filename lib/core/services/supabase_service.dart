import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the Supabase client as a Riverpod provider.
///
/// All repository classes must depend on this provider instead of
/// accessing [Supabase.instance.client] directly.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

