# Pasar al cliente a la versión nueva

La versión 2 de Otto cambia el `applicationId` (de `com.example.finanzas` a
`io.github.juanespinoza8.otto`) y la firma (keystore propio en lugar de la
clave debug). Android la instala como **otra app**: los datos no pasan solos,
se llevan con el respaldo.

## Antes de empezar

- Compilar el APK de release firmado (ver "Firma del APK" en el README) con la
  URL del proxy de IA.
- Probar el respaldo del cliente en el emulador antes de tocar su teléfono:
  pedirle el archivo exportado e importarlo en una instalación limpia.

## En el teléfono del cliente

1. **App vieja → Menú → Exportar Base de Datos.** Guardar el archivo en un
   lugar fuera del teléfono (Drive, mail o WhatsApp a sí mismo). Es un JSON
   con todos los movimientos, metas, cuotas, fijos y el ahorro previo.
2. Anotar lo que la app vieja guardaba fuera de la base y el respaldo viejo no
   trae: **nombre, sueldo mensual y valor de la hora extra**.
3. **Instalar el APK nuevo.** Conviven las dos apps ("Otto" la nueva).
4. En la app nueva, completar el onboarding con el nombre, el sueldo y el
   valor de la hora extra anotados.
5. **Menú → Importar respaldo** y elegir el archivo del paso 1. La app lo
   convierte con la misma migración que se probó con la base de prueba: si
   algún saldo no cierra, no importa nada y avisa.
6. Comparar con la app vieja: disponible en pesos, saldo de cada meta, cuotas
   pagadas y los movimientos del mes. El disponible nuevo es **solo pesos**:
   el ahorro previo en dólares y las metas en dólares aparecen en la tarjeta
   "Dólares".
7. Volver a activar en Menú el bloqueo con huella y los recordatorios (piden
   permiso de nuevo).
8. Recién entonces, **desinstalar la app vieja**.

## Si algo sale mal

- La app vieja sigue instalada hasta el paso 8: no se pierde nada.
- Antes de importar, la app nueva guarda una copia de su base
  (`finanzas_antes_de_importar_<fecha>.db`) y antes de reemplazar muestra cuántos
  movimientos trae el archivo.
- Si el cliente actualiza sin pasar por el respaldo (misma app y firma), la
  migración corre al abrir: copia el archivo (`finanzas_respaldo_v8.db`),
  verifica los saldos antes de confirmar y, si no cierran, deja la base como
  estaba y muestra una pantalla para compartir la copia.
