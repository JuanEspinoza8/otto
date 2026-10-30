/// Configuración de la integración con IA (Pollinations, compatible OpenAI).
///
/// La clave NO va en el código: se inyecta al compilar con
/// `--dart-define=POLLINATIONS_KEY=...` (o `--dart-define-from-file=env.json`).
/// Si no se define, la IA queda desactivada y la app usa el parser local.
class ConfiguracionIA {
  /// Clave de Pollinations, inyectada al compilar.
  static const String apiKey = String.fromEnvironment('POLLINATIONS_KEY');

  /// Modelo de texto a usar (Pollinations: openai, openai-fast, mistral, etc.).
  static const String modelo = 'openai';

  /// Endpoint OpenAI-compatible de Pollinations.
  static const String endpoint = 'https://gen.pollinations.ai/v1/chat/completions';

  static bool get estaConfigurada => apiKey.isNotEmpty;
}
