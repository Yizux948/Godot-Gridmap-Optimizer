# Grid Visual Manager para Godot 4
Por **Yizux**
Un script de optimización de entorno para Godot 4, diseñado para mejorar significativamente el rendimiento al renderizar mapas creados con `GridMap`. El script extrae la geometría de un `GridMap` original, remueve las caras internas ocultas entre los bloques y divide el mundo en "chunks" (trozos) que se ocultan o muestran dinámicamente según la distancia al jugador.
## ✨ Características
- **Optimización por Chunks**: Divide tu GridMap masivo en porciones más pequeñas (por defecto 16x16x16) para un renderizado y manejo eficiente en memoria.
- **Distance Culling**: Oculta automáticamente los chunks que están demasiado lejos del jugador para ahorrar severos recursos de procesamiento.
- **Eliminación de Caras Ocultas (Face Culling)**: Analiza los bloques vecinos y solo dibuja las caras exteriores visibles, reduciendo drásticamente la cantidad de polígonos a dibujar.
- **Soporte UV2 para Lightmaps**: Genera y desenvuelve automáticamente el canal UV2 de los chunks para prepararlos para iluminación horneada (Baked Lightmaps / `LightmapGI`).
- **Generación de Colisiones**: Opción integrada para crear mallas de colisión estáticas (`StaticBody3D` + `CollisionShape3D`) que se ajustan perfectamente al terreno optimizado.
- **Uso directo desde el Editor (`@tool`)**: Herramienta lista para usar con botones directamente en el Inspector de Godot. Genera o limpia tu malla sin necesidad de darle Play al proyecto.
## 🚀 Instalación
1. Copia el archivo `grid_visual_manager.gd` en la carpeta de tu proyecto de Godot 4.
2. Crea un nodo `Node3D` en tu escena.
3. Arrastra el script `grid_visual_manager.gd` al nodo recién creado.
## ⚙️ Cómo Usar
Selecciona el nodo que tiene el script y configura los parámetros desde el panel del **Inspector**:
### 1. Configuración Principal
- **Target Grid Map**: Asigna aquí tu nodo `GridMap` original (el script lo ocultará automáticamente al ejecutarse).
- **Target Player**: Asigna el nodo de tu jugador (o tu cámara principal). Este nodo se usará como referencia para medir la distancia y saber qué chunks mostrar/ocultar.
- **Output Parent** *(Opcional)*: El nodo donde quieres que se agrupen los chunks generados. Si lo dejas vacío, se generarán como hijos directos de este nodo.
### 2. Ajustes de Generación
- **Generar Colisiones**: Actívalo si necesitas que el jugador colisione con el mapa optimizado.
- **Chunk Size**: El tamaño en bloques de cada subdivisión (por defecto `16`).
- **Culling Distance**: Distancia a partir de la cual los chunks se volverán invisibles (se calcula la distancia al cuadrado por eficiencia).
### 3. Acciones Editor (Botones)
- **Generar Malla**: Marca esta casilla. El script leerá el `GridMap`, calculará la geometría y generará las mallas optimizadas. (La casilla volverá sola a su estado inactivo al terminar).
- **Limpiar Malla**: Borra todos los chunks que se generaron previamente.
## ⚖️ Licencia
Este script se distribuye bajo la **Licencia MIT**. Eres libre de usarlo, modificarlo, y distribuirlo en proyectos personales o comerciales sin ninguna restricción, siempre y cuando se mantenga el aviso de copyright original.
## 👤 Autor y Redes
Desarrollado con ❤️ por **Yizux**
- 🐙 **GitHub:** [Yizux948](https://github.com/Yizux948)
- 📺 **YouTube:** [@yizux948](https://www.youtube.com/@yizux948)
- 🎵 **TikTok:** [@yizux948](https://www.tiktok.com/@yizux948)
---
*¡Si este script te resulta útil en tu juego, agradecería que me etiquetaras o te pasaras por mis redes para verlo en acción!*
