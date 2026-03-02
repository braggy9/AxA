#!/usr/bin/env python3
"""
generate_placeholders.py
Generates 16x16 placeholder PNG sprites for AxA.
Run from the project root: python3 tools/generate_placeholders.py

These are intentionally simple coloured shapes — Zig will replace the
character sprites with his own drawings later.
"""

import struct
import zlib
import os
from pathlib import Path

# ---------------------------------------------------------------------------
# Minimal PNG writer (no dependencies required)
# ---------------------------------------------------------------------------

def write_png(path: str, pixels: list[list[tuple[int,int,int,int]]], width: int, height: int):
    """Write a list-of-rows RGBA pixel array as a PNG file."""
    def chunk(name: bytes, data: bytes) -> bytes:
        c = name + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

    raw = b''
    for row in pixels:
        raw += b'\x00'  # filter type none
        for r, g, b, a in row:
            raw += bytes([r, g, b, a])

    png  = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
                 .replace(struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)[8:], b'')  # noop
                 )
    # Redo IHDR correctly
    ihdr_data = struct.pack('>II', width, height) + bytes([8, 6, 0, 0, 0])  # 8-bit RGBA
    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', ihdr_data)
    png += chunk(b'IDAT', zlib.compress(raw))
    png += chunk(b'IEND', b'')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(png)

def make_pixels(width: int, height: int, fill=(0,0,0,255)):
    return [[fill]*width for _ in range(height)]

def set_rect(pixels, x, y, w, h, colour):
    for row in range(y, min(y+h, len(pixels))):
        for col in range(x, min(x+w, len(pixels[0]))):
            pixels[row][col] = colour

def set_pixel(pixels, x, y, colour):
    if 0 <= y < len(pixels) and 0 <= x < len(pixels[0]):
        pixels[y][x] = colour

def set_circle(pixels, cx, cy, r, colour):
    for y in range(len(pixels)):
        for x in range(len(pixels[0])):
            if (x-cx)**2 + (y-cy)**2 <= r**2:
                pixels[y][x] = colour

# Colours (RGBA)
PINK_SALT    = (240, 184, 178, 255)
PINK_SAND    = (252, 224, 204, 255)
WATER_BLUE   = (89, 183, 242, 255)
WATER_DEEP   = (51, 127, 204, 255)
CRYSTAL      = (255, 229, 242, 255)
CRYSTAL_EDGE = (255, 153, 178, 255)
TREE_TRUNK   = (115,  71,  30, 255)
TREE_LEAF    = (51,  165,  63, 255)
TREE_LIGHT   = (102, 217, 115, 255)
WIZ_BODY     = (153,  89, 204, 255)
WIZ_HAT      = (76,   38, 140, 255)
WIZ_STAFF    = (204, 165,  76, 255)
WHITE        = (255, 255, 255, 255)
BLACK        = (0,   0,   0,   255)
TRANSPARENT  = (0,   0,   0,     0)
UI_BASE      = (255, 255, 255,  64)
UI_KNOB      = (255, 255, 255, 140)
BUTTON_RED   = (242,  76,  76, 192)

# ---------------------------------------------------------------------------
# Tile sprites (16x16)
# ---------------------------------------------------------------------------

def tile_salt_ground():
    p = make_pixels(16, 16, PINK_SALT)
    # Subtle noise
    for pos in [(3,4),(7,11),(13,2),(2,13),(10,7)]:
        set_pixel(p, pos[0], pos[1], (217, 153, 148, 255))
    return p

def tile_salt_sand():
    p = make_pixels(16, 16, PINK_SAND)
    for pos in [(4,3),(9,12),(14,6),(1,10)]:
        set_pixel(p, pos[0], pos[1], (240, 204, 178, 255))
    return p

def tile_water():
    p = make_pixels(16, 16, WATER_BLUE)
    # Wave line
    for x, y in [(2,7),(3,6),(4,6),(5,7),(6,7),(7,6),(8,6),(9,7),(10,7),(11,6),(12,6),(13,7)]:
        set_pixel(p, x, y, (178, 222, 255, 255))
    return p

def tile_water_deep():
    p = make_pixels(16, 16, WATER_DEEP)
    for x, y in [(3,8),(4,7),(5,7),(6,8),(7,8),(8,7),(9,7),(10,8)]:
        set_pixel(p, x, y, (89, 165, 229, 255))
    return p

def tile_crystal():
    p = make_pixels(16, 16, PINK_SALT)
    # Diamond crystal shape
    pts = [(8,1),(7,3),(6,5),(5,7),(6,9),(7,11),(8,13),(9,11),(10,9),(11,7),(10,5),(9,3)]
    for x, y in pts:
        set_pixel(p, x, y, CRYSTAL_EDGE)
        set_pixel(p, x, y-1, CRYSTAL)
    # Fill centre
    for y in range(4, 12):
        for x in range(6, 11):
            if abs(x-8) + abs(y-7) < 5:
                p[y][x] = CRYSTAL
    return p

def tile_nono_tree():
    p = make_pixels(16, 16, PINK_SALT)
    # Trunk
    set_rect(p, 6, 9, 4, 7, TREE_TRUNK)
    # Canopy (circle)
    set_circle(p, 8, 7, 6, TREE_LEAF)
    # Highlight
    set_circle(p, 6, 5, 2, TREE_LIGHT)
    return p

# ---------------------------------------------------------------------------
# Character sprites (16x16)
# ---------------------------------------------------------------------------

