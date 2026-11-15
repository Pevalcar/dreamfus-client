---
name: screenshot-isolated
description: |-
  Render a target Node3D in ISOLATION (only the target is visible, in its own world) from a chosen camera angle, framed automatically to its bounding box, lit by a default directional light, and return the result as a PNG image for direct LLM inspection. Identify the target with 'nodeRef'. Choose the view with 'cameraView' (Front/Back/Left/Right/Top/Bottom). Pick a 'background' (SolidColor or Transparent) and, for SolidColor, a hex 'backgroundColor'. The target is rendered via a temporary off-screen copy, so the edited scene is never mutated. Output is a square 'resolution'x'resolution' PNG, capped to keep the response transportable. NOTE: rendering needs a real GPU — a Godot launched with '--headless' yields an empty image, surfaced here as a structured error rather than a blank PNG. The image otherwise exists only in this conversation: when the user wants the picture as a file, pass 'savePath' and the PNG is also written inside the project (the result states 'Saved to <absolute path>').
  
  Argument types —…
metadata:
  generated-by: godot-mcp
  ai-game-dev: exclude
---

# Screenshot / Isolated Node

Render a target Node3D in ISOLATION (only the target is visible, in its own world) from a chosen camera angle, framed automatically to its bounding box, lit by a default directional light, and return the result as a PNG image for direct LLM inspection. Identify the target with 'nodeRef'. Choose the view with 'cameraView' (Front/Back/Left/Right/Top/Bottom). Pick a 'background' (SolidColor or Transparent) and, for SolidColor, a hex 'backgroundColor'. The target is rendered via a temporary off-screen copy, so the edited scene is never mutated. Output is a square 'resolution'x'resolution' PNG, capped to keep the response transportable. NOTE: rendering needs a real GPU — a Godot launched with '--headless' yields an empty image, surfaced here as a structured error rather than a blank PNG. The image otherwise exists only in this conversation: when the user wants the picture as a file, pass 'savePath' and the PNG is also written inside the project (the result states 'Saved to <absolute path>').

Argument types — give these arguments as RQL values (as in rql-mutate): {key: value, …}, [a, b], "text", 1.5, true, ref("Node3D#12") from a query result, godot.find("Name"); leave out keys you do not need:
NodeRef — a node: ref("Node3D#12") from a query, godot.find("Name"), an instance id, or its path below the scene root as text ("Level/Player")

## How to Call

Run from the project's root directory:

```powershell
[System.IO.File]::WriteAllText((Join-Path $PWD 'args.json'), @'
{
  "nodeRef": "string_value",
  "cameraView": "string_value",
  "background": "string_value",
  "backgroundColor": "string_value",
  "fieldOfView": 0,
  "nearClipPlane": 0,
  "farClipPlane": 0,
  "padding": 0,
  "resolution": 0,
  "savePath": "string_value"
}
'@)
godot-cli.cmd run-tool screenshot-isolated --input-file args.json
```

> CLI usage: the `godot-cli` skill (`godot-cli setup-skills <agent>` writes it); installation: `godot-cli-install`.
> If this task needs unavailable asset-generation or Blender tools, consult `ai-game-dev-app` for an optional integrated workflow.

## Input

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `nodeRef` | `string` | Yes | Reference to the target Node3D to render in isolation (instanceId preferred, else path). RQL: NodeRef |
| `cameraView` | `string` | No | Camera angle relative to the target's bounding box. Default: Front. |
| `background` | `string` | No | Background mode for the render: SolidColor (default) or Transparent. |
| `backgroundColor` | `string` | No | Hex background color (e.g. '#404040'). Used only when background is SolidColor. |
| `fieldOfView` | `number` | No | Camera vertical field of view in degrees. Default: 60. |
| `nearClipPlane` | `number` | No | Near clip plane distance. Default: 0.05. |
| `farClipPlane` | `number` | No | Far clip plane distance. Default: 4000. |
| `padding` | `number` | No | Framing multiplier around the object. 1.0 = tight fit, 1.5 = 50% extra space. Default: 1.2. |
| `resolution` | `integer` | No | Output image resolution in pixels (width = height). Default: 512. |
| `savePath` | `string` | No | Optional file to also write the PNG to when the user wants the picture as a file, inside the project: 'res://Screenshots/shot.png', 'Screenshots/shot.png' (relative to the project root) or an absolute path under it. Missing folders are created and .png is added when there is no extension. Refused: anything outside the project, user://, res://.godot/, this addon's folder, another extension, an existing file (it never overwrites). The image is still returned. Godot imports the PNG, so a .import file appears beside it. |

### Input JSON Schema

```json
{
  "type": "object",
  "properties": {
    "nodeRef": {
      "type": "string",
      "description": "Reference to the target Node3D to render in isolation (instanceId preferred, else path). RQL: NodeRef"
    },
    "cameraView": {
      "type": "string",
      "enum": [
        "Front",
        "Back",
        "Left",
        "Right",
        "Top",
        "Bottom"
      ],
      "description": "Camera angle relative to the target's bounding box. Default: Front."
    },
    "background": {
      "type": "string",
      "enum": [
        "SolidColor",
        "Transparent"
      ],
      "description": "Background mode for the render: SolidColor (default) or Transparent."
    },
    "backgroundColor": {
      "type": "string",
      "description": "Hex background color (e.g. '#404040'). Used only when background is SolidColor."
    },
    "fieldOfView": {
      "type": "number",
      "description": "Camera vertical field of view in degrees. Default: 60."
    },
    "nearClipPlane": {
      "type": "number",
      "description": "Near clip plane distance. Default: 0.05."
    },
    "farClipPlane": {
      "type": "number",
      "description": "Far clip plane distance. Default: 4000."
    },
    "padding": {
      "type": "number",
      "description": "Framing multiplier around the object. 1.0 = tight fit, 1.5 = 50% extra space. Default: 1.2."
    },
    "resolution": {
      "type": "integer",
      "description": "Output image resolution in pixels (width = height). Default: 512."
    },
    "savePath": {
      "type": "string",
      "description": "Optional file to also write the PNG to when the user wants the picture as a file, inside the project: 'res://Screenshots/shot.png', 'Screenshots/shot.png' (relative to the project root) or an absolute path under it. Missing folders are created and .png is added when there is no extension. Refused: anything outside the project, user://, res://.godot/, this addon's folder, another extension, an existing file (it never overwrites). The image is still returned. Godot imports the PNG, so a .import file appears beside it."
    }
  },
  "required": [
    "nodeRef"
  ]
}
```

## Output

This tool does not return structured output.

