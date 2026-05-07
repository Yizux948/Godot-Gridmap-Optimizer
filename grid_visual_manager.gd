# ==============================================================================
# Grid Visual Manager para Godot 4
# ==============================================================================
# Autor: Yizux
# GitHub: https://github.com/Yizux948
# YouTube: https://www.youtube.com/@yizux948
# TikTok: https://www.tiktok.com/@yizux948
#
# Licencia MIT (MIT License)
# Copyright (c) 2026 Yizux
#
# Por la presente se concede permiso, libre de cargos, a cualquier persona que
# obtenga una copia de este software y de los archivos de documentación
# asociados (el "Software"), a utilizar el Software sin restricción, incluyendo
# sin limitación los derechos de usar, copiar, modificar, fusionar, publicar,
# distribuir, sublicenciar, y/o vender copias del Software, y a permitir a las
# personas a las que se les proporcione el Software a hacer lo mismo, sujeto a
# las siguientes condiciones:
#
# El aviso de copyright anterior y este aviso de permiso se incluirán en todas
# las copias o partes sustanciales del Software.
#
# EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA
# O IMPLÍCITA, INCLUYENDO PERO NO LIMITADO A GARANTÍAS DE COMERCIALIZACIÓN,
# IDONEIDAD PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO LOS
# AUTORES O TITULARES DEL COPYRIGHT SERÁN RESPONSABLES DE NINGUNA RECLAMACIÓN,
# DAÑOS U OTRAS RESPONSABILIDADES, YA SEA EN UNA ACCIÓN DE CONTRATO, AGRAVIO O
# CUALQUIER OTRO MOTIVO, QUE SURJA DE O EN CONEXIÓN CON EL SOFTWARE O EL USO U
# OTROS TRATOS EN EL SOFTWARE.
# ==============================================================================
@tool
extends Node3D

@export_group("Acciones Editor")
@export var generar_malla: bool = false:
	set(value):
		if value:
			build_optimized_world(true)

@export var limpiar_malla: bool = false:
	set(value):
		if value:
			clear_generated_meshes()

@export_group("Configuración Principal")
@export var target_grid_map: GridMap
@export var target_player: Node3D
@export var output_parent: Node3D

@export_group("Ajustes de Generación")
@export var generar_colisiones: bool = false
@export var chunk_size: int = 16
@export var culling_distance: float = 60.0

@export_group("Ajustes Lightmap / UV2")
@export var lightmap_texel_size: float = 0.2

var _chunk_nodes: Array[Node3D] = []
var _culling_distance_sq: float
var _frame_counter: int = 0

var _directions: Array[Vector3i] = [
	Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK
]

var _face_vertices: Array[Array] = [
	[Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)],
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)],
	[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1), Vector3(0, 0, 1)]
]

var _uvs: Array[Vector2] = [
	Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)
]

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if target_grid_map == null: return
	_culling_distance_sq = culling_distance * culling_distance
	target_grid_map.visible = false
	recollect_existing_chunks()

func recollect_existing_chunks() -> void:
	_chunk_nodes.clear()
	var parent_to_check: Node = output_parent if output_parent != null else self
	for child in parent_to_check.get_children():
		if child is Node3D and child.name.begins_with("Chunk_"):
			_chunk_nodes.append(child)

func clear_generated_meshes() -> void:
	var parent_to_clear: Node = output_parent if output_parent != null else self
	var children = parent_to_clear.get_children()
	for child in children:
		if child.name.begins_with("Chunk_"):
			if Engine.is_editor_hint():
				child.free()
			else:
				child.queue_free()
	_chunk_nodes.clear()
	print("GridVisualManager: Malla limpiada.")

func build_optimized_world(is_editor_action: bool) -> void:
	clear_generated_meshes()
	if target_grid_map == null: return

	var parent_node: Node3D = output_parent if output_parent != null else self
	var chunk_data = {}
	
	for cell in target_grid_map.get_used_cells():
		var chunk_pos = Vector3i(
			floor(float(cell.x) / chunk_size),
			floor(float(cell.y) / chunk_size),
			floor(float(cell.z) / chunk_size)
		)
		if not chunk_data.has(chunk_pos):
			chunk_data[chunk_pos] = []
		chunk_data[chunk_pos].append(cell)

	for key in chunk_data:
		generate_chunk_mesh(key, chunk_data[key], is_editor_action, parent_node)
	
	print("Malla generada con UV2 y bloqueada (Lock).")

