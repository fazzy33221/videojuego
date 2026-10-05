# CDMX: Zona Cero

Base jugable en Godot 4 para una aventura de supervivencia en dos actos. La partida inicia en Paseo de la Reforma y la mision es encontrar la ruta de evacuacion.

## Ejecutar

Abre `project.godot` con Godot 4 e inicia la escena principal. Godot importara los recursos 3D la primera vez.

## Controles

- WASD o flechas: movimiento
- Raton: camara
- Shift: correr
- Espacio: saltar
- F: encender/apagar linterna
- Escape: liberar el cursor

## Estructura

- `scenes/`: escena principal, jugador, zombie y niveles
- `scripts/`: control del jugador, IA, niveles y progresion
- `assets/models/zombies/`: modelos FBX extraidos del pack zombie
- `Modelos 3d/` y `mapa 3D/`: recursos originales conservados
- `Player/ModelPivot/CharacterModel` en `scenes/player.tscn`: modelo principal X Bot

Reforma usa iluminacion ambiental azul y luz direccional calida. Seis zombies aparecen alrededor del Angel. El mapa GLTF de Reforma se instancia en el origen con rotacion `(0, 0, 0)`, escala uniforme 100 y un desplazamiento local de `-0.1` en Y para apoyar la geometria en el nivel; sus mallas reciben colision estatica al cargar el acto. El jugador aparece 0.05 unidades sobre el marcador de inicio. Los niveles hornean una malla de navegacion desde los nodos del grupo `navigation_mesh_source_group`; para integrar geometria nueva, agregala a ese grupo. La camara sigue suavemente desde un pivote independiente del giro del personaje, y al estar quieto el modelo vuelve a su pose de reposo sin reutilizar un fotograma de caminata como postura de arma.

## Compilacion Android

Cada `push` ejecuta `.github/workflows/build_apk.yml` con Godot 4.7.2 y exporta un APK de depuracion a `build/android/juego.apk`. Descarga el artefacto `videojuego-android-apk` desde la ejecucion del workflow en GitHub Actions. Este APK esta firmado con la clave de depuracion de Godot y es para pruebas, no para publicar en Google Play.