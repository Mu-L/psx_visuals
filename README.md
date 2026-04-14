
# PS1 / PSX Visuals

This addon contains a set of shaders and materials you can use to make your game look like it was built on the original PlayStation hardware. Almost all of the limitations of the console have been faithfully implemented into a versatile set of shaders.

# Features

## Quickstart / Conversion Wizard

In a PSX-style game, almost all `MeshInstance3D`s will be using similar shaders included in this addon. Consider using the Conversion Wizard to do any of the following:

- Override the surface materials of any newly created `MeshInstance3D` nodes
- Override the surface materials of any currently existing `MeshInstance3D` nodes in your scene(s)
- Convert any material in the FileSystem to a PSX material

You can then change the material of any `MeshInstance3D` at any time.

## Materials

There are a few built-in materials for use or duplication:

- `mat_psx_default.tres` : Default material to showcase vertex effects. Works with Gouraud shading too.
- `mat_psx_placeholder.tres` : Placeholder material to showcase affine texture warping.
- `mat_psx_post_process.tres` : Built-in material to showcase bit depth reduction. DO NOT DELETE!
- `mat_psx_shadow_32x32.tres` : Built-in material to showcase `RayShadowCaster` shadows.

## Shaders

There are four shaders to choose from, though all of them are nearly identical except for a few static flags:

- `psx_opaque.gdshader` : Suitable for opaque or cutout textures.
- `psx_opaque_double.gdshader` : Double sided version of `psx_opaque`.
- `psx_transparent.gdshader` : Suitable for semi-opaque textures.
- `psx_transparent_double.gdshader` : Double sided version of `psx_transparent`.

## Global Shader Features

This is a list of all global shader properties (modified in `Project Settings > Globals > Shader Globals`). These properties are created when enabling the plugin for the first time.

- [`psx_affine_strength`](#affine-texture-mapping)
- [`psx_bit_depth`](#limited-color-bit-depth)
- [`psx_fog_color`](#psx_fog_color)
- [`psx_fog_far`](#psx_fog_far)
- [`psx_fog_near`](#psx_fog_near)
- [`psx_snap_distance`](#vertex-snapping-jitter)

> [!TIP]
> Any or all of these properties can be converted to instance shader parameters if desired. Feel free to modify to your liking. For the sake of simplicity, they have been set to global parameters.

### Affine Texture Mapping

This component recreates the dizzying effect of textures warping due to a lack of a depth buffer. It is controlled by the `psx_affine_strength` shader global. The default value is `1.0`. `0.0` will disable the effect. It is generally not recommended to use values outside the `0...1` range.

### Limited Color Bit Depth

This component recreates the effect of rendered colors being limited to a certain number of bits, with a dithered matrix to interpolate between them. It is controlled by the `psx_bit_depth` shader global. The default value is `5` (original hardware value). `0` disables the effect.

> [!NOTE]
> This effect is applied as post process, so it will not be visible in the editor; only at runtime. But, it will apply to the entire screen.

### Fog

This component recreates the distance fog effect used in the original [Silent Hill](https://youtu.be/6QD55_DcxrM) games. It applies a vertex-based additive emission to meshes, similar to how vertex lighting works. Using lower-poly meshes will therefore result in lower-detail fog, and high-resolution meshes will create higher-detail fog.  It is controlled by three values:

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

## Material / Instance Shader Parameters

This is a list of the uniform shader properties on all PSX shaders.

- [`use_vertex_colors_as_albedo`](#use-vertex-colors-as-albedo-gouraud-shading)
- [`use_global_fog`](#use-global-fog)
- [`albedo`](#albedo)
- [`albedo_tint`](#albedo-tint)
- [`emission`](#emission)
- [`emission_tint`](#emission-tint)
- [`alpha_scissor_threshold`](#alpha-scissor-threshold)

### Use Vertex Colors as Albedo (Gouraud Shading)

If this is enabled, the mesh's vertex color will be used as the base color for material. This is a simple way to give color details to a mesh without needing a texture. The default value is `true`.

> [!TIP]
> In Blender, you can add a vertex color layer by selecting `Properties Window > Data > Color Attributes > Add Color Attribute` and then modified using `Vertex Paint` mode.

### Use Global Fog

If this is enabled, global distance fog will be applied to this material. The default value is `true`.

### Albedo

This is the standard albedo texture for the material. Also determines opacity. If you already have vertex colors applied, consider using a grayscale albedo texture.

### Albedo Tint

Simple multiplier for `albedo`. Also affects opacity.

### Emission

This is the emission texture for the material. Not affected by vertex colors.

### Emission Tint

Simple multiplier for `emission`.

### Alpha Scissor Threshold

Simple hook for `ALPHA_SCISSOR_THRESHOLD`. Only affects the material when `albedo` contains transparent pixels.
