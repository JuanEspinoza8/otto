/// Configuración de la integración con IA.
///
/// La app no guarda ninguna clave: habla con un proxy propio (ver `proxy/`)
/// que agrega la clave de Pollinations y limita el uso. La URL del proxy se
/// inyecta al compilar con `--dart-define-from-file=env.json`. Si no se
/// define, la IA queda desactivada y el chat usa el parser local.
class ConfiguracionIA {
  /// URL del proxy de IA (compatible con la API de chat de OpenAI).
  static const String endpoint = String.fromEnvironment('OTTO_IA_URL');

  /// Token opcional que el proxy exige en `X-Otto-Token`.
  static const String tokenApp = String.fromEnvironment('OTTO_IA_TOKEN');

  /// Modelo de texto a usar (Pollinations: openai, openai-fast).
  static const String modelo = 'openai';

  static bool get estaConfigurada => endpoint.isNotEmpty;

  static Map<String, String> get encabezados => {
        'Content-Type': 'application/json',
        if (tokenApp.isNotEmpty) 'X-Otto-Token': tokenApp,
      };
}
