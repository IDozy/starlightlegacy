# Pathfinder — cinemática renderizada (Capítulo I)

La **secuencia 3D con el greybox** solo se conserva para comparar; este nuevo prototipo crea un **video offline** en Blender con un escenario independiente y lo conecta con Godot.

## Crear el vídeo en Windows (Blender 5.2)

1. Instala **FFmpeg** si no lo tienes: `winget install --id Gyan.FFmpeg -e` y reinicia PowerShell.
2. Desde la raíz del repositorio ejecuta:
   ```powershell
   .\scripts\cinematics\render_pathfinder.ps1 -Quality draft
   ```
   Si Blender no se autodetecta, agrega `-BlenderBinary "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"`.
3. El resultado `assets/videos/pathfinder/pathfinder_intro.ogv` se importa directamente en Godot. Ejecuta `levels/ares_vallis/pathfinder_video_intro.tscn` con **F6** o la historia normal con F5. Esc/E lo omiten.
4. Para una versión con mayor resolución: `-Quality final`. Los frames y el `.blend` generado quedan en `renders/pathfinder/`.

**Importante:** no existe un .ogv renderizado y verificado en el repositorio todavía. Este script se ejecuta en el Blender del usuario. La intro está preparada para abrir el mapa normal cuando falte el archivo, sin doble cinemática ni bloqueo. Los PNG, .blend generado y OGV son archivos locales de producción: revisar su tamaño y licencia antes de incorporarlos al PR.

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
