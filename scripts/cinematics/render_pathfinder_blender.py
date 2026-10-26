"""
Starlight Legacy / Pathfinder (1997) video production scene.
Procedurally builds a stylized 3D reenactment WITHOUT the in-game greyboxes.
Blender 5.2 compatible. NASA hardware chronology checked; simplified visuals.
Usage:
  blender --background --factory-startup --python scripts/cinematics/render_pathfinder_blender.py -- --quality draft --output-prefix <folder>/frame_
Draft: 960x540 12fps, Final: 1280x720 24fps, 16 seconds.
All output stays local: source repository holds reproducible render instructions.
"""
import argparse
import math
import os
import random
import sys

import bpy
from mathutils import Vector, noise

random.seed(1997)
argp = argparse.ArgumentParser()
argp.add_argument("--quality", choices=("draft", "final"), default="draft")
argp.add_argument("--output-prefix", required=True)
args = argp.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE" if bpy.app.version >= (5, 0, 0) else "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 960 if args.quality == "draft" else 1280
scene.render.resolution_y = 540 if args.quality == "draft" else 720
scene.render.resolution_percentage = 100
FPS = 12 if args.quality == "draft" else 24
scene.render.fps = FPS
scene.frame_start = 1
scene.frame_end = 16 * FPS
scene.render.film_transparent = False
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGB"
scene.render.filepath = args.output_prefix
scene.camera = None
scene.view_settings.view_transform = "AgX"


def at(seconds):
    return max(1, min(scene.frame_end, round(seconds * FPS) + 1))


def key_location(obj, points):
    for seconds, position in points:
        obj.location = position
        obj.keyframe_insert(data_path="location", frame=at(seconds))


def key_scale(obj, points):
    for seconds, value in points:
        obj.scale = (value, value, value)
        obj.keyframe_insert(data_path="scale", frame=at(seconds))


def key_visibility(obj, items):
    for seconds, visible in items:
        obj.hide_render = not visible
        obj.keyframe_insert(data_path="hide_render", frame=at(seconds))


