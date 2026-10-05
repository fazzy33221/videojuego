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

Reforma usa iluminacion ambiental azul y luz direccional calida. Seis zombies aparecen alrededor del Angel. Los niveles hornean una malla de navegacion en segundo plano desde los nodos del grupo `navigation_mesh_source_group`. Para integrar geometria nueva, agregala a ese grupo. Los modelos de escenario siguen siendo visuales salvo el suelo de colision de prueba; agrega colisiones fisicas para que el jugador tambien choque con paredes y vehiculos. El protagonista usa una postura sin arma y movimiento relativo a la camara.