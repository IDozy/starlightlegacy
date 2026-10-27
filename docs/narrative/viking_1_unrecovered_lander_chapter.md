# Starlight Legacy — Recuerdo 06: Viking 1, una pregunta sin respuesta definitiva

**Estado:** capítulo integrado en `feat/005a-discovery-archive`; referencias revisadas en código, **Godot Desktop/Web y smoke test pendientes de ejecutar**.  
**Fecha:** 22 de octubre de 2026.  
**Orden jugable:** Pathfinder/Sojourner → Vanguard 1 → Surveyor 1 → Apollo 11 → Apollo 15 → Viking 1.  
**Regla del proyecto:** solo objetos reales que permanecieron fuera de la Tierra, **nunca recuperados**.

## Verificación del artefacto — fuentes oficiales NASA

- **Viking 1 Lander** aterrizó el **20 de julio de 1976**, en **Chryse Planitia**, Marte. Es un **aterrizador**, no un rover.
- El aparato científico utilizó un brazo para tomar muestras de suelo el **28 de julio de 1976**. Incluía experimentos biológicos y análisis químico.
- La arquitectura física del lander era un cuerpo **hexagonal, tres patas**, dos cámaras de barrido, un brazo recolector, antenas y **dos generadores termoeléctricos de radioisótopos (RTG)**. **No tenía ruedas ni dependía de paneles solares.**
- Los experimentos observaron **actividad química desconcertante**, pero **no ofrecieron pruebas concluyentes de vida marciana**. No afirmar ni que descubrió vida, ni que se demostró que Marte no tiene vida.
- **Últimas comunicaciones:** noviembre de **1982**. La nave **no fue recuperada**: permanece en Marte. El Mars Reconnaissance Orbiter la volvió a identificar desde órbita, junto a indicios de su backshell y escudo térmico.

Fuentes NASA:
- [Viking 1, cronología y datos de instrumentos](https://science.nasa.gov/mission/viking-1/)
- [Viking Spacecraft and Science — equipos del aterrizador](https://science.nasa.gov/mission/viking/spacecraft-and-science/)
- [Viking Project y resultados biológicos](https://science.nasa.gov/astrobiology/missions/viking-project/)
- [Viking Lander 1 fotografiado desde órbita, NASA Photojournal](https://science.nasa.gov/photojournal/viking-lander-1-thomas-a-mutch-memorial-station-imaged-from-orbit/)
- [Informe de resultados de los experimentos Viking, NASA NTRS](https://ntrs.nasa.gov/citations/19760062481)

## Desarrollo narrativo — ciencia antes que suposiciones

### Intento / fallo en el taller

El Vehículo Explorador de Rescate ya soporta impactos, administra energía, orienta cámara, libera su base y puede desplazarse por suelo irregular.

En la siguiente prueba, un sensor escolar registra una **reacción química simulada** y el niño está a punto de anunciar que detectó vida, aunque no tiene pruebas de qué produjo esa señal.

**El fallo es intelectual y de instrumentación**, no de descenso ni movilidad: falta contrastar lecturas y registrar evidencias.

### Abuelo (diálogo escrito para el juego)

El abuelo relata que Viking 1 quedó en Marte después de investigar el terreno. En 1976 su laboratorio tomó muestras y encontró actividad química difícil de interpretar. La misión **no demostró vida**. Invita a estudiar por qué los científicos comparan varios resultados y reconocen la incertidumbre.

### Recuerdo 06 — Chryse Planitia (1976)

Reconstrucción estilizada de terreno marciano; **no** se presenta como cartografía exacta. Modelo provisional del lander con cuerpo hexagonal, tres patas, brazo, cámaras, antena, RTGs y módulos de análisis.

La consola educativa desarrolla tres acciones:

1. **Recoger suelo con brazo robótico**, no con astronautas que no participaron en Viking 1.
2. **Contrastar la señal con más pruebas y posibles explicaciones**. Se marca como inventada la reacción del minijuego; **no simula la telemetría real**.
3. **Concluir con cuidado:** actividad interesante pero no evidencia definitiva de vida.

Solo después de la tercera etapa se concede `viking_1`; la ficha aparece en 1976 dentro del Archivo NASA y el portal de regreso se habilita. «Continuar / Saber más» usa los controles comunes.

### Regreso / proyecto del niño

La solución aplicable **no copia el laboratorio real**: incorpora bandejas escolares para comparar muestras y un registrador, `rescue_rover_science_verification_upgrade`, evitando presentar resultados únicos como prueba suficiente.

Se conserva la evolución anterior: amortiguación, energía solar del vehículo del niño, cámara regulable, base auxiliar liberable y ruedas con agarre.

## Contratos y rutas

| Componente | Archivo o identificador |
| --- | --- |
| Fallo de taller | `rescue_rover_science_verification_problem` |
| Diálogo del abuelo | `grandfather_viking_1` |
| Recuerdo jugable | `levels/viking_1/viking_1_memory.tscn` |
| Greybox del lander | `levels/viking_1/viking_1_lander_greybox.tscn` |
| Laboratorio jugable | `systems/gameplay/viking_1_science_console.gd` |
| Descubrimiento del Archivo | `viking_1` |
| Mejora en el taller | `rescue_rover_science_verification_upgrade` |
| Smoke test (sin ejecutar) | `tests/viking_1_science_story_loop_smoke.gd` |

## Condiciones de aceptación

- [x] Objeto físico no recuperado, destino corroborado por NASA.
- [x] Mecánica distinta de Sojourner APXS: **interpretar evidencias**.
- [x] Modelo no mezcla tecnologías de otras misiones (3 patas, RTG, no rover).
- [x] Integración de progresión después de Apollo 15, diálogo, Archivo y mejora.
- [x] Rechazo de opciones históricamente falsas y conclusiones sin evidencia.
- [x] Prueba de flujo y regresión de mejoras anteriores creada.
- [ ] Compilar y ejecutar Godot local/Desktop/Web; corregir eventuales errores.
- [ ] Validar controles, colisiones, HUD, guardado y posiciones visuales.
- [ ] Revisar capturas y modelar versión definitiva en Blender.

**No fusionar ni afirmar aprobado hasta completar las validaciones aplazadas.**
