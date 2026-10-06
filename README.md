# CDMX: Zona Cero

Aventura de supervivencia en Godot 4 para Android y PC. La partida nueva comienza en una ciudad ficticia de 300 x 300 metros, organizada alrededor de una avenida principal y una cuadrícula de calles secundarias. Incluye el Centro Antiguo, la Colonia del Lago, el Barrio del Mercado, la Zona Industrial y el Parque del Mirador. El diseño prioriza rutas transitables, cruces legibles, landmarks y colisiones ligeras para móvil.

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

El nivel principal utiliza `scripts/reforma_environment.gd` para crear calles, manzanas y zonas urbanas. La escena incluye un piso de respaldo y el jugador vuelve a su punto de aparición si cae fuera del mapa. `scenes/levels/act_one.tscn` conserva el escenario antiguo del metro, pero Nueva partida carga la ciudad. `scenes/levels/reforma_map_test.tscn` sirve para probar el trazado urbano por separado.

### Diseño de la ciudad

La avenida norte-sur conecta la zona comercial del sur con el Centro Antiguo. Calles transversales forman barrios de escala peatonal; los callejones y patios entre edificios dan rutas secundarias. La ciudad distingue las zonas mediante alturas, paletas y espacios abiertos. Entre sus referencias están la torre del centro, la escuela, el mercado con gasolinera, las bodegas y el parque con cancha. Los edificios usan colisiones de caja y el detalle se mantiene acotado para Android.

La escena `scenes/levels/reforma_map_test.tscn` permite recorrer el blockout urbano de forma independiente con **Run Current Scene (F6)**.

## Compilacion Android

Cada `push` ejecuta `.github/workflows/build_apk.yml` con Godot 4.7.2 y exporta un APK de depuracion a `build/android/juego.apk`. Descarga el artefacto `videojuego-android-apk` desde la ejecucion del workflow en GitHub Actions. Este APK esta firmado con la clave de depuracion de Godot y es para pruebas, no para publicar en Google Play.