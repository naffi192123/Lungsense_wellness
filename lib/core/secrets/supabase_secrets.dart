/// Config file that exposes Supabase API credentials.
/// This file keeps credentials centralized and decouples them from code logic.
abstract class SupabaseSecrets {
  /// Supabase project API URL.
  static const String supabaseUrl = 'https://sjqpwvgojbceivgrqcol.supabase.co';

  /// Supabase Anonymous Public Key.
  static const String supabaseAnonKey = 'sb_publishable_AxamSU1LxYnx7yNxMlgAww_biKwiC-G';
}
