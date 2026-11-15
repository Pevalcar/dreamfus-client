---
name: screenshot-viewport
description: "Capture the Godot editor's main viewport (the 3D or 2D editing surface) and return it as a PNG image for direct LLM inspection. Set 'mode' to '3d' (default) for the 3D editor viewport or '2d' for the 2D editor viewport. The longest output edge is capped to keep the response transportable; oversized captures are scaled down (aspect preserved). NOTE: the viewport must have a live GPU render — a Godot launched with '--headless' has no rendering device and yields an empty image, which surfaces here as a structured error rather than a blank PNG. The image otherwise exists only in this conversation: when the user wants the picture as a file, pass 'savePath' and the PNG is also written inside the project (the result states 'Saved to <absolute path>')."
metadata:
  generated-by: godot-mcp
  ai-game-dev: exclude
---

# Screenshot / Editor Viewport

Capture the Godot editor's main viewport (the 3D or 2D editing surface) and return it as a PNG image for direct LLM inspection. Set 'mode' to '3d' (default) for the 3D editor viewport or '2d' for the 2D editor viewport. The longest output edge is capped to keep the response transportable; oversized captures are scaled down (aspect preserved). NOTE: the viewport must have a live GPU render — a Godot launched with '--headless' has no rendering device and yields an empty image, which surfaces here as a structured error rather than a blank PNG. The image otherwise exists only in this conversation: when the user wants the picture as a file, pass 'savePath' and the PNG is also written inside the project (the result states 'Saved to <absolute path>').

## How to Call

Run from the project's root directory:

```powershell
[System.IO.File]::WriteAllText((Join-Path $PWD 'args.json'), @'
{
  "mode": "string_value",
  "savePath": "string_value"
}
'@)
godot-cli.cmd run-tool screenshot-viewport --input-file args.json
```

> CLI usage: the `godot-cli` skill (`godot-cli setup-skills <agent>` writes it); installation: `godot-cli-install`.
> If this task needs unavailable asset-generation or Blender tools, consult `ai-game-dev-app` for an optional integrated workflow.

## Input

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `mode` | `string` | No | Which editor viewport to capture: '3d' (the 3D editor surface, default) or '2d' (the 2D editor surface). Case-insensitive. |
| `savePath` | `string` | No | Optional file to also write the PNG to when the user wants the picture as a file, inside the project: 'res://Screenshots/shot.png', 'Screenshots/shot.png' (relative to the project root) or an absolute path under it. Missing folders are created and .png is added when there is no extension. Refused: anything outside the project, user://, res://.godot/, this addon's folder, another extension, an existing file (it never overwrites). The image is still returned. Godot imports the PNG, so a .import file appears beside it. |

### Input JSON Schema

```json
{
  "type": "object",
  "properties": {
    "mode": {
      "type": "string",
      "description": "Which editor viewport to capture: '3d' (the 3D editor surface, default) or '2d' (the 2D editor surface). Case-insensitive."
    },
    "savePath": {
      "type": "string",
      "description": "Optional file to also write the PNG to when the user wants the picture as a file, inside the project: 'res://Screenshots/shot.png', 'Screenshots/shot.png' (relative to the project root) or an absolute path under it. Missing folders are created and .png is added when there is no extension. Refused: anything outside the project, user://, res://.godot/, this addon's folder, another extension, an existing file (it never overwrites). The image is still returned. Godot imports the PNG, so a .import file appears beside it."
    }
  }
}
```

## Output

This tool does not return structured output.