func generate_chunk_mesh(chunk_coords: Vector3i, cells: Array, is_editor_action: bool, parent_node: Node3D) -> void:
	var chunk_node = Node3D.new()
	chunk_node.name = "Chunk_" + str(chunk_coords)
	chunk_node.position = Vector3(chunk_coords) * chunk_size * target_grid_map.cell_size
	parent_node.add_child(chunk_node)

	if is_editor_action and get_tree() != null:
		chunk_node.owner = get_tree().edited_scene_root
		chunk_node.set_meta("_edit_lock_", true)

	_chunk_nodes.append(chunk_node)

	var surface_tools = {}
	var active_tools = {}

	for cell in cells:
		var item_id = target_grid_map.get_cell_item(cell)
		if item_id == GridMap.INVALID_CELL_ITEM: continue

		if not surface_tools.has(item_id):
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			surface_tools[item_id] = st

		var current_tool: SurfaceTool = surface_tools[item_id]
		for i in range(6):
			var neighbor_pos = cell + _directions[i]
			if target_grid_map.get_cell_item(neighbor_pos) == GridMap.INVALID_CELL_ITEM:
				add_face_geometry(current_tool, i, cell, chunk_coords)
				active_tools[item_id] = true

	for item_id in surface_tools:
		if not active_tools.has(item_id): continue

		var st: SurfaceTool = surface_tools[item_id]
		st.generate_tangents()
		
		var mesh: ArrayMesh = st.commit()
		
		if is_editor_action:
			mesh.lightmap_unwrap(Transform3D.IDENTITY, lightmap_texel_size)

		var original_mesh: Mesh = target_grid_map.mesh_library.get_item_mesh(item_id)
		var mat: Material = null
		if original_mesh != null and original_mesh.get_surface_count() > 0:
			mat = original_mesh.surface_get_material(0)

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.name = "VisualMesh"
		if mat != null:
			mesh_instance.material_override = mat
		
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mesh_instance.set("gi_mode", 1)

		chunk_node.add_child(mesh_instance)

		if is_editor_action and get_tree() != null:
			mesh_instance.owner = get_tree().edited_scene_root
			mesh_instance.set_meta("_edit_lock_", true)

			if generar_colisiones:
				mesh_instance.create_trimesh_collision()
				var child = mesh_instance.get_child(0)
				if child is StaticBody3D:
					var static_body: StaticBody3D = child
					static_body.name = "StaticBody_Col"
					static_body.owner = get_tree().edited_scene_root
					static_body.set_meta("_edit_lock_", true)

					if static_body.get_child_count() > 0:
						static_body.get_child(0).owner = get_tree().edited_scene_root

func add_face_geometry(st: SurfaceTool, dir_index: int, cell_global_pos: Vector3i, chunk_coords: Vector3i) -> void:
	var cell_local_pos = Vector3(cell_global_pos) - (Vector3(chunk_coords) * chunk_size)
	cell_local_pos *= target_grid_map.cell_size

	var verts: Array = _face_vertices[dir_index]
	var normal = Vector3(_directions[dir_index])

	var indices: Array[int] = [0, 2, 1, 0, 3, 2]
	for idx in indices:
		st.set_normal(normal)
		var uv_idx = 1 if idx == 1 else (2 if idx == 2 else (3 if idx == 3 else 0))
		st.set_uv(_uvs[uv_idx])
		st.add_vertex(cell_local_pos + (verts[idx] * target_grid_map.cell_size))

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or target_player == null or _chunk_nodes.size() == 0: return

	_frame_counter += 1
	if _frame_counter < 15: return
	_frame_counter = 0

	var player_pos = target_player.global_position
	for chunk in _chunk_nodes:
		if is_instance_valid(chunk):
			var dist_sq = player_pos.distance_squared_to(chunk.global_position)
			chunk.visible = dist_sq < _culling_distance_sq