def mat(name, color, metal=0.0, roughness=0.72, emission=0.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metal
    shader.inputs["Roughness"].default_value = roughness
    if emission:
        shader.inputs["Emission Color"].default_value = (*color, 1.0)
        shader.inputs["Emission Strength"].default_value = emission
    return material


RED_SAND = mat("Martian regolith", (0.39, 0.14, 0.088))
DUST = mat("Airborne fine rust", (0.76, 0.43, 0.26))
DARK_ROCK = mat("Basalt rock", (0.22, 0.13, 0.105))
STONE = mat("Eroded sandstone", (0.50, 0.28, 0.20))
GOLD = mat("Gold insulation", (0.64, 0.41, 0.15), 0.58, 0.41)
DARK_GOLD = mat("Dark bronze", (0.29, 0.20, 0.13), 0.52, 0.46)
GRAPHITE = mat("Scientific equipment", (0.075, 0.082, 0.092), 0.32, 0.52)
SOLAR = mat("Deep blue solar cells", (0.025, 0.090, 0.17), 0.34, 0.25)
AIRBAG = mat("Kevlar-colored airbag fabric", (0.85, 0.77, 0.61), 0.0, 0.91)
WHITE = mat("Parachute cream", (0.86, 0.82, 0.69), 0.0, 0.85)
RED = mat("Parachute red", (0.63, 0.13, 0.11), 0.0, 0.83)
FIRE = mat("Rocket flame", (1.0, 0.35, 0.045), 0, 0.5, 5.0)


def put_material(obj, material):
    obj.data.materials.append(material)
    return obj


def parent_to(obj, root):
    obj.parent = root
    return obj


def empty(name, location=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    if parent:
        obj.parent = parent
    return obj


def cube(name, location, dimensions, material, parent=None, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    put_material(obj, material)
    if bevel:
        m = obj.modifiers.new("Soft machined edges", "BEVEL")
        m.width = bevel
        m.segments = 2
        obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    if parent:
        obj.parent = parent
    return obj


def sphere(name, location, scale, material, parent=None, lowpoly=False):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1 if lowpoly else 3, radius=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    put_material(obj, material)
    if not lowpoly:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    if parent:
        obj.parent = parent
    return obj


def cylinder(name, location, radius, depth, material, rotation=(0, 0, 0), parent=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = rotation
    put_material(obj, material)
    if parent:
        obj.parent = parent
    return obj


def bar(name, a, b, radius, material, parent=None):
    vec = Vector(b) - Vector(a)
    center = (Vector(a) + Vector(b)) / 2
    obj = cylinder(name, center, radius, vec.length, material, parent=parent)
    obj.rotation_euler = vec.to_track_quat("Z", "Y").to_euler()
    return obj


# 1. Broad, detailed procedural Mars valley. Do not use a flat box floor.
bpy.ops.mesh.primitive_grid_add(x_subdivisions=95, y_subdivisions=95, size=60)
ground = bpy.context.object
ground.name = "Ares Vallis / cinematic terrain"
for vertex in ground.data.vertices:
    x, y = vertex.co.x, vertex.co.y
    hill = noise.noise(Vector((x * 0.11, y * 0.11, 5.3))) * 0.85
    grain = noise.noise(Vector((x * 0.71, y * 0.71, 1.6))) * 0.11
    dist = math.hypot(x, y)
    flat = min(1.0, max(0.07, (dist - 2) / 9.0))
    vertex.co.z = (hill + grain) * flat
put_material(ground, RED_SAND)
for polygon in ground.data.polygons:
    polygon.use_smooth = True

for i in range(72):
    x = random.uniform(-23, 23)
    y = random.uniform(-24, 24)
    if math.hypot(x, y) < 3.7:
        continue
    size = random.uniform(0.15, 1.0)
    stone = sphere("Ares rock %02d" % i, (x, y, -0.07),
                   (size, size * random.uniform(0.75, 1.3), size * 0.45),
                   random.choice([DARK_ROCK, STONE]), lowpoly=True)
    stone.rotation_euler.z = random.uniform(-3.14, 3.14)

# The material remains independent of NASA photos; studio lighting is intentional.
world = bpy.data.worlds.new("Dusty Martian atmosphere")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
bg.inputs["Color"].default_value = (0.41, 0.22, 0.19, 1)
bg.inputs["Strength"].default_value = 0.72

bpy.ops.object.light_add(type="AREA", location=(-7, -6, 15))
key = bpy.context.object
key.name = "Low Martian sun"
key.data.energy = 2700
key.data.shape = "DISK"
key.data.size = 9
key.data.color = (1.0, 0.62, 0.37)
bpy.ops.object.light_add(type="AREA", location=(8, 5, 11))
fill = bpy.context.object
fill.name = "Dust bounce fill"
fill.data.energy = 1200
fill.data.shape = "DISK"
fill.data.size = 12
fill.data.color = (0.67, 0.72, 0.98)

# 2. Pathfinder and a more cinematic, purpose-made lander model.
landing = empty("Pathfinder / falling object")
body = cube("Pathfinder tetrahedral body", (0, 0, 0.55), (1.65, 1.45, 0.78),
            GOLD, landing, 0.12)
cube("Upper avionics package", (0, 0, 1.02), (0.85, 0.75, 0.30),
     DARK_GOLD, landing, 0.06)
for i, xy in enumerate([(-0.73, -0.62), (0.73, -0.62), (-0.73, 0.62), (0.73, 0.62)]):
    bar("Lander strut %d" % i, (0, 0, 0.45), (xy[0], xy[1], 0.13), 0.055, GRAPHITE, landing)

petals = []
for name, loc, dimensions, rotation_end in [
    ("Left solar petal", (-1.40, 0, 0.14), (1.8, 1.3, 0.095), (0, -0.015, 0)),
    ("Right solar petal", (1.40, 0, 0.14), (1.8, 1.3, 0.095), (0, 0.015, 0)),
    ("Rear solar petal", (0, 1.40, 0.14), (1.3, 1.8, 0.095), (0, 0, 0))
]:
    wing = cube(name, loc, dimensions, SOLAR, landing, 0.032)
    petals.append((wing, tuple(loc), rotation_end))
    for t in [0, 7.55]:
        wing.location = (0, 0, 0.95)
        wing.rotation_euler = (math.radians(68), 0, math.radians(120) if "Rear" in name else 0)
        wing.keyframe_insert(data_path="location", frame=at(t))
        wing.keyframe_insert(data_path="rotation_euler", frame=at(t))
    for t in [9.8, 16]:
        wing.location = loc
        wing.rotation_euler = rotation_end
        wing.keyframe_insert(data_path="location", frame=at(t))
        wing.keyframe_insert(data_path="rotation_euler", frame=at(t))

cylinder("Imaging mast", (0.4, 0.2, 1.55), 0.045, 1.0, GRAPHITE, parent=landing)
sphere("Mars imager head", (0.4, 0.2, 2.04), (0.22, 0.20, 0.14), DARK_GOLD, landing)
for i, obj in enumerate([body]):
    pass

# Airbags are grouped lobes, not a permanent part of the finished rover.
bags = []
for i in range(18):
    ang = math.tau * i / 18
    bag = sphere("Impact bag %02d" % i,
                 (math.cos(ang) * 1.2, math.sin(ang) * 1.08, 0.56),
                 (0.76, 0.78, 0.76), AIRBAG, landing)
    bags.append(bag)
    key_scale(bag, [(0, 0.001), (2.7, 0.001), (3.1, 1.0),
                    (6.7, 1.0), (8.4, 0.001), (16, 0.001)])

# Animated parachute as fabric radial panels with suspension cables.
canopy = empty("Parachute and suspension", (0, 0, 0), landing)
canopy.location.z = 5.8
for sector in range(16):
    angle0 = math.tau * sector / 16
    angle1 = math.tau * (sector + 1) / 16
    vertices = [(0, 0, 1.45)]
    for j in range(9):
        a = angle0 + (angle1 - angle0) * j / 8
        vertices.append((3.2 * math.cos(a), 3.2 * math.sin(a), 0.0))
    faces = [(0, j, j + 1) for j in range(1, 9)]
    mesh = bpy.data.meshes.new("Fabric sector")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    part = bpy.data.objects.new("Parachute panel %02d" % sector, mesh)
    bpy.context.collection.objects.link(part)
    put_material(part, RED if sector in (2, 3, 8, 9, 14, 15) else WHITE)
    part.parent = canopy
for j in range(12):
    a = math.tau * j / 12
    bar("Suspension line %02d" % j, (math.cos(a) * 3.15, math.sin(a) * 3.15, 0),
        (0.4 * math.cos(a), 0.4 * math.sin(a), -4.7), 0.015, GRAPHITE, canopy)
key_visibility(canopy, [(0, True), (3.5, True), (3.6, False), (16, False)])

flame = sphere("Braking rockets / conceptual", (0, 0, -0.7), (0.6, 0.6, 1.4), FIRE, landing)
key_scale(flame, [(0, 0.001), (2.4, 0.001), (2.7, 1.0),
                  (3.7, 0.9), (3.8, 0.001), (16, 0.001)])
key_location(landing, [
    (0, (0, 0, 13)), (2.7, (0, 0, 5.7)), (3.9, (0, 0, 0.65)),
    (4.65, (0, 0, 2.4)), (5.4, (0, 0, 0.42)),
    (5.9, (0, 0, 1.2)), (6.6, (0, 0, 0.15)), (16, (0, 0, 0.15))
])

# 3. Sojourner: one coherent small six-wheel rover, independent of game GLB.
rover = empty("Sojourner / independent film model", (0, -1.2, 0.4))
cube("Sojourner chassis", (0, 0, 0.33), (0.75, 1.07, 0.24), GOLD, rover, 0.06)
cube("Solar cell deck", (0, 0, 0.55), (0.91, 1.12, 0.045), SOLAR, rover, 0.02)
for side in [-1, 1]:
    for j, y in enumerate([-0.39, 0.0, 0.39]):
        cylinder("Rover wheel %s-%d" % (side, j),
                 (side * 0.50, y, 0.22), 0.19, 0.13, GRAPHITE,
                 (0, math.pi / 2, 0), rover)
        bar("Rocker arm %s-%d" % (side, j), (side * 0.31, y, 0.39),
            (side * 0.50, y, 0.22), 0.028, DARK_GOLD, rover)
bar("Sojourner instrument arm", (0, -0.38, 0.32), (0, -0.81, 0.13),
    0.041, DARK_GOLD, rover)
sphere("APXS probe", (0, -0.84, 0.13), (0.12, 0.12, 0.095), GRAPHITE, rover)
bar("Sojourner camera mast", (0.10, 0.25, 0.56), (0.10, 0.25, 0.84),
    0.035, GOLD, rover)
sphere("Camera", (0.10, 0.25, 0.87), (0.11, 0.13, 0.09), GRAPHITE, rover)
key_visibility(rover, [(0, False), (11.4, False), (11.45, True), (16, True)])
key_location(rover, [(0, (0, 0.5, 0.6)), (11.45, (0, 0.5, 0.6)),
                     (13.9, (0, -1.45, 0.34)), (16, (0, -2.4, 0.34))])

# Atmospheric dust at touchdown, with a deliberate but restrained silhouette.
for i in range(28):
    a = random.uniform(0, math.tau)
    d = random.uniform(1.0, 3.0)
    orb = sphere("Landing dust %02d" % i,
                 (d * math.cos(a), d * math.sin(a), 0.30 + random.random() * 0.8),
                 (0.10, 0.10, 0.10), DUST, lowpoly=True)
    key_scale(orb, [(0, 0.001), (3.6, 0.001), (4.2, random.uniform(0.6, 1.6)),
                    (5.6, 0.001), (16, 0.001)])

# 4. Shot composition, not Godot camera shots. Film ends on wide Martian view.
bpy.ops.object.camera_add(location=(11, -21, 16))
camera = bpy.context.object
camera.name = "Cinematic film camera"
camera.data.type = "PERSP"
camera.data.lens = 37
scene.camera = camera
focus = empty("Animated camera focus", (0, 0, 3))
constraint = camera.constraints.new("TRACK_TO")
constraint.target = focus
constraint.track_axis = "TRACK_NEGATIVE_Z"
constraint.up_axis = "UP_Y"
key_location(camera, [
    (0, (11, -22, 18)), (2.7, (8, -14, 11)),
    (4.2, (8.5, -15, 6.6)), (6.8, (8, -13, 5.5)),
    (8.4, (6.0, -10, 5.1)), (10.9, (-6.8, -9, 5.0)),
    (12.0, (-5.0, -6.8, 2.6)), (14.2, (5.3, -6.4, 2.5)),
    (16, (7.0, -12.4, 4.5))
])
key_location(focus, [
    (0, (0, 0, 10.1)), (2.7, (0, 0, 5.1)),
    (4.3, (0, 0, 1.15)), (7.5, (0, 0, 1.1)),
    (9.5, (0, 0, 0.78)), (12, (0, 0, 0.88)),
    (14.2, (0, -1.2, 0.55)), (16, (0, -1.3, 0.7))
])

# The clips will display Spanish historical subtitles in Godot, NOT baked in:
# this permits revisions, localization and precise timing independently.
out_dir = os.path.dirname(args.output_prefix)
os.makedirs(out_dir, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir, "pathfinder_film_scene.blend"))
scene.frame_set(1)
print("[STL] Render", args.quality, scene.render.resolution_x,
      "x", scene.render.resolution_y, FPS, "fps /", scene.frame_end, "frames")
bpy.ops.render.render(animation=True)
print("[STL] PNG SEQUENCE COMPLETE:", args.output_prefix)
