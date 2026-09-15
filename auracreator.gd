extends Node3D
class_name AuraFlameGenerator

## Attach to a Node3D positioned at the character's feet (origin at ground level).
## Call generate() once (e.g. in _ready) or whenever you want to rebuild the aura.

@export var flame_material: ShaderMaterial

@export_group("Ring Shape")
@export var fin_count: int = 8
@export var ring_radius: float = 0.35        # how far fins sit from center
@export var radius_jitter: float = 0.08      # randomizes each fin's distance from center

@export_group("Fin Shape")
@export var flame_height: float = 2.0        # should match shader's flame_height uniform
@export var height_jitter: float = 0.4       # some fins taller than others
@export var base_width: float = 0.25
@export var width_jitter: float = 0.1
@export var tip_width: float = 0.02          # near-zero = fin comes to a point
@export var segments: int = 6                # vertical subdivisions per fin (more = smoother taper/wobble in shader)
@export var lean_amount: float = 0.15         # fins lean outward slightly like real flame tongues

@export_group("Randomization")
@export var seed_value: int = 0               # 0 = random each time
@export var rotation_jitter_deg: float = 15.0  # random twist per fin


func generate() -> void:
	for child in get_children():
		child.queue_free()

	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	for i in range(fin_count):
		var angle: float = (TAU / fin_count) * i
		var jittered_angle: float = angle + deg_to_rad(rng.randf_range(-rotation_jitter_deg, rotation_jitter_deg))
		var radius: float = ring_radius + rng.randf_range(-radius_jitter, radius_jitter)

		var h: float = flame_height + rng.randf_range(-height_jitter, height_jitter)
		var bw: float = base_width + rng.randf_range(-width_jitter, width_jitter)

		var fin_mesh: ArrayMesh = _build_fin_mesh(h, bw, tip_width, segments, lean_amount)

		var mi := MeshInstance3D.new()
		mi.mesh = fin_mesh
		mi.material_override = flame_material
		mi.position = Vector3(cos(jittered_angle) * radius, 0.0, sin(jittered_angle) * radius)
		# Face outward from center, plus a slight random twist so fins don't look uniform
		mi.rotation.y = -jittered_angle + deg_to_rad(rng.randf_range(-20.0, 20.0))
		add_child(mi)


## Builds a single tapered, slightly curved flame "fin" as a double-sided vertical strip.
func _build_fin_mesh(height: float, base_w: float, tip_w: float, segs: int, lean: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var left_verts: Array[Vector3] = []
	var right_verts: Array[Vector3] = []

	for s in range(segs + 1):
		var t: float = float(s) / float(segs)          # 0 at base, 1 at tip
		var y: float = t * height
		var w: float = lerp(base_w, tip_w, pow(t, 1.5)) # ease-out taper, most width lost near tip
		var lean_offset: float = lean * pow(t, 2.0) * height  # curves outward as it rises

		left_verts.append(Vector3(-w * 0.5, y, lean_offset))
		right_verts.append(Vector3(w * 0.5, y, lean_offset))

	# Build two-triangle quads per segment, both winding orders (so it's visible from both sides
	# without needing cull_disabled, in case you'd rather cull_back stays on for perf)
	for s in range(segs):
		var bl: Vector3 = left_verts[s]
		var br: Vector3 = right_verts[s]
		var tl: Vector3 = left_verts[s + 1]
		var tr: Vector3 = right_verts[s + 1]

		var v0: float = float(s) / float(segs)
		var v1: float = float(s + 1) / float(segs)

		_add_quad(st, bl, br, tr, tl, v0, v1)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()


func _add_quad(st: SurfaceTool, bl: Vector3, br: Vector3, tr: Vector3, tl: Vector3, v0: float, v1: float) -> void:
	# UV.y maps to height_ratio (0 base -> 1 tip), matches shader's height_ratio expectations if you
	# choose to drive it from UV instead of object-space Y — kept both available for flexibility.
	st.set_uv(Vector2(0.0, v0)); st.add_vertex(bl)
	st.set_uv(Vector2(1.0, v0)); st.add_vertex(br)
	st.set_uv(Vector2(1.0, v1)); st.add_vertex(tr)

	st.set_uv(Vector2(0.0, v0)); st.add_vertex(bl)
	st.set_uv(Vector2(1.0, v1)); st.add_vertex(tr)
	st.set_uv(Vector2(0.0, v1)); st.add_vertex(tl)

	# Back face (reversed winding) so fins are visible from both sides
	st.set_uv(Vector2(0.0, v0)); st.add_vertex(bl)
	st.set_uv(Vector2(1.0, v1)); st.add_vertex(tr)
	st.set_uv(Vector2(1.0, v0)); st.add_vertex(br)

	st.set_uv(Vector2(0.0, v0)); st.add_vertex(bl)
	st.set_uv(Vector2(0.0, v1)); st.add_vertex(tl)
	st.set_uv(Vector2(1.0, v1)); st.add_vertex(tr)


func _ready() -> void:
	generate()
