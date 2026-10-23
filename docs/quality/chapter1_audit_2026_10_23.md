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

## Hallazgos adicionales — selección del Archivo NASA
- Codex había documentado dos fallos P2 en el PR #13. El primero (los descubrimientos de **proyecto** que no aparecían en la línea temporal) ya estaba resuelto mediante la sección de tarjetas `archive_kind: project`.
- El segundo continuaba vigente: `_find_latest_discovered_index()` elegía el último índice visual; como las tarjetas del proyecto se anexan después del catálogo cronológico, al abrir K podía saltar a un progreso antiguo en lugar de Pathfinder o el recuerdo recién recuperado.
- Se cambió la elección para recorrer `get_discoveries()` **desde el registro más reciente** y localizar ese ID entre las tarjetas del Archivo. Se preparó `tests/archive_recency_smoke.gd` con casos NASA → proyecto → InSight opcional. No ejecutado.

## Inspección estática ampliada
- 56 scripts GDScript de sistema, escenas, niveles y tests revisados con un escaneo independiente de delimitadores (cadenas/comentarios excluidos) y funciones repetidas: **sin nuevos errores de delimitadores ni funciones duplicadas tras corregir InSight**. Esta revisión NO sustituye al parser de Godot.
- Se revisaron enlaces de escenas principales: Taller → Ares Vallis/otros nueve recuerdos → taller → feria → teaser opcional / InSight opcional. Se comprobarán rutas e interacciones reales después.
- PR #13 continúa abierto; la última actividad de Codex es anterior a múltiples cambios posteriores de la rama. **No hay revisión actual aprobada de estos últimos commits.**

## Inventario real de recursos y modelos
### Importaciones propias ya presentes en GitHub
- `assets/models/taller/Taller_NASA_v02.glb` — taller (forma y geometría ya integradas, requiere validación de escala, colisiones, iluminación).
- `assets/models/taller/Sojourner_v01.glb` — rover Sojourner, verificar alineación/cámara/ruedas.
- `assets/models/taller/Starlight_AresVallis_Desarrollo_v33.blend.glb` — terreno de referencia/prototipo; junto a `assets/terrain/ares_vallis/nasa_pathfinder_preview.obj` (verificar importación y cargas).
- `assets/models/taller/rover.blend` — archivo fuente Blender de trabajo, no tratar como modelo listo para todas las escenas.
### Greyboxes (por completar/validar visualmente)
- Pathfinder y sus accesorios de descenso; Vanguard 1; Surveyor 1; Apollo 11; Apollo 15 LRV; Viking 1; Spirit; Opportunity; Sky Crane/Perseverance; Ingenuity; InSight (opcional).
- Escenario feria escolar, rover acumulativo, escenario del adelanto del Capítulo II y caja misteriosa.
- Todos requieren revisión de geometría, correcta época NASA, colisiones, orientación, escalas, materiales, iluminación y animaciones. La implementación de un greybox no equivale a un modelo validado.

## Runner de validación preparado — no ejecutado
Se añade `scripts/chapter1_validate.ps1` que importa el proyecto con Godot en modo headless y ejecuta **16 smoke tests** uno por uno, abortando ante el primer fallo. Ejecutar en Windows PowerShell al retomar la computadora:
```powershell
./scripts/chapter1_validate.ps1 -GodotBinary "C:\ruta\Godot.exe"
```
Después de tests unitarios/headless, ejecutar Desktop y exportación Web para controles, diálogo, Archivo NASA, partida guardada, portal/cámaras/colisiones y objetos. El script no reemplaza la validación visual.

## Estado y definición de terminado (no alcanzada)
- Código corregido y tests preparados ≠ BUILD SUCCESS.
- Capítulo I **no validado** hasta importar y ejecutar las pruebas; la segunda parte continúa como adelanto, no implementada.
- Cerrar PR únicamente tras resolver fallos Godot, comprobar historia principal de extremo a extremo y validar modelos mínimos necesarios.
