# Recuerdo 08 — Opportunity: el Sol que dejó de llegar

**Estado:** historia y código implementados en `feat/005a-discovery-archive`. Sin ejecución Godot Desktop/Web. NO fusionar aún. Modelos definitivos aplazados.

## Continuidad
Después de Spirit (Troy), el vehículo escolar detecta patinaje y se detiene a tiempo. En la siguiente prueba, una pantalla de polvo oscurece sus paneles solares: la iluminación baja y los instrumentos siguen consumiendo energía. El abuelo recuerda a Opportunity, gemelo solar de Spirit.

**Abuelo (ficción):** «Opportunity exploró Marte mucho más de lo previsto, pero en 2018 el cielo se oscureció por una gigantesca tormenta de polvo. La última señal llegó desde el Valle de la Perseverancia y no volvió a despertarse. Podemos aprender a cuidar la batería de nuestro rover sin cambiar lo que ocurrió allá».

**Bucle:** prueba → fallo de luz → abuelo → recuerdo de Perseverance Valley → medir iluminación → proteger reserva → respetar desenlace → Archivo NASA → Continuar/Saber más → taller → `rescue_rover_power_budget_upgrade`.

## Hechos históricos verificados NASA/JPL
- Opportunity aterrizó en Meridiani Planum el **24 de enero de 2004 (PST)**; era gemelo de Spirit, con **seis ruedas, cámaras, instrumentos y paneles solares**.
- Diseñado para 90 soles, recorrió **45,16 km**.
- Una tormenta marciana oscureció la atmósfera sobre **Perseverance Valley**, borde del cráter Endeavour. **Última comunicación: 10 de junio de 2018**.
- NASA intentó restablecer contacto durante meses sin éxito y declaró terminada la misión el **13 de febrero de 2019**. Opportunity permanece en Marte; **no recuperó las comunicaciones**.
- La tormenta redujo la luz en la **atmósfera**; no contar una historia incorrecta de «limpiar los paneles y continuar». Las decisiones de la maqueta son inventadas, no telemetría ni órdenes de vuelo.

Fuentes:
- [NASA Science · Opportunity](https://science.nasa.gov/mission/mer-opportunity/)
- [NASA · Fin de la misión](https://www.nasa.gov/news-release/nasas-record-setting-opportunity-rover-mission-on-mars-comes-to-end/)
- [NASA JPL · Hunkers down during dust storm](https://www.jpl.nasa.gov/news/opportunity-hunkers-down-during-dust-storm/)
- [NASA JPL · Última imagen](https://www.jpl.nasa.gov/images/pia22929-opportunitys-last-message/)

## Recuerdo 08 — Decisiones educativas
1. **Medir luz solar disponible**, no creer que orientar un panel despeja la tormenta.
2. **Suspender cargas no esenciales** en la maqueta, sin asegurar que esa fue una secuencia concreta de comandos históricos.
3. **Reconocer el desenlace real:** última señal 2018, declaración fin de misión 2019; ninguna reactivación milagrosa.

Las elecciones incorrectas bloquean el descubrimiento `opportunity`. El jugador conserva Continuar/Saber más, el regreso al taller y las fichas Historia/Ingeniería/Tu proyecto.

## Mejora escolar
`rescue_rover_power_budget_upgrade`: monitor de luz y reserva + selección de consumos y aviso de agotamiento para **el rover del niño**. No sustituye el panel solar Vanguard ni el sistema Spirit; no garantiza energía perpetua.

## Implementación y validación futura
- `levels/opportunity/opportunity_rover_greybox.tscn` — pieza independiente, reutilizando geometría del gemelo Spirit
- `levels/opportunity/opportunity_memory.tscn` — recuerdo 3D temporal, iluminación reducida, HUD y portal
- `systems/gameplay/opportunity_power_console.gd` — decisiones y Archivo NASA
- Integración en `rescue_rover_project`, `talkable_npc`, `dialogue_controller`, `main` y `knowledge_registry`
- `tests/opportunity_power_story_loop_smoke.gd` — contrato preparado, sin ejecutar

Pendiente: imports Godot, E/A/D, colisiones, regreso, Archivo, mejoras, Desktop/Web, modelo Blender y capturas. No marcar funcionalmente validado.
