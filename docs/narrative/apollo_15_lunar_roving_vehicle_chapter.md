# Starlight Legacy — Recuerdo 05: las ruedas que conquistaron la Luna

**Estado:** implementación en rama `feat/005a-discovery-archive`; revisión estática inicial, sin validación local Godot ni capturas.  
**Fecha:** 22 de octubre de 2026.  
**Precedencia jugable:** Pathfinder/Sojourner → Vanguard 1 → Surveyor 1 → Apollo 11 → Apollo 15.

## Historia real — únicamente hechos respaldados por NASA

- Apollo 15 fue la primera misión que utilizó el **Lunar Roving Vehicle (LRV)** sobre la superficie lunar, el **31 de julio de 1971**.
- Los astronautas **David Scott y James Irwin** lo condujeron en la zona **Hadley–Apennine**, donde realizaron tres recorridos.
- Era un vehículo **eléctrico, tripulado, con cuatro ruedas y dos asientos**, concebido para ampliar el alcance de los trabajos geológicos y transportar material.
- Sus ruedas eran **mallas de alambre metálico flexible** con bandas de tracción; no eran neumáticos convencionales inflados. La NASA también describe estructura plegable para trasladarlo en el módulo lunar.
- El vehículo permaneció en la Luna tras la misión; **Sojourner (1997)** fue un rover robótico de Marte distinto del LRV tripulado de 1971.

Fuentes oficiales NASA:
- [NASA — First Use of the Lunar Roving Vehicle, July 31, 1971](https://www.nasa.gov/image-article/this-week-nasa-history-first-use-of-lunar-roving-vehicle-july-31-1971/)
- [NASA — Apollo 15 Mission Details](https://www.nasa.gov/missions/apollo/apollo-15-mission-details/)
- [NASA — Apollo 15 Mission Report, sección A.3.2](https://www.nasa.gov/wp-content/uploads/static/history/alsj/a15/ap15mr.pdf)
- [NASA — Lunar Roving Vehicle, wire-mesh wheels](https://nssdc.gsfc.nasa.gov/planetary/lunar/apollo_lrv.html)
- [NASA — Lunar Roving Vehicle educator guide](https://ntrs.nasa.gov/api/citations/19950005259/downloads/19950005259.pdf)

## Puente narrativo — taller → abuelo → recuerdo

### Fallo del Vehículo Explorador de Rescate

Tras instalar el acoplamiento liberable inspirado en Apollo 11, el vehículo escolar ya puede abandonar su base auxiliar. Pero una nueva zona de la prueba, con arena suelta y piedras, hace que sus ruedas **giren sin avanzar correctamente**.

El problema no se resuelve necesariamente con más potencia: el contacto rueda-terreno y la distribución de carga requieren atención.

### Diálogo del abuelo (ficción)

El abuelo recuerda cómo Scott e Irwin recorrieron la Luna en Apollo 15 con un vehículo muy especial. Comenta las **cuatro ruedas de malla metálica** y el transporte de equipos científicos. Invita a examinar un modelo provisional para entender por qué un vehículo necesita equilibrio y ruedas adecuadas a su entorno.

### Recuerdo 05 — Hadley–Apennine (1971)

Se muestra un modelo **greybox** del LRV con cuatro ruedas, dos asientos, antena, cámara y equipos. No es una réplica a escala exacta ni el escenario es topografía auténtica.

**Desafío progresivo:**

1. Elegir **ruedas de malla metálica con bandas** en lugar de imaginar que el LRV llevaba neumáticos inflados y lisos.
2. **Repartir la carga** en la maqueta escolar para evitar concentrarla sobre una esquina (regla didáctica, no simulación de la estructura específica de Apollo 15).
3. Seleccionar un **recorrido controlado** por un terreno irregular (no se reproduce el perfil real de las excursiones).

Solo después de acertar se reproduce un desplazamiento simplificado, se registra el descubrimiento `apollo_15_lrv` y aparece el portal de regreso.

**Continuar / Saber más:** las mismas opciones de los capítulos anteriores; el Archivo mantiene 1971 en su lugar cronológico, aunque el orden jugable obedezca a dificultad.

### Regreso y mejora del proyecto

El vehículo escolar incorpora **ruedas con agarre y una distribución de carga revisada**, `rescue_rover_traction_upgrade`. No reproduce material por material el diseño aeroespacial: aprovecha el **principio** de adaptar ruedas al suelo y distribuir peso.

Conservar: amortiguación de Pathfinder, energía de Vanguard 1, cámara y panel orientables de Surveyor 1, liberación modular de Apollo 11.

## Contratos de código

| Elemento | Archivo o ID |
| --- | --- |
| Problema | `rescue_rover_traction_problem` |
| Abuelo | `grandfather_apollo_15` |
| Recuerdo | `levels/apollo_15/apollo_15_memory.tscn` |
| Greybox | `levels/apollo_15/apollo_15_lrv_greybox.tscn` |
| Consola | `systems/gameplay/apollo_15_traction_console.gd` |
| Descubrimiento | `apollo_15_lrv` |
| Mejora del rover escolar | `rescue_rover_traction_upgrade` |
| Prueba pendiente de ejecutar | `tests/apollo_15_lrv_story_loop_smoke.gd` |

## Criterios de aceptación y pendientes

- [x] Nueva escena independiente; no sustituye Ares Vallis ni los recuerdos anteriores.
- [x] Identificador histórico reutilizado del catálogo cronológico.
- [x] Tracción desbloqueada solo tras aplicar mejora modular de Apollo 11.
- [x] Escena, narrativa, diálogo, Archivo NASA y mejora del taller conectados en código.
- [x] Prueba de ciclo preparada: respuestas incorrectas, ruedas, carga, recorrido, regreso, progreso y conservación de mejoras previas.
- [ ] Compilar escenas Godot y ejecutar smoke tests en Desktop.
- [ ] Verificar Web/Compatibility, colisiones, raycast de interacción y HUD en pantalla pequeña.
- [ ] Revisar en vivo las proporciones del greybox, suelo y tracción; más adelante reemplazar por un modelo de Blender.

**No marcar capítulo como aprobado ni fusionar sin ejecución y revisión visual posteriores.**
