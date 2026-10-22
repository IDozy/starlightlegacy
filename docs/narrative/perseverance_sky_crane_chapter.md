# Recuerdo 09 — Perseverance y Sky Crane: primero tocar suelo

**Estado:** implementado como código y relato en `feat/005a-discovery-archive`, pendiente de ejecutar Godot Desktop/Web y verificar modelos. No fusionar todavía.

## Continuidad de la campaña
Luego de Opportunity, el niño consiguió protección ante impactos y patinaje, energía solar, comprobación científica y un presupuesto energético. La nueva prueba demuestra un peligro distinto: **el soporte de entrega se suelta antes de que las ruedas estén apoyadas**. No basta con tener amortiguación; la secuencia de operaciones debe garantizar contacto antes de liberar.

**Abuelo (ficción):** «¿Recuerdas cómo Apollo 11 dejó una etapa en la Luna? Perseverance hizo algo diferente: en 2021 llegó al cráter Jezero de Marte con una etapa de descenso que lo sostuvo por cables, confirmó el contacto y luego se alejó para caer lejos. Tu rover escolar necesita un seguro que no libere el soporte antes de posarse».

**Bucle:** probar entrega → fallo liberación → abuelo → recuerdo Jezero → sitio seguro → bajar por cables → detectar touchdown y cortar → descubrimiento `perseverance_sky_crane` → Continuar / Saber más → regreso al taller → `rescue_rover_touchdown_release_upgrade`.

## Historia real NASA/JPL
- Perseverance aterrizó exitosamente en el cráter **Jezero el 18 de febrero de 2021**.
- Para el descenso se usaron escudo térmico, paracaídas y navegación relativa al terreno (**Terrain-Relative Navigation**). El sistema seleccionó un punto alcanzable y seguro al comparar imágenes con mapas.
- Una etapa de descenso con **ocho motores** redujo la velocidad. Aproximadamente **20 m sobre la superficie** inició la maniobra Sky Crane y bajó al rover sujeto por cables.
- Cuando Perseverance **detectó contacto de las ruedas con el suelo**, cortó cables y conexiones. La etapa de descenso **se alejó y terminó impactando a distancia**. No quedó como base de apoyo en el lugar de touchdown, a diferencia de la etapa de descenso de Apollo 11.
- Toda la maniobra fue autónoma: la demora de las comunicaciones imposibilitaba pilotarla en tiempo real desde Tierra.
- La maqueta es una reconstrucción educativa sin telemetría real; no reprodujimos la trayectoria de vuelo, velocidades, propulsión ni el impacto de la etapa.

Fuentes oficiales:
- [NASA Science · How We Land on Mars](https://science.nasa.gov/planetary-science/programs/mars-exploration/mission-timeline/how-we-land-on-mars/)
- [NASA/JPL · Landing Press Kit, Mars 2020](https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/)
- [NASA/JPL · Perseverance Touches Down (illustration)](https://www.jpl.nasa.gov/images/pia24319-perseverance-touches-down-on-mars-illustration/)

## Tres decisiones jugables
1. Escoger una zona más segura según las observaciones, en vez de ignorar obstáculos.
2. Bajar al rover **sostenido por cables**, en vez de soltarlo en caída libre.
3. **Confirmar contacto → cortar cables → etapa se aleja**. Los atajos están bloqueados: el minijuego y el modelo no permiten ejecutar separación prematura.

El rover del recuerdo queda en el suelo; los cables desaparecen y la etapa se aleja. El jugador recupera `perseverance_sky_crane` solo tras completar correctamente las tres etapas. Continúa el Archivo NASA con su cronología independiente y la ruta opcional Saber más.

## Aplicación escolar
`rescue_rover_touchdown_release_upgrade`: contacto/sensor de apoyo y pestillo de liberación del soporte de transporte. **No es un Sky Crane real**, no tiene motores cohete; es una analogía de seguridad de operaciones. Se acumula con los módulos ya instalados.

## Entregables de implementación
- `levels/perseverance_sky_crane/sky_crane_greybox.gd` / `.tscn`: módulo de descenso, ocho motores representados por geometría simple, cables, rover de seis ruedas, estados y alejamiento.
- `levels/perseverance_sky_crane/sky_crane_memory.gd` / `.tscn`: Jezero, HUD, consola, portal.
- `systems/gameplay/sky_crane_landing_console.gd`: decisiones correctas / incorrectas, secuencia y Archivo NASA.
- `systems/gameplay/rescue_rover_project.gd` / `.tscn`: nueva prueba y mejora visual acumulable.
- `systems/dialogue/talkable_npc.gd`, `dialogue_controller.gd`, `scenes/main/main.gd`, `systems/knowledge/knowledge_registry.gd`: disparador, recuerdos, objetivos, catálogo.
- `tests/sky_crane_story_loop_smoke.gd`: contrato preparado sin ejecutar.

## Validación aplazada
- [ ] Godot import/editor, GDScript y recursos.
- [ ] Interacción E, A/D, controles, HUD y colisiones.
- [ ] No permitir separación antes del touchdown aun llamando métodos del modelo fuera del minijuego.
- [ ] Persistencia, regreso a taller, Archivo y mejoras anteriores.
- [ ] Ejecutar smoke test en Desktop y Web.
- [ ] Modelado definitivo Blender y ajustes visuales.
