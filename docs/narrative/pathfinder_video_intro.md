> **DECISIÓN VISUAL (26 oct 2026):** tras ver el primer render `draft` en Godot, se prefirió la cinemática **in-engine** anterior. Se restauró el flujo normal taller → `ares_vallis.tscn` → intro in-engine. El video es un experimento opcional al abrir `pathfinder_video_intro.tscn` con F6; no se reproduce mediante F5 y no hace falta volver a renderizarlo. Si se usa esa opción, la entrada al mapa suprime la segunda intro. Si falta el `.ogv`, se utiliza la intro in-engine como respaldo.

# Pathfinder — cinemática renderizada (Capítulo I)

Esta es una **alternativa archivada para comparación**, no la entrada principal del juego. El video offline se creó con Blender para evaluar su calidad, pero la prueba favoreció la primera secuencia 3D del mapa.

## Crear el vídeo en Windows (Blender 5.2)

1. **No necesitas WinGet.** Si falta FFmpeg, el ejecutor descargará la versión portable Essentials ZIP desde gyan.dev, comprobará el SHA-256 publicado y la conservará en `.tools/pathfinder-ffmpeg/` sin cambiar el PATH del sistema ni pedir permisos de administrador.
2. Desde la raíz del repositorio ejecuta:
   ```powershell
   .\scripts\cinematics\render_pathfinder.ps1 -Quality draft
   ```
   Si Blender no se autodetecta, agrega `-BlenderBinary "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"`.
3. El resultado `assets/videos/pathfinder/pathfinder_intro.ogv` se importa directamente en Godot. Para revisar **solo la alternativa de video**, ejecuta `levels/ares_vallis/pathfinder_video_intro.tscn` con **F6**. Para la experiencia **elegida**, usa **F5** (intro in-engine). Esc/E omiten ambas.
4. Para una versión con mayor resolución: `-Quality final`. Los frames y el `.blend` generado quedan en `renders/pathfinder/`.

**Importante:** el usuario ya renderizó y evaluó el primer .ogv en su máquina; no se incluye en el repositorio. La intro de video es opcional y conserva una transición que evita encadenar la intro in-engine si se ha reproducido un .ogv. Los PNG, .blend generado y OGV son archivos locales de producción: revisar su tamaño y licencia antes de incorporarlos al PR.

## Storyboard — 16 segundos (reconstrucción estilizada, no filmación real)

| Segundos | Cámara / acontecimiento | Superposición de texto en Godot |
|---|---|---|
| 0–2.7 | Descenso con paracaídas y valle marciano | MARTE · 4 DE JULIO DE 1997 |
| 2.7–5.5 | Frenado, airbags inflándose | DESCENSO |
| 5.5–8.5 | Rebotes y asentamiento | ATERRIZAJE |
| 8.5–12 | Retraer airbags, abrir pétalos/paneles | PATHFINDER |
| 12–15 | Sojourner desciende por rampa en Sol 2 | SOL 2 · SOJOURNER |
| 15–16 | Plano general final → fundido → mapa FPS | ARES VALLIS |

## Criterios científicos
El aterrizaje ocurrió el **4 de julio de 1997**. La entrada, el paracaídas, retrocohetes y airbags son la secuencia auténtica de ingeniería, pero los tiempos, número de rebotes, geometría del modelo y cámaras son **simplificaciones narrativas**. El rover descendió de la rampa en **Sol 2**, no inmediatamente tras la caída. **No confundir con Sky Crane de Perseverance**.

- https://science.nasa.gov/mission/mars-pathfinder/
- https://www.nasa.gov/history/25-years-ago-mars-pathfinder-launches-to-mars-to-deploy-sojourner-the-first-planetary-rover/
- https://www-robotics.jpl.nasa.gov/gallery/mars-pathfinder-mission-animation-1996/
- https://docs.godotengine.org/en/4.4/tutorials/animation/playing_videos.html

## Pendiente de evaluación
- [ ] Comprobar que Blender 5.2 renderiza sin errores en la GPU local.
- [ ] Ver que el video mejora a la cinemática antigua en encuadre, nitidez, materiales y transiciones.
- [ ] Comprobar OGV Desktop y Web (Theora Web puede ser más lento).
- [ ] Afinar la física visual, despliegue de Sojourner y materialidad usando referencias reales.
- [ ] Elegir versión definitiva antes de integrar otros recuerdos.
