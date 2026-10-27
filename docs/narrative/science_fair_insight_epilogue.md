# Starlight Legacy — Fin del Capítulo I: El primer legado (feria + InSight opcional)

**Estado:** propuesta de cierre **implementada como guion y greybox** en rama `feat/005a-discovery-archive`. No se ejecutaron Godot Desktop/Web ni E2E. No fusionar ni marcar validado.

## Final del Capítulo I, NO final de Starlight Legacy
Tras recuperar Ingenuity y añadir el explorador aéreo auxiliar, el niño regresa al taller. Se habilita un portal a la **feria de ciencias**: escenario independiente del taller con un rover expositor que refleja las mejoras registradas.

La presentación tiene **cuatro pasos**: seguridad del suelo, gestión energética, liberación después de tocar superficie y exploración más verificación científica. Todos los 10 descubrimientos de mejora acumulados son requisitos; saltarse cualquiera impide declarar completada la exhibición. Las elecciones incorrectas bloquean el avance.

**Final ficticio (abuelo):** «No has construido un rover de la NASA. Has aprendido a solucionar problemas escuchando las historias de quienes lo intentaron antes». La feria se registra como **proyecto escolar** `rescue_rover_science_fair_completed`, no como artefacto NASA. El jugador puede seguir consultando Archivo K, regresar al taller o elegir **Continuar / Saber más**.

## Ruta opcional InSight
Tras ganar la feria, un portal extra conduce a la reconstrucción educativa de **InSight y el sismómetro SEIS**. No es requisito de ningún final. Se elige colocar el sensor sobre suelo, protegerlo del viento y ruido, y reconocer la fecha real de final de misión. Solo entonces se desbloquea `insight` (opcional) en la **cronología NASA año 2022**. El portal de salida retorna a la feria sin eliminar la marca de victoria.

### Fuentes históricas oficiales
- [NASA Science · InSight](https://science.nasa.gov/mission/insight/): aterrizó el **26 de noviembre de 2018** en **Elysium Planitia**.
- [NASA/JPL · InSight coloca SEIS en la superficie](https://www.jpl.nasa.gov/news/nasas-insight-places-first-instrument-on-mars/): **19 de diciembre de 2018**. El brazo robótico situó el sensor sobre suelo marciano.
- [NASA · InSight misión terminada](https://www.nasa.gov/missions/insight/nasa-retires-insight-mars-lander-mission-after-years-of-science/): NASA concluyó la misión **21 de diciembre de 2022** después de **1.319 marsquakes**; la energía solar quedó insuficiente por polvo acumulado. InSight no volvió a comunicarse después.
- InSight **NO era un rover**; permanecía inmóvil. La actividad sísmica se usó para estudiar el interior del planeta. La consola no presenta datos reales de telemetría ni pretende reproducir sismos medidos.

## Entregables de implementación
- `levels/science_fair/science_fair.gd` + `.tscn`: escenario de feria, rover, kiosco, regreso al taller, portal opcional.
- `systems/gameplay/science_fair_demo_console.gd`: comprobación de 10 mejoras, 4 demostraciones, selección Continuar/Saber más y registro de victoria.
- `levels/insight/insight_greybox.gd` + `.tscn`: lander estático, paneles, brazo, SEIS y escudo provisional.
- `levels/insight/insight_memory.gd` + `.tscn`: recuerdo opcional Elysium Planitia, portal de regreso a feria.
- `systems/gameplay/insight_seismometer_console.gd`: decisiones de sensor, ruido y desenlace 2022.
- `scenes/main/main.gd`: portal de feria solo tras módulo Ingenuity.
- `systems/knowledge/knowledge_registry.gd`: ficha NASA InSight opcional verificada.
- `tests/science_fair_insight_story_loop_smoke.gd`: pruebas preparadas, no ejecutadas.

## Validación diferida
- [ ] Cargar en Godot y validar parseo de todas las escenas y recursos.
- [ ] Probar feria iniciando con uno o más módulos faltantes (bloqueo real).
- [ ] Probar 4 decisiones correctas/incorrectas, entrada y salida entre taller/feria.
- [ ] Comprobar que InSight NO se requiere para ganar ni se desbloquea antes de resolver.
- [ ] Probar sensor en el suelo, escudo, año 2022, K Archivo, volver a feria.
- [ ] Verificar los 10 módulos visuales acumulados y ausencia de regresiones.
- [ ] Ejecutar smoke test Godot Desktop, exportación Web, E2E y revisar modelos Blender.


## Escena poscréditos — Una nueva pista
El Capítulo I cierra con una victoria que tiene valor propio: la presentación de feria, todas las mejoras y la voz del abuelo. Al elegir **CONTINUAR · UNA NUEVA PISTA**, la historia lleva a `levels/chapter_two_preview/chapter_two_preview.tscn`. El escenario es una sala de archivo al anochecer con **tres siluetas sin identificar** y una **caja antigua sin etiqueta**. Al pulsar E para examinarla, el jugador escucha tres mensajes: la curiosidad del abuelo, la necesidad de identificar las fuentes y un «CONTINUARÁ…».

**Nunca afirmamos que las siluetas corresponden a nuevas piezas históricas concretas ni agregamos años o artefactos inventados al Archivo NASA.** El contenido posterior queda abierto para una segunda parte. El portal regresa a la feria; puede consultarse el Archivo NASA con K.

El progreso del Capítulo I continúa identificado por `rescue_rover_science_fair_completed` para mantener compatibilidad con la ruta y las pruebas existentes. **No se sustituye ni reinicia ese registro**. InSight permanece opcional en un camino separado y no se exige para ver la pista o completar la feria.

### Extensión futura
- Segunda parte todavía NO implementada: seleccionar y verificar con NASA nuevos objetos reales, su historia, sus lugares y la curva de retos.
- Nuevas historias podrán añadirse a la cronología existente sin modificar los registros históricos anteriores.
- El cierre del Capítulo I conserva todas las mecánicas, pero no pretende ser el producto final de la saga.
- [ ] Probar Godot: feria → Continuar → escena de caja → E/Enter → regreso a feria, y rama Saber más → InSight por separado.
- [ ] Verificar que el Archivo no registre entradas históricas ficticias ni se reinicie al entrar al teaser.
