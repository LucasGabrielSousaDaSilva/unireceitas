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
  /// Configurada para desenvolvimento local em Chrome — a mesma URL precisa
  /// estar cadastrada em Authentication → URL Configuration → Redirect URLs.
  /// A porta precisa bater com a usada em `flutter run -d chrome --web-port=8080`.
  static const String passwordRecoveryRedirect =
      'http://localhost:8080/#/redefinir-senha';

  /// Valida se as credenciais foram configuradas
  static bool get isConfigured {
    return true;
  }
}
