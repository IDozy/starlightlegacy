# Integración del taller Blender v02 en Godot

La rama `feat/005a-discovery-archive` utiliza `assets/models/taller/Taller_NASA_v02.glb` como geometría visible del taller. La escena principal sigue siendo `scenes/main/main.tscn` y `levels/workshop/workshop.gd` sigue creando los elementos interactivos.

## Qué cambia

- `Workshop` instancia el modelo como hijo `Taller_NASA_v02_Visual`.
- Se retira **solo en tiempo de ejecución** la sala rectangular generada anteriormente, sin borrar su función `_build_room()`: el flag `use_imported_workshop` permite usar el diseño anterior como fallback.
- Colisiones de Godot, separadas del mesh visual: piso inferior, plataforma superior, rampa convexa, paredes laterales y barandas divididas para dejar libre el centro.
- El rover de rescate, abuelo, objetos inspeccionables y props conservan sus nodos directamente bajo `Workshop`. La mayoría se desplaza `+5 m` en Z hacia el piso inferior; el rover suma `+1.5 m` adicionales para coincidir con el espacio de pruebas; las marcas antiguas y la plataforma de caída ya no se generan. Algunos accesorios visuales de las paredes antiguas se ocultan.
- La iluminación de la versión GLB tiene un fondo más claro y luz ambiental cálida.

## Referencia de coordenadas

La geometría se creó en Blender a 14 × 20 m, con altura 5,8 m, plataforma superior a 1 m y rampa de 4,2 × 3,8 m. En Godot, el modelo se deja en transform identidad: el conversor glTF se ocupa de los ejes. Se esperan estos valores del mundo Godot:

- Suelo inferior en `Y = 0`.
- Plataforma superior en `Y = 1`, aproximadamente `Z = -10` a `Z = -3.6`.
- Rampa de `Z = +0.2` (abajo) a `Z = -3.6` (arriba).
- Zona de pruebas del rover en torno a `Z = +6.15`.

Se usan colisiones simplificadas, no una colisión por tornillo o viga. La geometría final debe verificarse contra el GLB exportado tras las correcciones manuales de Blender. Si la rampa visual no coincide exactamente, ajustar la cuña de colisión, no el importado.

## Ajustes de distribución y seguridad (octubre de 2026)

- Al utilizar el taller importado, ya **no se instancia** `_build_test_area()`. Esto retira el rectángulo negro, el bloque de caída y las señales duplicadas. El modo antiguo mantiene su zona de pruebas.
- La mesa completa (tablero, patas, ordenador, silla y dispositivo inspeccionable) conserva su composición en el **primer nivel, a la izquierda de la rampa**. Se movió **0,75 m hacia el centro (alejándose de la puerta lateral)** y **3,15 m hacia el portón principal**. Nuevo tablero en `X≈-4.10`, `Z≈-1.25`, dejando paso junto a la rampa; no se borran interacciones.
- El abuelo pasa al **nivel superior derecho** junto a la baranda. Continúa siendo un nodo directo `Grandfather` de Workshop.
- Se oculta el panel negro del prototipo antiguo situado tras la mesa (`WorkbenchBackboard`), incluyendo su colisión.
- Se añade un **muro de cierre color marfil** con zócalo azul y franja naranja en `Z≈+9.8`, al fondo del primer nivel. El **portón superior (`Z≈-10`) queda completamente despejado**. Se genera en Godot, sin modificar el archivo fuente GLB de Blender.
- Barandas con colisión invisible de **2,6 m de altura** en ambos extremos del nivel alto y los laterales. El hueco central hacia la rampa continúa despejado. Las colisiones de pared permanecen activas.

**Validación visual pendiente en el ordenador:** en particular, comprobar que el muro cierre el extremo inferior sin obstruir el portón superior, que la mesa sea accesible al lado izquierdo de la rampa, que la interacción con el abuelo funcione desde el nivel superior y que la caída lateral se impida incluso saltando. El smoke test comprueba presencia y transformaciones, no simula movimiento real.

## Validación

Desde la carpeta que contiene `project.godot`:

```powershell
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/workshop_glb_smoke.gd
```

Después ejecutar el juego en Godot y confirmar que:

1. No aparece la sala rectangular antigua por encima del modelo nuevo.
2. El personaje aparece en el piso inferior, camina y sube la rampa sin saltar ni atravesarla.
3. La parte alta es transitable y las barandas no bloquean la embocadura.
4. Funcionan el rover, inspección, abuelo, diálogos, transición a Ares Vallis y Archivo NASA.
5. No hay materiales ausentes, iluminación excesiva, colisiones flotantes ni props enterrados.

**Pendiente:** validación manual de colisiones/posiciones y rendimiento Web, ya que esta integración no se ha ejecutado dentro del editor Godot en el entorno de edición remoto. Si se vuelve a exportar el GLB desde Blender, revisar estas referencias geométricas.
