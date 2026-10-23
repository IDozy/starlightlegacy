# Recuerdo 10 — Ingenuity: observar más allá del horizonte

**Estado:** implementación de código y narrativa en `feat/005a-discovery-archive` / PR #13. Godot Desktop/Web, E2E y modelos definitivos PENDIENTES, no declarar funcionalmente validado.

## Continuidad
Después del aterrizaje seguro de Sky Crane, el Vehículo Explorador de Rescate de feria se encuentra con una cresta de rocas. Su cámara terrestre no ve el terreno que hay detrás. La nueva solución no consiste en hacer volar el rover, sino en usar **una aeronave auxiliar de exploración**.

**Abuelo (diálogo ficticio):** «Ingenuity llegó a Marte en el vientre de Perseverance. ¿Sabes que allí la atmósfera es tan tenue que volar resulta mucho más difícil? Fue pequeño y ligero; tenía dos rotores que giraban en sentidos opuestos. Consiguió el primer vuelo de ese tipo fuera de la Tierra. Tu rover puede seguir en el suelo y tener un compañero que mire desde arriba».

**Bucle:** prueba de reconocimiento → no se ve la ruta → abuelo → recuerdo de Ingenuity → elegir aeronave ligera → rotores contrarrotativos → vuelo de demostración y aterrizaje → legado 2024 sin resurrección → `ingenuity` en Archivo → Continuar / Saber más → taller → `rescue_rover_aerial_scout_upgrade`.

## Historia real y fuentes NASA/JPL
- Ingenuity aterrizó en Marte el **18 de febrero de 2021**, transportado bajo Perseverance, y se desplegó sobre la superficie en abril.
- El **19 de abril de 2021** realizó el **primer vuelo motorizado y controlado en otro planeta**. Se elevó aproximadamente **3 m**, permaneció en vuelo estacionario alrededor de **30 segundos** y aterrizó; el vuelo completo duró **39,1 segundos**.
- La atmósfera de Marte tiene una presión superficial alrededor del **1% de la terrestre**. Ingenuity era un helicóptero muy ligero, con **dos rotores coaxiales contrarrotativos**, cada uno de **1,2 m de diámetro**.
- Su objetivo inicial era una demostración tecnológica de **hasta cinco vuelos**; tras el éxito continuó como explorador aéreo, ayudando a planificar operaciones de Perseverance.
- Completó **72 vuelos**; el último fue el **18 de enero de 2024**. NASA anunció el **25 de enero de 2024** el fin de la misión tras detectar daños en una o más palas que impedían seguir volando. No mostrar vuelos posteriores ni resurrección histórica.
- La representación Godot es **un ejercicio didáctico sin física aerodinámica real**. No pretende recrear la navegación ni la telemetría de JPL.

Fuentes:
- [NASA/JPL · Ingenuity (misión)](https://www.jpl.nasa.gov/missions/ingenuity/)
- [NASA · Primer vuelo](https://www.nasa.gov/news-release/nasas-ingenuity-mars-helicopter-succeeds-in-historic-first-flight/)
- [NASA/JPL · Final de Ingenuity](https://www.jpl.nasa.gov/news/after-three-years-on-mars-nasas-ingenuity-helicopter-mission-ends/)
- [NASA Science · Ingenuity](https://science.nasa.gov/mission/mars-2020-perseverance/ingenuity-mars-helicopter/)

## Tres decisiones educativas
1. Elegir un helicóptero **ligero con rotores adecuados** ante el aire tenue; rechazar una aeronave terrestre pesada.
2. Comprender los **dos rotores contrarrotativos** para compensar el par; rechazo de rotores que giren igual.
3. Finalizar un vuelo corto con aterrizaje, explicar los 72 vuelos y el daño en 2024; **no afirmar que Ingenuity despegó después de sufrir daños**.

La maqueta muestra las cuatro patas, cuerpo, mástil, panel solar y dos rotores independientes; el vuelo tiene estados explícitos. El minijuego impide saltar pasos. Se activa el portal de retorno tras registrar `ingenuity`. La cronología del Archivo conserva el año **2024**, aunque la escena visita el inicio de 2021 y relata el final.

## Mejora para el proyecto escolar
`rescue_rover_aerial_scout_upgrade`: pequeña maqueta/sonda aérea auxiliar, separada del rover terrestre, con rotores protegidos y exploración visual de obstáculos. La representación escolar no equivale a volar sobre Marte; los sistemas de ruedas, tracción, energía solar, entrega y conocimiento anterior permanecen.

## Código
- `levels/ingenuity/ingenuity_greybox.gd` y `.tscn`
- `levels/ingenuity/ingenuity_memory.gd` y `.tscn`
- `systems/gameplay/ingenuity_flight_console.gd`
- `systems/gameplay/rescue_rover_project.gd` y `.tscn`
- `systems/dialogue/talkable_npc.gd` y `dialogue_controller.gd`
- `scenes/main/main.gd` y `systems/knowledge/knowledge_registry.gd`
- `tests/ingenuity_flight_story_loop_smoke.gd` (preparado, NO ejecutado)

## Validación aplazada
- [ ] Importar a Godot, comprobar errores de sintaxis/importación, luces y materiales.
- [ ] Probar E, A/D, feedback incorrecto, archivo, portal y progreso.
- [ ] Comprobar modelo de dos rotores, despegue conceptual, regreso al suelo y guardas.
- [ ] Revisar persistencia/ciclo previo completo y exportación Web.
- [ ] Ejecutar smoke test sólo cuando vuelva el equipo a Godot y modelar en Blender la versión definitiva.
