
# PS1 / PSX Visuals

This addon contains a set of shaders and materials you can use to make your game look like it was built on the original PlayStation hardware. Almost all of the limitations of the console have been faithfully implemented into a versatile set of shaders.

## Table of Contents

| Section | Description |
|-|-|
| [Quickstart](#quickstart) | How to set up the Plugin |
| [PsxMaterial3D](#psxmaterial3d) | The main event. How to create custom PSX materials and how to use them |
| [Shader Globals](#shader-globals) | A list of included global shader features |
| [Resource Conversion Tool](#conversion-tool) | How to use the conversion tool to quickly modify resources/scenes |
| [List of Visual Features]() | |

## Quickstart

To install:

1. Add the contents of this package to your project, into the folder `res://addons/psx`
2. In project Settings, enable the associated Plugin
3. Restart the editor
4. Verify installation by looking for the following components
	- Autoload Node called `psx_post_process`
	- [New Shader Globals](#shader-globals)
	- [New context menu options]() in the FileSystem and SceneTree
	- [New commands]() in the command palette
	- A newly created folder `res://addons/psx/shaders/cache` with some shader files inside

## `PsxMaterial3D`

`PsxMaterial3D` is a new kind of Material. In a PSX-style game, most (or all) of your 3D Geometry should inherit from `PsxMaterial3D`. It is very similar to `StandardMaterial3D`. To create one, either create a new Resource, or right-click on a Material in the FileSystem and choose `Context Menu > Convert Selected Resource(s) to PSX...`

### Additions to `StandardMaterial3D`

The following is an explanation of properties in `PsxMaterial3D` that differ from `StandardMaterial3D`.

- `fog_mode`: There are now 3 options for fog.
	- Disabled ( `render_mode fog_disabled` )
	- Per-Pixel ( unchanged, use regular distance fog )
	- Per-Vertex. This is the standard for PSX distance fog.

- Instance shader parameters `i_precision_uv`, `i_precision_xy`, and `i_precision_z`. These act as scalars for their shader global counterparts.

> [!TIP]
> Due to the way that PsxMaterial3D is implemented, a new shader may need to be created each time certain parameters are set. These shaders are stored in `res://addons/psx/shaders/cache`. The system will automatically handle these shaders, but they must be manually removed when no longer in use. It is recommended you do the following before exporting your project:
> 1. Close all open Scenes
> 2. Restart the editor
> 3. Open the command palette and run `Psx > Purge Unused Shaders`.
>
> This operation is very safe and will never delete any used shaders. Alternatively, you can delete the cache folder entirely, but this is a more nuclear option and may result in loss of data.

## Shader Globals

This is a list of all global shader properties (modified in `Project Settings > Globals > Shader Globals`). These properties are created when enabling the plugin for the first time.

- [`psx_affine_strength`](#psx_affine_strength)
- [`psx_bit_depth`](#psx_bit_depth)
- [`psx_fog_color`](#psx_fog_color)
- [`psx_fog_far`](#psx_fog_far)
- [`psx_fog_near`](#psx_fog_near)
- [`psx_precision_uv`](#vertex-precision-uv)
- [`psx_precision_xy`](#vertex-precision-xy)
- [`psx_precision_z`](#vertex-precision-z)

> [!TIP]
> Any or all of these properties can be converted to instance shader parameters if desired. Feel free to modify to your liking. For the sake of simplicity, they have been set to global parameters.

### `psx_affine_strength`

This component recreates the dizzying effect of textures warping due to a lack of a depth buffer. The default value is `1.0`. `0.0` will disable the effect. It is generally not recommended to use values outside the `0...1` range.

### `psx_bit_depth`

This component recreates the effect of rendered colors being limited to a certain number of bits, with a dithered matrix to interpolate between them. The default value is `5` (original hardware value). `0` disables the effect.

#### `psx_fog_color`

This determines the color of the fog. The opacity of this color will determine its strength. The default value is `Color.TRANSPARENT` (no fog).

#### `psx_fog_far`

This value controls at which distance the fog should reach full opacity. The default value is `20.0`, but this can be set to anything without compromising PSX authenticity.

#### `psx_fog_near`

This value controls at which distance the fog should reach full transparency. The default value is `10.0`, but this can be set to anything without compromising PSX authenticity.

> [!TIP]
> For more information about other implementations of PSX fog or how to implement them, see [this video by Elias Daler](https://www.youtube.com/watch?v=EwpFdMJlVP4).

### Vertex Snapping (Jitter)

This component recreates the effect of vertices being limited to integer screen pixels. It is controlled by the `psx_snap_distance` shader global. The default value is `1.0`. Higher values will increase the effect. `0.0` will disable the effect.

## Conversion Wizard

In a PSX-style game, you will want to use a PSX material on almost all `MeshInstance3D`s in every 3D scene. You can do this manually, but this can take lots of time. The Conversion Wizard is a tool that can help you convert scenes, materials, or an entire project into PSX.

> [!CAUTION]
> Using the conversion Wizard is currently irreversible. Make a backup or VCS commit of your project before using.

Keep in mind during the conversion process:

<!-- - If the `Node.owner` is not the scene root, the `Node` will not be processed. -->
- You can add a meta value named `psx_ignore` of type `bool` to any Node to control if the Wizard should modify any `Node`.
	- If `null` or not present, the converter will process the `Node` normally.
	- If `false`, the converter will ignore THIS `Node`, but will continue on to its children.
	- If `true`, the converter will ignore this `Node`, AND ALL its children.
- You can add a meta value named `psx_auto` of type `Material` to the root of any scene to enforce

# Visual Features Reference

## Affine Texture Warping

## Bit Depth Reduction

## Vertex Jitter



## Fog

This component recreates the distance fog effect used in the original [Silent Hill](https://youtu.be/6QD55_DcxrM) games. It applies a vertex-based additive emission to meshes, similar to how vertex lighting works. Using lower-poly meshes will therefore result in lower-detail fog, and high-resolution meshes will create higher-detail fog.  It is controlled by three values:


# Unsupported Features

This is a list of features that are not yet supported. Links to associated [GitHub issues](https://github.com/snotbane/psx_visuals/issues) are attached.

- [Painter's Algorithm / Z-Buffer Errors](https://github.com/snotbane/psx_visuals/issues/12)
