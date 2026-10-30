# Proxy de IA de Otto

Cloudflare Worker que guarda la clave de Pollinations y reenvía los pedidos de
la app. La app no tiene ninguna clave: solo conoce la URL del Worker.

Qué controla:

- agrega la clave (`POLLINATIONS_KEY`, guardada como secreto del Worker);
- acepta solo `POST` con JSON de hasta 16 KB y reenvía solo los campos que usa la app;
- limita el modelo (`openai`, `openai-fast`) y `max_tokens` (600);
- limita a 10 pedidos por minuto por IP;
- opcionalmente exige el encabezado `X-Otto-Token` (secreto `APP_TOKEN`);
- no reenvía los mensajes de error del proveedor.

## Desplegar

Requiere una cuenta de Cloudflare (el plan gratis alcanza) y Node.js.

```bash
cd proxy
npx wrangler login
npx wrangler secret put POLLINATIONS_KEY   # pegá la clave nueva
npx wrangler secret put APP_TOKEN          # opcional: cualquier texto largo al azar
npx wrangler deploy
```

`wrangler deploy` imprime la URL (`https://otto-ia-proxy.<tu-subdominio>.workers.dev`).
Esa URL, y el token si lo usaste, se pasan a la app al compilar (ver el README
principal).

Además, conviene ponerle un tope de gasto a la clave desde el panel de
Pollinations.

## Probar en local

```bash
cd proxy
echo "POLLINATIONS_KEY=tu_clave" > .dev.vars
npx wrangler dev
```

Desde el emulador de Android, el Worker local queda en `http://10.0.2.2:8787`.
