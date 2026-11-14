from PIL import Image, ImageDraw
from pathlib import Path

# Dofus colors (approximated for Incarnam)
COLORS = {
    0: (120, 180, 80),   # Grass
    1: (60, 120, 200),   # Water
    2: (100, 100, 100),  # Wall
    3: (255, 0, 255),    # Doubt (pink)
    4: (140, 140, 150),  # Metallic
    5: (160, 160, 160),  # Stone
    6: (240, 220, 160),  # Sand
    7: (140, 100, 80),   # Dirt
}

TILE_W = 64
TILE_H = 32

def generate_tiles(out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    for tid, color in COLORS.items():
        # Alpha=0 background
        img = Image.new("RGBA", (TILE_W, TILE_H), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        
        # Isometric diamond shape
        pts = [
            (TILE_W // 2, 0),
            (TILE_W, TILE_H // 2),
            (TILE_W // 2, TILE_H),
            (0, TILE_H // 2)
        ]
        
        # Fill diamond
        draw.polygon(pts, fill=color)
        
        # Border
        border_color = tuple(max(0, c - 40) for c in color)
        draw.line(pts + [pts[0]], fill=border_color, width=1)
        
        img.save(out_dir / f"tile_{tid}.png")
    
    print(f"Generated {len(COLORS)} tiles in {out_dir}")

if __name__ == "__main__":
    import sys
    generate_tiles(sys.argv[1] if len(sys.argv) > 1 else "tiles")
