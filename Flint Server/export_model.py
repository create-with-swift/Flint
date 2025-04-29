import bpy
import sys
import os

# Get the output path from command line arguments
if len(sys.argv) > 1:
    output_path = sys.argv[-1]
    print(f"Using output path from command line: {output_path}")
else:
    # Fallback path if no argument is provided
    output_path = "OUTPUT_PATH_FOLDER/exported_model.usdz"
    print(f"No path argument found, using default: {output_path}")

# Print all objects in the scene for debugging
print("Objects in scene that will be exported:")
for obj in bpy.context.scene.objects:
    print(f" - {obj.name} (type: {obj.type}, visible: {obj.visible_get()})")

# Make sure the directory exists
directory = os.path.dirname(output_path)
if directory:
    os.makedirs(directory, exist_ok=True)
    print(f"Ensuring directory exists: {directory}")

# Select all objects to ensure everything gets exported
bpy.ops.object.select_all(action='SELECT')

print(f"Exporting Blender scene to GLB: {output_path}")

# Export to GLB format
bpy.ops.wm.usd_export(
    filepath=output_path,
)

print(f"Export completed successfully to: {output_path}")