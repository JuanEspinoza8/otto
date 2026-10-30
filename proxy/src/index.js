// Proxy mínimo entre la app y Pollinations.
//
// La clave de Pollinations vive solo acá (secreto POLLINATIONS_KEY del
// Worker). La app nunca la ve: manda el pedido sin clave y este Worker la
// agrega, limita el tamaño, el modelo y la cantidad de pedidos por IP.

const UPSTREAM = 'https://gen.pollinations.ai/v1/chat/completions';
const MODELOS_PERMITIDOS = new Set(['openai', 'openai-fast']);
const MAX_BYTES = 16 * 1024;
const MAX_TOKENS = 600;

function json(cuerpo, status) {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return json({ error: 'Método no permitido' }, 405);
    }

    // Token de la app (opcional). No es un secreto fuerte, porque viaja en el
    // APK, pero corta el abuso casual de la URL.
    if (env.APP_TOKEN && request.headers.get('X-Otto-Token') !== env.APP_TOKEN) {
      return json({ error: 'No autorizado' }, 401);
    }

    if (env.LIMITADOR) {
      const ip = request.headers.get('CF-Connecting-IP') ?? 'sin-ip';
      const { success } = await env.LIMITADOR.limit({ key: ip });
      if (!success) return json({ error: 'Demasiados pedidos' }, 429);
    }

    const texto = await request.text();
    if (texto.length > MAX_BYTES) {
      return json({ error: 'Pedido demasiado grande' }, 413);
    }

    let pedido;
    try {
      pedido = JSON.parse(texto);
    } catch {
      return json({ error: 'JSON inválido' }, 400);
    }
    if (!Array.isArray(pedido.messages) || pedido.messages.length === 0) {
      return json({ error: 'Falta messages' }, 400);
    }

    // Solo se reenvían los campos que usa la app.
    const limpio = {
      model: MODELOS_PERMITIDOS.has(pedido.model) ? pedido.model : 'openai',
      messages: pedido.messages,
      temperature: typeof pedido.temperature === 'number' ? pedido.temperature : 0.3,
      max_tokens: Math.min(Number(pedido.max_tokens) || MAX_TOKENS, MAX_TOKENS),
    };
    if (pedido.response_format?.type === 'json_object') {
      limpio.response_format = { type: 'json_object' };
    }

    const respuesta = await fetch(UPSTREAM, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${env.POLLINATIONS_KEY}`,
      },
      body: JSON.stringify(limpio),
    });

    // Los errores del proveedor no se reenvían: pueden traer datos de la cuenta.
    if (!respuesta.ok) {
      return json({ error: 'El servicio de IA no respondió' }, 502);
    }
    return new Response(respuesta.body, {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};
