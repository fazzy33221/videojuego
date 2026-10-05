# CDMX: Zona Cero

Base jugable en Godot 4 para una aventura de supervivencia en dos actos. El segundo acto usa temporalmente el modelo de la estacion Ex Hacienda de Enmedio; el mapa de Reforma queda fuera del nivel mientras se elige otro entorno.

## Ejecutar

Abre `project.godot` con Godot 4 e inicia la escena principal. La pantalla de inicio ofrece **Nueva partida**, **Continuar**, una guia de controles y opciones de volumen y sensibilidad de camara. El progreso se guarda localmente en el dispositivo. Godot importara los recursos 3D la primera vez.

### Entorno de desarrollo en Codespaces

El proyecto no necesita un entorno virtual de Python. Para trabajar con una version reproducible de Godot, abre el repositorio en GitHub Codespaces y selecciona **Reopen in Container**. El contenedor usa Godot 4.7.2, la misma version que la compilacion de Android, e importa los recursos al crearse.

Puedes comprobar la version con `godot --version` y validar la escena principal en modo sin interfaz con `godot --headless --path . --quit-after 1`. Para usar el editor grafico, instala Godot 4.7.2 en tu equipo y abre `project.godot`.

## Controles

En PC:
- WASD o flechas: movimiento
- Raton: camara
- Shift: correr
- Espacio: saltar
- F: encender/apagar linterna
- Escape: liberar el cursor

En Android:
- Joystick de la izquierda: movimiento
- Arrastrar en la mitad derecha: mover la camara
- Botones de la derecha: correr, saltar y encender/apagar la linterna

## Estructura

- `scenes/`: escena principal, jugador, zombie y niveles
- `scripts/`: control del jugador, IA, niveles y progresion
- `assets/models/zombies/`: modelos FBX extraidos del pack zombie
- `Modelos 3d/` y `mapa 3D/`: recursos originales conservados
- `Player/ModelPivot/CharacterModel` en `scenes/player.tscn`: modelo principal X Bot

El nivel principal instancia `Modelos 3d/v1_metro_ex_hacienda_de_enmedio.glb` temporalmente a escala original. El controlador genera colisiones estaticas para la geometria del mapa y hornea la navegacion de forma asincrona. Los nodos del mapa se agregan al grupo `navigation_mesh_source_group` para construir la malla de navegacion. El jugador aparece encima del centro del modelo y cae hasta la superficie. La escena `scenes/levels/reforma_map_test.tscn` se conserva como prueba independiente del mapa urbano anterior.

### Probar el mapa de Reforma

Abre `scenes/levels/reforma_map_test.tscn` y ejecuta **Run Current Scene (F6)** para recorrer el mapa nuevo sin zombies ni cambiar la escena principal del juego. Usa WASD para moverte, Shift para correr, el raton para mirar y Escape para liberar el cursor.

## Compilacion Android

Cada `push` ejecuta `.github/workflows/build_apk.yml` con Godot 4.7.2 y exporta un APK de depuracion a `build/android/juego.apk`. Descarga el artefacto `videojuego-android-apk` desde la ejecucion del workflow en GitHub Actions. Este APK esta firmado con la clave de depuracion de Godot y es para pruebas, no para publicar en Google Play.