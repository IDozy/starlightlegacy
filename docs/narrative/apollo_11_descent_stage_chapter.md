# Starlight Legacy · Recuerdo 04: Apollo 11, la etapa que se quedó

**Estado:** implementado en rama `feat/005a-discovery-archive`; pendiente de pruebas locales Godot Desktop y Web, revisión visual y aprobación.  
**Fecha de seguimiento:** 22 de octubre de 2026.  
**Precedencia jugable:** Pathfinder + Sojourner → Vanguard 1 → Surveyor 1 → Apollo 11.  
**Orden del Archivo NASA:** cronológico, independientemente del orden jugable.

## Hechos históricos confirmados

- Apollo 11 despegó de la Tierra el **16 de julio de 1969** y el módulo lunar `Eagle` alunizó en el **Mar de la Tranquilidad** el **20 de julio**.
- El módulo lunar estaba dividido en **etapa de descenso** y **etapa de ascenso**. La etapa inferior incluía las **cuatro patas** y el sistema que permitía alunizar.
- El **21 de julio de 1969**, Armstrong y Aldrin despegaron desde la superficie en la **etapa superior**, utilizando la etapa de descenso como **plataforma de lanzamiento**.
- La etapa inferior **permaneció** en la superficie. La superior alcanzó la órbita lunar y se reunió con el módulo de mando `Columbia`. No se describe al módulo completo despegando.
- El desafío interactivo, sus opciones, tiempos y animación son una **analogía didáctica**; no reproduce los comandos auténticos de la cabina ni la velocidad real de despegue.

Fuentes oficiales:
- [NASA · Apollo 11 Mission Overview](https://www.nasa.gov/missions/apollo/apollo-11/apollo-11-mission-overview/)
- [NASA · Apollo's Lunar Module Bridged Technological Leap to the Moon](https://www.nasa.gov/history/apollos-lunar-module-bridged-technological-leap-to-the-moon/)
- [NASA · Apollo 11 — The Journey Home](https://www.nasa.gov/history/50-years-ago-apollo-11-the-journey-home/)
- [NASA · Apollo 11 Lunar Surface Journal](https://nasa.gov/wp-content/uploads/static/history/alsj/a11/a11ov.html)

## Historia jugable

### Intento y fallo en el taller

El **Vehículo Explorador de Rescate** ya amortigua impactos, gestiona energía solar y orienta una cámara. Para simular su despliegue antes de la feria, está unido a una base auxiliar de transporte. En la prueba final, las ruedas funcionan, pero la base permanece fijada; el rover **no puede iniciar la misión**.

### Conversación del abuelo

El abuelo presenta las dos etapas del `Eagle`. Distingue que la **inferior** permitió aterrizar y sirvió después como plataforma, mientras la **superior** trasladó a los astronautas de vuelta a la órbita. Los diálogos son **ficción** basada en hechos NASA, no frases históricas atribuidas a participantes reales.

### Recuerdo 04 · 1969

**Lugar:** reconstrucción estilizada del Mar de la Tranquilidad, sin fingir cartografía exacta.

El jugador ve un modelo greybox del `Eagle` con dos conjuntos jerárquicos independientes, `DescentStage` y `AscentStage`. En la consola educativa debe:

1. Identificar qué etapa permaneció en la Luna (descenso, no ascenso).
2. Conservar la plataforma de cuatro patas estable (no retirar los apoyos).
3. Decidir separar las etapas (no despegar con las dos).
4. Activar la animación **didáctica**: solo `AscentStage` asciende; `DescentStage` permanece sobre la superficie.

Solo al terminar se desbloquea `apollo_11_descent_stage` en el Archivo NASA y aparece el portal de regreso. Las respuestas erróneas muestran explicaciones y no otorgan el descubrimiento.

**Continuar / Saber más:** con `Saber más` el Archivo NASA muestra Historia, Ingeniería y Tu proyecto; `Continuar` mantiene el regreso.

### Aplicación en el proyecto del niño

El Vehículo Explorador de Rescate de la feria **no es una nave espacial**. La adaptación es un mecanismo de **desacoplamiento de su base auxiliar de transporte**: queda una base sobre el suelo y el rover continúa con ruedas, panel solar, cámara orientable y protección de impactos. Es una idea de ingeniería modular inspirada en las dos etapas del `Eagle`, **no una representación literal de la misión**.

Al elegir una solución incorrecta (quitar las ruedas) no se desbloquea nada. El acoplamiento liberable correcto registra `rescue_rover_modular_release_upgrade`.

## Contratos y rutas

| Elemento | Ruta / ID |
| --- | --- |
| Problema en el taller | `rescue_rover_module_separation_problem` |
| Diálogo abuelo | `grandfather_apollo_11` |
| Recuerdo jugable | `levels/apollo_11/apollo_11_memory.tscn` |
| Greybox independiente | `levels/apollo_11/apollo_11_lunar_module_greybox.tscn` |
| Consola | `systems/gameplay/apollo_11_stage_console.gd` |
| Descubrimiento histórico | `apollo_11_descent_stage` |
| Mejora del proyecto | `rescue_rover_modular_release_upgrade` |
| Prueba de ciclo | `tests/apollo_11_stage_story_loop_smoke.gd` |

## Criterios de aceptación

- [x] La rama contiene scripts y escenas enlazados al mismo sistema de personaje, diálogo y Archivo NASA.
- [x] Los archivos separan claramente visual de descenso y ascenso.
- [x] La lógica impide registrar Apollo antes de comprobar las etapas y simular el ascenso.
- [x] Se añade prueba de regresión de descubrimientos y mejoras Pathfinder, Vanguard y Surveyor.
- [ ] **Pendiente:** compilar y ejecutar en Godot, corregir parse errors, ejecutar la prueba de ciclo y probar ratón/teclado en Desktop.
- [ ] **Pendiente:** probar el render Web/Compatibility, colisiones, distancias de interacción y velocidad de animación.
- [ ] **Pendiente:** revisar capturas, reemplazar greybox por un modelo Blender detallado y comprobar rendimiento.

**No fusionar a main ni dar por cerrado sin validación.**
