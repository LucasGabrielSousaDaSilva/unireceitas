/// Configuração do Supabase
/// IMPORTANTE: Configure estas variáveis com suas credenciais do Supabase
class SupabaseConfig {
  /// URL do seu projeto Supabase
  static const String supabaseUrl = 'https://kngdraibfylpszglknks.supabase.co';

  /// Chave pública do Supabase (anon key)
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZ2RyYWliZnlscHN6Z2xrbmtzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MTE4OTgsImV4cCI6MjA5NDE4Nzg5OH0.NZsi0nx5CghVT3yrWJ6PLcOahNxtVDwi9kB83SoEgYk';

  /// Nomes das tabelas no Supabase
  static const String usuariosTable = 'usuarios';
  static const String receitasTable = 'receitas';

  /// URL de redirect para o fluxo de recuperação de senha.
  /// - Em mobile/desktop é tratado como deep link (precisa estar registrado
  ///   nos esquemas nativos e como Redirect URL no painel Supabase →
  ///   Authentication → URL Configuration).
  /// - Em web, use a URL pública do app (ex.: https://app.unireceitas.com/reset).
  static const String passwordRecoveryRedirect =
      'io.supabase.unireceitas://reset-callback/';

  /// Valida se as credenciais foram configuradas
  static bool get isConfigured {
    return true;
  }
}
