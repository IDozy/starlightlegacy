# Starlight Legacy — próximos dos recuerdos: Vanguard 1 y Surveyor 1

**Estado:** diseño narrativo + modelos temporales; no integrado a campaña principal.  
**Fecha:** 2026-10-20.  
**Fuente de continuidad:** Notion «NASA», sección Historia maestra, consultado 2026-10-20.  
**Rama de referencia:** `feat/005a-discovery-archive`.

## Reglas de continuidad

- El protagonista (niño o niña de 10–12 años) construye el **Vehículo Explorador de Rescate** para su feria de ciencias.
- Bucle inalterable: intento → fallo → abuelo → recuerdo jugable → descubrimiento → «Continuar / Saber más» → aplicar conocimiento → éxito.
- Orden de niveles según **curva de dificultad**, no cronológico; el Archivo NASA ordena los artefactos por año.
- El abuelo es un personaje ficticio nacido en 1950: los diálogos que proponemos son **ficción narrativa**; las afirmaciones sobre las misiones se basan en NASA.
- Las vistas de épocas históricas son **reconstrucciones educativas**, no filmaciones del viaje ni registros exactos del día del suceso.
- Los modelos greybox se mantienen separados de escenas jugables actuales. Primero historia comprobable; después arte final.

---

## Capítulo siguiente: Vanguard 1 — «La energía que no se rinde»

**Archivo NASA:** 1958 · `vanguard_1_solar` · Tierra/orbita · tipo: satélite.  
**Dificultad orientativa:** fácil, descanso tras el reto de impacto y APXS.  
**Concepto:** energía solar + reserva de batería + uso responsable de electricidad.

### Ancla histórica verificable

- Vanguard 1 fue lanzado el **17 de marzo de 1958** y se considera el primer satélite alimentado por energía solar.
- Lo desarrolló el programa Vanguard del **Naval Research Laboratory**, **antes** de que la NASA comenzara sus operaciones. No atribuir el lanzamiento de marzo de 1958 a una NASA que aún no operaba.
- Tenía **forma esférica**, seis grupos de células solares y seis antenas, como describe una nota técnica histórica.
- Su transmisor alimentado por células solares operó durante años; la comunicación terminó en **1964**. Que todavía orbite no significa que continúe transmitiendo.

Fuentes:
- NASA: https://www.nasa.gov/image-article/vanguard-satellite-1958/
- NASA: https://science.nasa.gov/sun/how-nasa-uses-and-improves-solar-power/
- NASA Goddard: https://www.nasa.gov/history/nasa-goddards-beginnings-in-project-vanguard/
- NASA NTRS: https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19980228199.pdf

### Intento, fallo, abuelo

**Taller.** El Vehículo Explorador de Rescate del niño ya amortigua el impacto, pero después de mover su brazo y encender la luz de búsqueda, se apaga. El indicador de batería llega a cero. El niño intenta reducir el brillo, pero todavía no dispone de suficiente autonomía.

**Diálogo propuesto (ficción):**

- **Niño:** «¡Por fin soportó la caída! Pero ahora no tiene energía para terminar el rescate».
- **Abuelo:** «A veces no se trata de una batería más grande. Hubo un satélite muy pequeño que nos enseñó a buscar energía mientras trabajaba».
- **Niño:** «¿La NASA lo lanzó?»
- **Abuelo:** «Fue Vanguard 1, en 1958, antes de que la NASA empezara a funcionar. Tenía pequeñas células solares en su esfera. Ven, te mostraré por qué importaron».

### Recuerdo jugable

**Lugar:** reconstrucción estilizada de una órbita terrestre. No es visita literal a una grabación histórica.

1. Descubrir Vanguard 1, pequeño y esférico, con seis antenas. Proteger lectura de tamaño: perspectiva ampliada para inspección; escala base física **0,165 m de diámetro**, sin hacer creer que era enorme.
2. Activar una comparación educativa **batería sola / batería + células solares**. Los valores son del juego, no mediciones históricas.
3. Mantener una transmisión simulada con consumo de energía moderado; evitar agotar toda la reserva cuando el satélite entra en sombra.
4. Mensaje de logro: «La energía solar puede prolongar el tiempo de trabajo de un sistema, si se gestiona bien».
5. Desbloqueo `vanguard_1_solar`; aparece en **1958** dentro del Archivo NASA.

### Volver y aplicar

El niño añade al **Vehículo Explorador de Rescate** un **pequeño módulo solar** y un indicador de batería, y programa una **modalidad de ahorro**. Es ingeniería de su vehículo ficticio, no un componente de Vanguard trasplantado de manera literal.

### Fichas Saber más

- **Historia:** satélite del programa Vanguard, en órbita desde 1958; las comunicaciones no son eternas.
- **Ingeniería:** células solares transforman luz en electricidad; las baterías almacenan una cantidad finita de energía.
- **Tu proyecto:** consumo de luces, motores y comunicación; decidir cuándo ahorrar energía.

### Verificaciones de guion

- Nunca afirmar que Vanguard se lanzó después de fundarse la NASA.
- No afirmar que sigue transmitiendo.
- No confundir la simulación de sombras/consumo con telemetría real.

