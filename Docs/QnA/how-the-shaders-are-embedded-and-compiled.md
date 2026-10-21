# How are the shaders embedded and compiled?

- **Recorded:** 2026-10-21
- **Last updated:** 2026-10-21

The repository has no `.metal` file. The vertex and fragment functions live in a
Swift multi-line string, [`metal/service.swift`](../../metal/service.swift)
(`shaderSource`), and are compiled when the service starts.

## Runtime compilation

[`metal/service.swift`](../../metal/service.swift) (`Renderer.init`) calls:

```swift
let library = try device.makeLibrary(source: shaderSource, options: nil)
```

It then looks up the functions by name: `square_vertex` returns a `VertexOut` with
a clip-space position, and `square_fragment` returns the orange fill. Missing
functions fail initialization with a `[metal-service]` message.

Why compile at runtime?

- The executable has no resource bundle, path lookup, or build step for shaders.
- The source sits next to the Swift pipeline code, so a change is one file.
- The cost is that shader syntax and type errors appear at launch. `make check`
  cannot catch them. Launch the app after touching the shader.

## The shared uniform layout

The Swift struct and the MSL struct must match:

```text
SIMD2<Float> resolution    <->    float2 resolution
Float        angle         <->    float angle
```

[`metal/service.swift`](../../metal/service.swift) (`Renderer.draw`) passes the Swift
value with `setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride,
index: 0)`. `stride` includes any padding the Swift layout requires. If the fields
or their order change, update both declarations and the shader's use of them in the
same commit.

## What the shader computes

- The four corners are a constant `float2` array selected by `vertex_id`.
- Each corner is scaled by `0.9` and rotated by `angle` using sine and cosine.
- x is multiplied by `resolution.y / max(resolution.x, 1.0)` so the quad stays
  square in normalized device coordinates.
- The fragment function returns `float4(0.98, 0.44, 0.12, 1.0)`.

There is no texture sampling, lighting, or depth test. Keeping the shader this
small is what makes runtime compilation acceptable.

## Verifying a shader change

1. Run `make check` to catch Swift-side mistakes.
2. Run `ruby core.rb` and confirm the window appears and the square rotates.
3. Resize the window and confirm the quad remains square.
4. Close the window and confirm the terminal returns to the prompt.

If the launch fails, the `[metal-service]` line on stderr identifies whether the
library, a function, or the pipeline could not be created.
