# Cinemática in-engine piloto: Pathfinder y Sojourner

**Estado:** implementado en GitHub como prototipo visual, con validación local Godot aún pendiente. No es video prerenderizado.

## Qué se implementó
Se entra al recuerdo Ares Vallis ya existente. Después de alinear el escenario GLB v33 y los modelos de Pathfinder y Sojourner con el suelo real, comienza un montaje cinematográfico in-engine de **15,5 segundos**:

1. Paracaídas, descenso y fecha 4 de julio de 1997.
2. Frenado de retrocohetes (efecto conceptual) y airbags.
3. Dos rebotes mostrados a modo de resumen (la misión real rebotó más).
4. Contracción de airbags, apertura de los tres pétalos en una réplica visual del lander.
5. **Transición temporal explícita:** «EN LOS SOLES SIGUIENTES». Sojourner aparece descendiendo por la rampa trasera; el escenario sigue siendo Ares Vallis.
6. La cámara se interpola al punto de vista FPS real del jugador, aparecen HUD y objetivos, y se desbloquean sus controles sin cargar otro nivel.

Se utiliza **una sola escena** y se reutilizan las mallas reales de los objetos cargados en Ares Vallis. Durante la intro, se ocultan los visuales interactivos originales y se muestran copias exclusivamente visuales, sin colisiones; al terminar se destruyen las copias y reaparecen los originales sin cambios.

## Controles y pruebas
- **E o Esc**: omitir inmediatamente y recuperar cámara/jugador/HUD, incluso si la cinemática está a medias.
- Piloto: reproduce la intro **en cada visita**, incluso en partidas con el primer recuerdo completado; así se puede comparar y probar sin borrar la partida. Cuando esté aprobada se podrá controlar con `enable_pathfinder_intro`.
- No se registran descubrimientos nuevos ni se alteran datos persistidos por el video.
- No hay archivos de video, codecs, descarga, dependencia de Blender ni cambio en el reto APXS.

### Contexto histórico oficial
- [NASA Science · Pathfinder aterriza el 4 julio 1997](https://science.nasa.gov/solar-system/mars-pathfinder-lands-on-mars/).
- [NASA Science · Paracaídas, retrocohetes y airbags](https://science.nasa.gov/planetary-science/programs/mars-exploration/mission-timeline/how-we-land-on-mars/).
- [NASA/JPL · Rampas y Sojourner](https://www.jpl.nasa.gov/images/pia00627-pathfinder-rear-ramp/). La **rampa trasera** fue utilizada para su salida en Sol 2; no se debe narrar que salió inmediatamente al tocar suelo.
- [NASA/JPL · Rebotó muchas veces](https://www.jpl.nasa.gov/images/pia00797-pathfinder-landing-accelerations/). La animación comprime las fases históricas; no representa telemetría real.

### Validación requerida en Godot
- [ ] Abrir el juego normal, taller → hablar con abuelo → Ares Vallis: aparece la cámara cinemática.
- [ ] Ver los subtítulos completos y el marcador «En los soles siguientes».
- [ ] Comprobar que el descenso y los airbags no están bajo el relieve de Ares Vallis v33.
- [ ] Comprobar transición sin saltos de escala/orientación ni parpadeos.
- [ ] Pulsa **Esc** en descenso, rebotes, pétalos y Sojourner: retorna a FPS sin bloqueo.
- [ ] Confirma que Pathfinder y Sojourner siguen pudiendo inspeccionarse/completarse.
- [ ] Abre K; navega a taller; vuelve a entrar para replay; comprobación de rendimiento Desktop/Web.
- [ ] Ejecutar `tests/pathfinder_cinematic_intro_smoke.gd` con Godot; no se ejecutó aún.

**Futuros pasos**: sustituir greyboxes y añadir audio/partículas/reconstrucción de trayectoria si la prueba visual queda bien. Si no convence, comparar con intro de video prerenderizado sin perder la lógica del recuerdo.