---

## Segundo capítulo: Surveyor 1 — «La luz, las órdenes y una primera mirada»

**Archivo NASA:** 1966 · `surveyor_1_lunar` · Luna · tipo: aterrizador.  
**Dificultad orientativa:** media.  
**Concepto:** orientación de panel, gestión de carga/energía, comandos desde Tierra y observación remota.

### Ancla histórica verificable

- Lanzado el **30 de mayo de 1966**; aterrizó suavemente en la Luna el **2 de junio de 1966**, primera vez para una nave estadounidense.
- Descendió en el **Océano de las Tormentas (Oceanus Procellarum)**; transmitió **11.240 imágenes**.
- Estructura **triangular**, tres patas de aterrizaje con zapatas, un **mástil con panel solar y antenas**, batería más células solares, y una cámara de TV.
- Podía recibir órdenes desde Tierra para cambiar gradualmente la posición de su panel solar. La operación de carga después de una noche lunar aparece en documentación histórica de NASA; no inventar un seguimiento automático inteligente.

Fuentes:
- NASA Science: https://science.nasa.gov/mission/surveyor-1/
- NASA JPL: https://www.jpl.nasa.gov/missions/surveyor-1/
- NASA: https://www.nasa.gov/history/55-years-ago-surveyor-1-makes-a-soft-landing-on-the-moon/
- NASA/JPL documento histórico: https://science.nasa.gov/solar-system/moon/surveyor-1-lands-on-the-moon/
- NASA Historical Data Book: https://www.nasa.gov/wp-content/uploads/2023/04/sp-4012v2.pdf

### Intento, fallo, abuelo

**Taller.** Gracias a la mejora solar, el vehículo acumula energía. Sin embargo, en una prueba con la luz lateral, el panel recibe menos iluminación y la cámara no muestra bien el objeto que debe encontrar. Ya no basta con **tener** panel solar: hay que **orientarlo** y dirigir la observación.

**Diálogo propuesto (ficción):**

- **Niño:** «Ahora tengo un panel, pero cuando la luz cambia deja de cargar tan bien. ¡Y la cámara no encuentra la señal!».
- **Abuelo:** «Las máquinas que exploraban lejos de casa tenían que aprovechar la energía que recibían y obedecer instrucciones precisas».
- **Niño:** «¿Podían hacerlo desde la Tierra?»
- **Abuelo:** «Sí. En 1966, Surveyor 1 llegó con cuidado a la Luna. Desde la Tierra controlaron instrumentos y también la orientación del panel para administrar la recarga».

### Recuerdo jugable

**Lugar:** reconstrucción de una zona de Oceanus Procellarum en 1966. Sin astronautas: la misión era robótica.

1. Explorar Surveyor 1 en su **trípode**, cámara y panel solar. El escenario lunar es gris y polvoriento; no reutilizar Marte.
2. Activar una consola que representa **órdenes desde la Tierra**; el jugador envía órdenes discretas para inclinar un **panel de entrenamiento** hacia una fuente de luz.
3. Estabilizar la energía después de una fase de sombra simulada; la curva de carga es **analogía educativa**, no telemetría real.
4. Dirigir la cámara a una roca y recibir una **imagen reconstruida**, inspirada en el trabajo de la cámara de Surveyor 1.
5. Completar el registro `surveyor_1_lunar`; aparece en **1966** en el Archivo NASA.

### Volver y aplicar

El niño añade al vehículo **un soporte regulable** para el panel solar y **un mecanismo básico de orientación de cámara**, con indicación de energía recibida. No atribuir sensores autónomos de seguimiento solar a Surveyor 1 sin referencia específica.

### Fichas Saber más

- **Historia:** aterrizaje suave en la Luna y preparación de conocimiento para misiones Apolo posteriores.
- **Ingeniería:** trípode estable, propulsión de descenso, panel orientable mediante comandos, batería y cámara remota.
- **Tu proyecto:** ajustar ángulo del panel según luz, observar una zona sin desplazar todo el vehículo.

### Verificaciones de guion

- No atribuirle a Surveyor 1 un rover ni pala excavadora de versiones posteriores.
- No confundir aterrizaje suave con las bolsas de aire de Pathfinder (1997).
- Las misiones reales ocurrieron **1958** y **1966**, aunque el orden jugable cambie por dificultad.

---

## Estado de implementación y criterios para aprobar

- [x] Dos guiones base contrastados con fuentes NASA.
- [x] Modelos **greybox independientes**: `levels/vanguard_1/vanguard_1_greybox.tscn` y `levels/surveyor_1/surveyor_1_greybox.tscn`.
- [ ] Validar visualmente en Godot las escalas, orientación y jerarquía.
- [ ] Conectar ambas escenas al fallo/abuelo/recuerdo y al Archivo NASA mediante los contratos reales.
- [ ] Implementar pruebas Desktop y Web, registros sin duplicados, Continuar/Saber más y guardar progreso.
- [ ] Aprobar ritmo de dificultad con capturas; modelado final de Blender pendiente.

**NO marcar estos capítulos como implementados ni fusionar hasta superar las pruebas.**  
