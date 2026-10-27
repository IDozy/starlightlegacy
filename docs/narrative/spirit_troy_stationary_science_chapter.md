# Recuerdo 07 — Spirit en Troy: cuando seguir no es avanzar

**Estado:** implementado en `feat/005a-discovery-archive`, pendiente de abrir y validar en Godot Desktop/Web. No reemplazar modelos definitivos ni fusionar sin pruebas.

## Continuidad jugable

El niño lleva su Vehículo Explorador de Rescate a otra prueba tras el laboratorio Viking 1. Sus bandas de agarre mejoraron la tracción, pero ahora un terreno artificial de polvo muy suelto hace patinar una rueda. Insistir con velocidad hace que se hunda aún más. El abuelo propone conocer a Spirit.

**Diálogo del abuelo (ficción):** «Spirit tenía seis ruedas y exploró Marte durante años. En 2009 quedó atrapado en un suelo inesperadamente blando. La NASA estudió cómo sacarlo, pero no pudo. A veces la decisión más inteligente no es empujar más, sino reconocer los límites y seguir aprendiendo sin moverse».

Bucle: prueba de suelo → fallo y registro → abuelo → memoria Troy → tres decisiones → descubrimiento `spirit` → «Continuar / Saber más» → retorno al taller → detector de patinaje `rescue_rover_slip_guard_upgrade`.

## Hechos de NASA/JPL (separados de la ficción)

- Spirit (Mars Exploration Rover-A) aterrizó en Gusev Crater el **4 de enero de 2004 UTC** (3 de enero hora de California). Era un rover de **seis ruedas** con paneles solares y cámaras, diseñado para una misión primaria de 90 soles.
- En abril/mayo de **2009**, una zona de suelo muy blando en Home Plate, denominada **Troy**, atrapó sus ruedas. Spirit tenía ya una rueda delantera derecha inoperativa. JPL investigó y ensayó maniobras en la Tierra; **no logró liberarlo**.
- El **26 de enero de 2010** NASA anunció que trabajaría con Spirit como **plataforma científica estacionaria**, con limitaciones serias de energía por el invierno marciano.
- La **última comunicación fue el 22 de marzo de 2010**; NASA cerró los intentos de contacto el **25 de mayo de 2011**. El rover quedó en Marte.
- Los descubrimientos de minerales ricos en sílice por Spirit, en otra parte de su travesía, son historia auténtica, pero **no deben confundirse con una muestra extraída en la consola inventada de Troy**.

**Fuentes primarias:**
- [NASA Science · Spirit](https://science.nasa.gov/mission/mer-spirit/)
- [NASA/JPL · MER Spirit](https://www.jpl.nasa.gov/missions/mars-exploration-rover-spirit-mer-spirit/)
- [NASA/JPL · Spirit starts a new chapter (26-01-2010)](https://www.jpl.nasa.gov/news/nasas-mars-rover-spirit-starts-a-new-chapter/)
- [NASA/JPL · Attempts to free Spirit (2009)](https://www.jpl.nasa.gov/news/tilt-parameters-end-first-extrication-drive/)

## Tres decisiones jugables (analogía educativa)

1. El monitor del museo muestra giro de ruedas sin avance: **detener**, no acelerar.
2. Evaluar **hundimiento, inclinación y reserva de energía**, no subir potencia a ciegas.
3. Reconocer el desenlace histórico: Spirit **no escapó**; en 2010 la misión priorizó ciencia estacionaria. No presentar éxito de rescate ficticio.

Las opciones erróneas mantienen el reto bloqueado. La tercera decisión registra `spirit`, desbloquea el portal y habilita la ficha «Historia / Ingeniería / Tu proyecto». Los datos del monitor son inventados para enseñar toma de decisiones; **no son telemetría ni una recreación de comandos de vuelo**.

## Aplicación escolar

Se instala un pequeño **monitor de patinaje e inclinación** sobre el rover del niño que compara movimiento observado con giro de ruedas y recomienda detenerse antes de atascarse. Esta mejora educativa puede prevenir errores en **el rover de feria**, pero **no reescribe el destino de Spirit**. Se preservan impacto, energía solar, cámara orientable, base modular, ruedas con agarre y registrador científico.

## Artefactos y contrato

- `levels/spirit/spirit_rover_greybox.tscn` — rover simple e independiente con seis ruedas, dos paneles, cámaras, mástil y brazo.
- `levels/spirit/spirit_memory.tscn` — terreno rojo simulado, controles, HUD y regreso.
- `systems/gameplay/spirit_slip_console.gd` — decisiones bloqueantes y Archivo NASA.
- `systems/gameplay/rescue_rover_project.gd` y `.tscn` — nuevo fallo y mejora con visual propio.
- `systems/dialogue/talkable_npc.gd`, `systems/dialogue/dialogue_controller.gd`, `scenes/main/main.gd`, `systems/knowledge/knowledge_registry.gd` — continuidad.
- `tests/spirit_slip_story_loop_smoke.gd` — contrato a ejecutar después.

**Validación aplazada:** importaciones, controles E/teclado, textos en HUD, interacción y colisiones, portal, Archivo NASA, guardado de sesión, escenas Desktop/Web y futuros modelos Blender. **No marcar completado funcionalmente.**
