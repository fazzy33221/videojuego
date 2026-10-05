# CDMX: Zona Cero

Base jugable en Godot 4 para una aventura de supervivencia en dos actos. La partida inicia en Paseo de la Reforma y la mision es encontrar la ruta de evacuacion.

## Ejecutar

Abre `project.godot` con Godot 4 e inicia la escena principal. Godot importara los recursos 3D la primera vez.

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

Reforma instancia el mapa GLTF original con escala uniforme 100 y posicion local `(0, -10, 0)` para compensar la altura del origen importado. El modelo mide aproximadamente 506 x 88 x 368 m despues de importarse y escalarse; la escena conserva sus proporciones y geometria. La prueba independiente `scenes/levels/reforma_map_test.tscn` contiene la reticula urbana procedural de 5 x 5 manzanas. El nivel principal usa iluminacion ambiental neutral, genera una colision estatica agrupada para el mapa y hornea la navegacion de forma asincrona. Los zombies esperan a que NavigationServer sincronice la malla y se alinean con el suelo fisico antes de perseguir. El jugador aparece en el marcador sobre la superficie medida del modelo; la camara conserva su far clip predeterminado de 4000 m. Los niveles hornean una malla de navegacion desde los nodos del grupo `navigation_mesh_source_group`; para integrar geometria nueva, agregala a ese grupo. La camara sigue suavemente desde un pivote independiente del giro del personaje, y al estar quieto el modelo vuelve a su pose de reposo sin reutilizar un fotograma de caminata como postura de arma.

### Probar el mapa de Reforma

Abre `scenes/levels/reforma_map_test.tscn` y ejecuta **Run Current Scene (F6)** para recorrer el mapa nuevo sin zombies ni cambiar la escena principal del juego. Usa WASD para moverte, Shift para correr, el raton para mirar y Escape para liberar el cursor.

## Compilacion Android

Cada `push` ejecuta `.github/workflows/build_apk.yml` con Godot 4.7.2 y exporta un APK de depuracion a `build/android/juego.apk`. Descarga el artefacto `videojuego-android-apk` desde la ejecucion del workflow en GitHub Actions. Este APK esta firmado con la clave de depuracion de Godot y es para pruebas, no para publicar en Google Play.