def char_wiz_idle_down():
    p = make_pixels(16, 16, TRANSPARENT)
    # Body — purple oval
    set_circle(p, 8, 10, 5, WIZ_BODY)
    # Gills (pink side spikes)
    for y in range(8, 13):
        set_pixel(p, 3, y, (255, 153, 204, 255))
        set_pixel(p, 13, y, (255, 153, 204, 255))
    # Hat
    hat_pts = [(8,1),(7,2),(8,2),(9,2),(6,3),(7,3),(8,3),(9,3),(10,3),(5,4),(6,4),(7,4),(8,4),(9,4),(10,4),(11,4)]
    for x, y in hat_pts:
        set_pixel(p, x, y, WIZ_HAT)
    # Hat brim
    for x in range(4, 13):
        set_pixel(p, x, 5, WIZ_HAT)
    # Eyes (white dots)
    set_pixel(p, 6, 9, WHITE)
    set_pixel(p, 10, 9, WHITE)
    set_pixel(p, 6, 10, BLACK)  # pupils
    set_pixel(p, 10, 10, BLACK)
    # Staff (tail carries it — bottom right)
    for i, (x, y) in enumerate([(13,13),(14,12),(15,11),(15,10)]):
        set_pixel(p, x, y, WIZ_STAFF)
    set_pixel(p, 15, 9, (255, 215, 0, 255))  # staff tip glow
    return p

def char_wiz_walk_down_0():
    p = char_wiz_idle_down()
    # Shift body slightly left — walking frame 0
    # Just move the gills for a simple bob
    set_pixel(p, 3, 12, TRANSPARENT)
    set_pixel(p, 13, 12, TRANSPARENT)
    return p

def char_wiz_walk_down_1():
    p = char_wiz_idle_down()
    # Walking frame 1 — shift gills slightly
    set_pixel(p, 3, 8, TRANSPARENT)
    set_pixel(p, 13, 8, TRANSPARENT)
    set_pixel(p, 2, 9, (255, 153, 204, 255))
    set_pixel(p, 14, 9, (255, 153, 204, 255))
    return p

# ---------------------------------------------------------------------------
# UI sprites (larger: 44x44 for joystick base, 22x22 for knob)
# ---------------------------------------------------------------------------

def ui_joystick_base():
    size = 88  # 2x for @2x
    p = make_pixels(size, size, TRANSPARENT)
    set_circle(p, size//2, size//2, size//2 - 2, UI_BASE)
    # Ring
    for y in range(size):
        for x in range(size):
            d = ((x - size//2)**2 + (y - size//2)**2)**0.5
            if size//2 - 3 <= d <= size//2 - 1:
                p[y][x] = (255, 255, 255, 76)
    return p, size, size

def ui_joystick_knob():
    size = 44
    p = make_pixels(size, size, TRANSPARENT)
    set_circle(p, size//2, size//2, size//2 - 1, UI_KNOB)
    # Highlight
    set_circle(p, size//2 - 4, size//2 - 4, 6, (255,255,255,100))
    return p, size, size

def ui_button_attack():
    size = 112  # 56pt @2x
    p = make_pixels(size, size, TRANSPARENT)
    set_circle(p, size//2, size//2, size//2 - 2, BUTTON_RED)
    # Ring
    for y in range(size):
        for x in range(size):
            d = ((x - size//2)**2 + (y - size//2)**2)**0.5
            if size//2 - 3 <= d <= size//2 - 1:
                p[y][x] = (255,255,255,100)
    # "A" letter in white (simple pixel letter)
    letter_a = [
        "  XXX  ", "  X X  ", " XXXXX ", " X   X ", "X     X"
    ]
    ox, oy = size//2 - 14, size//2 - 10
    for row, line in enumerate(letter_a):
        for col, ch in enumerate(line):
            if ch == 'X':
                for dy in range(4):
                    for dx in range(4):
                        set_pixel(p, ox + col*4 + dx, oy + row*4 + dy, WHITE)
    return p, size, size

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    root = Path(__file__).parent.parent / "assets"

    sprites = {
        # Tiles
        "Tiles/SaltWorldLake/tile_salt_ground.png":    (tile_salt_ground(),   16, 16),
        "Tiles/SaltWorldLake/tile_salt_sand.png":      (tile_salt_sand(),     16, 16),
        "Tiles/SaltWorldLake/tile_water.png":          (tile_water(),         16, 16),
        "Tiles/SaltWorldLake/tile_water_deep.png":     (tile_water_deep(),    16, 16),
        "Tiles/SaltWorldLake/tile_crystal.png":        (tile_crystal(),       16, 16),
        "Tiles/SaltWorldLake/tile_nono_tree.png":      (tile_nono_tree(),     16, 16),
        # Characters — Wiz
        "Characters/Wiz/char_wiz_idle_down_0.png":     (char_wiz_idle_down(),     16, 16),
        "Characters/Wiz/char_wiz_walk_down_0.png":     (char_wiz_walk_down_0(),   16, 16),
        "Characters/Wiz/char_wiz_walk_down_1.png":     (char_wiz_walk_down_1(),   16, 16),
    }

    ui_sprites = {
        "UI/ui_joystick_base.png": ui_joystick_base(),
        "UI/ui_joystick_knob.png": ui_joystick_knob(),
        "UI/ui_button_attack.png": ui_button_attack(),
    }

    for rel_path, (pixels, w, h) in sprites.items():
        full = str(root / rel_path)
        write_png(full, pixels, w, h)
        print(f"  ✓ {rel_path}")

    for rel_path, (pixels, w, h) in ui_sprites.items():
        full = str(root / rel_path)
        write_png(full, pixels, w, h)
        print(f"  ✓ {rel_path}")

    print(f"\nAll placeholder assets written to {root}/")

if __name__ == "__main__":
    main()
