PARCHE DE REFORMA - CDMX: ZONA CERO

Problema corregido
------------------
El nivel habia dejado de instanciar el glTF original y mostraba una geometria
procedural reducida. El recurso glTF conserva una escala de raiz cercana a
0.0058088065, aplicada por su configuracion de importacion; la escena debe
mantener una escala uniforme de 100 para que el mapa tenga dimensiones urbanas.
La elevacion positiva del terreno se compensa colocando ReformaEnvironment en
Y = -10. MapGeometry conserva su transformacion local en el origen.
La comprobacion del recurso importado da unas dimensiones de 506.3 x 88.2 x
368.4 m. La escala 100 y la correccion de Y producen esos limites sin alterar
la geometria.

No uses scale = 10. Reduciria el mapa completo a unas dimensiones demasiado
pequenas y no arreglaria su origen vertical. No se modifican el glTF, sus
archivos binarios, sus mallas ni las proporciones individuales.

Archivos incluidos
------------------
scenes/levels/act_two.tscn
scripts/level_controller.gd
scripts/zombie_ai.gd
.github/workflows/build_apk.yml
mapa 3D/textures/Model_15_baseColor.jpeg

El JPEG de Model_15 es una textura gris neutra de 4 x 4 px. Repara la
referencia ausente sin sustituir el aspecto de los demas materiales.
El workflow mantiene Godot 4.7.2 y habilita la descarga de Git LFS.

Instalacion
-----------
1. Haz una copia de seguridad del proyecto.
2. Extrae el ZIP sobre la raiz del repositorio, conservando las rutas.
3. Abre el proyecto con Godot 4.7.2 y deja que importe los recursos.
4. Abre scenes/levels/act_two.tscn o ejecuta el juego.

Comprobacion
------------
- ReformaEnvironment: position = Vector3(0, -10, 0), escala uniforme 100.
- MapGeometry: position local = Vector3(0, 0, 0).
- PlayerSpawn: Y = 5.25 m. En la ubicacion de inicio la superficie medida esta
  a Y ~= 5.17 m; usar Y = 0 colocaba al jugador debajo de la malla local.
- Cada zombie alinea su altura mediante un raycast a las colisiones reales del
  mapa cuando NavigationServer esta sincronizado.
- La escena no reduce ni deforma el glTF original.
- El jugador usa collision mask 3; el mapa estatico usa layer 1 y mask 0.
- Los zombies esperan a que la malla de navegacion se sincronice y persiguen
  directamente al jugador si la navegacion no queda disponible a tiempo.
- El bake de navegacion corre en hilo y usa celdas de 0.5 m para reducir el
  coste de la malla de 500 x 368 m. Si una ruta no esta disponible, el zombie
  conserva la persecucion directa y el comportamiento de ataque.
- La camara mantiene su far clip predeterminado de Godot (4000 m), suficiente
  para el mapa; no se configura visibility_range ni culling personalizado.
- El renderer GL Compatibility se conserva para Android.

En Godot, revisa la posicion y escala de ReformaEnvironment y MapGeometry en el
Inspector. Ejecuta el nivel y comprueba que el jugador aparece sobre el suelo,
que el mapa completo se ve a su escala natural y que las colisiones y zombies
funcionan despues del bake de navegacion.
