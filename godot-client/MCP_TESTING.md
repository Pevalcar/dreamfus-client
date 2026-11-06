# Testing Guide for Godot MCP Toolkit

## ⚠️ IMPORTANT: Prerequisites

Before testing, you MUST have Godot editor open. The MCP server is a **client** that connects to Godot, it doesn't start Godot itself.

## Step-by-Step Testing

### 1. Configure OpenCode to recognize the MCP

The MCP server name must be consistent. The configuration is now in:
- **File**: `godot-client/.mcp.json`

This matches the global `opencode.json` configuration.

### 2. Start Godot Editor (REQUIRED)

1. Open Godot 4.8 beta2
2. Load the project: `godot-client/project.godot`
3. **Wait for Godot to fully load** - this can take 30-60 seconds

### 3. Verify Plugin is Loaded

1. Go to **Project Settings → Plugins**
2. Look for **"Godot MCP Toolkit"**
3. Ensure it's **enabled** (checkbox checked)

### 4. Check MCP Dock

1. Look at the bottom panel in Godot editor
2. You should see a **MCP dock** with status showing something like:
   ```
   MCP Server Connected
   Tools: 113
   Port: 655x (varies)
   ```

### 5. Restart OpenCode

**After Godot is loaded with the plugin enabled:**
1. Close OpenCode completely
2. Reopen OpenCode (this forces it to reload MCP servers)
3. OpenCode should now see the `godot` MCP server

### 6. Test MCP Tools

You can now use tools like:
- `godot.scene_load` - Load a scene file
- `godot.scene_get_children` - Get children of a scene root
- `godot.script_read` - Read a GDScript file
- `godot.editor_get_setting` - Read project setting

## 🚨 Common Issues

### "Server not connecting" after Godot starts
- **Solution**: Restart OpenCode completely (not just the session)
- The MCP connection is established when OpenCode starts

### "Tools not found" 
- **Verify**: Godot is running with the project loaded
- **Verify**: Plugin is enabled in Project Settings → Plugins
- **Check**: Output log in Godot for MCP startup messages

### Port already in use
- Close Godot and OpenCode
- Wait 10 seconds
- Reopen both

## ✅ Verification Checklist

- [ ] Godot 4.8 beta2 is OPEN (not just project loaded)
- [ ] Project `godot-client/project.godot` is loaded in Godot
- [ ] Plugin "Godot MCP Toolkit" is ENABLED in Project Settings
- [ ] MCP dock appears in Godot (shows tool count: 113)
- [ ] OpenCode restarted AFTER Godot was running
- [ ] MCP server "godot" is available in OpenCode

## 📁 Files Created

1. `.mcp.json` - Project-level MCP configuration (matches global config)
2. `MCP_TESTING.md` - This testing guide