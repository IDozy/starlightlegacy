# Auditoría del Capítulo I — sesión 2026-10-23

## Revisión inicial sin abrir Godot
Rama: `feat/005a-discovery-archive` · PR #13. Capítulo I desde Pathfinder/Sojourner hasta la feria, cliffhanger y Saber más InSight. Esta auditoría es del código GitHub, no ejecución local.

### Incidencias confirmadas y correcciones
- **Bloqueo de sintaxis en `knowledge_registry.gd`:** el registro opcional de InSight tenía una llave de cierre `}` adicional antes de Ingenuity. Corregido en la definición del catálogo; antes podía impedir importar el autoload.
- **Pérdida de progreso:** los descubrimientos y las diez mejoras se almacenaban exclusivamente en dos variables en memoria, `_discoveries` y `_discovery_order`. Al reiniciar el proceso se perdían. Se implementó persistencia local `user://starlight_legacy_chapter1_v1.json`, formato versionado V1, guardado después de cada descubrimiento, archivo temporal y respaldo `.bak`, recarga al abrir y recuperación desde respaldo de JSON inválido. No se guarda estado de controles/transiciones a mitad de escena: al reabrir se regresa al taller con los descubrimientos ya logrados.
- **Aislamiento de test headless:** el autoload omite carga y escritura del progreso en `--headless`, para evitar que los smoke tests contaminen la partida real. Prueba dedicada usa ruta temporal única y limpia sus archivos.

### Contrato de progreso
- Restaurar descubrimientos y su orden una sola vez; impedir duplicados.
- Reconstruir el catálogo NASA desde código en cada carga; guardar solo `id, title, category, summary`.
- Preservar entrada de feria `rescue_rover_science_fair_completed`, InSight opcional y documentos históricos.
- No sobrescribir partida cuando el JSON tiene esquema inválido o versión desconocida.
- Conservar respaldo si existe una instantánea anterior válida.
- Proteger juegos actuales de un test automatizado por comandos headless.
- Evitar declaración de `BUILD SUCCESS` hasta ejecutar Godot.

### Pruebas aún pendientes
```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/chapter1_persistence_smoke.gd
```
Después: recorrer escenas reales, verificar botón K/Archivo NASA, comprobar cierre de juego y reapertura, caja de capítulo II, InSight opcional y exportación Web. Ejecutar también smoke tests existentes y comprobar rutas/colisiones/modelos.

### Modelos definitivos por revisar
Taller NASA `Taller_NASA_v02.glb`, terreno Ares Vallis, Pathfinder + Sojourner, Vanguard 1, Surveyor 1, Apollo 11, Apollo 15 LRV, Viking 1, Spirit, Opportunity, Sky Crane/Perseverance, Ingenuity, InSight opcional, feria y caja misteriosa. Los modelos greybox preservan lógica provisional, **no son aprobación de escala, animaciones ni ciencia visual**.
