"""Draw the courtyard sample on a native 16-pixel grid, then export at 2x.

The *_source.png files are the editable masters. No generated-image input is used.
Use --force only when deliberately replacing edits to those masters.
"""
from __future__ import annotations

import argparse
import random
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
S = 16
P = {
    "ink": "#171D2B", "joint": "#242C3C", "stone_dark": "#293247",
    "stone": "#30394F", "stone_mid": "#39455B", "stone_light": "#47546A",
    "stone_edge": "#65748B", "moss_dark": "#283B39", "moss": "#405A49",
    "moss_light": "#668067", "water_deep": "#27394E", "water": "#344657",
    "water_mid": "#4B6172", "water_glint": "#8BA7B4", "wet_stone": "#405065",
    "shore": "#53657A", "iron": "#33313C",
    "iron_edge": "#766D70", "ember": "#B45B31", "fire": "#E89A49",
    "fire_core": "#FFD779", "banner_dark": "#3E303E",
    "banner": "#624452", "banner_light": "#896069",
}

def tile(height: int = S, fill: str | None = None) -> Image.Image:
    return Image.new("RGBA", (S, height), P[fill] if fill else (0, 0, 0, 0))

def point(q: ImageDraw.ImageDraw, coords: list[tuple[int, int]], color: str) -> None:
    for xy in coords:
        q.point(xy, fill=P[color])

def floor(i: int) -> Image.Image:
    # The common cell is intentionally quiet. A 30x17 room must not repeat a
    # distinct bright squiggle on 84% of the floor cells.
    bases = ["stone", "stone_mid", "stone_dark", "stone", "stone_mid", "stone"]
    im = tile(fill=bases[i]); q = ImageDraw.Draw(im)
    if i == 0:  # plain dressed stone / safe central combat field
        q.line((0,0,15,0), fill=P["joint"])
        q.line((0,1,13,1), fill=P["stone_mid"])
        q.line((0,0,0,15), fill=P["joint"])
        q.line((1,4,1,12), fill=P["stone_mid"])
        q.line((10,12,13,12), fill=P["stone_mid"])
    elif i == 1:  # offset joint, broad uninterrupted face
        q.line((0,0,15,0), fill=P["joint"])
        q.line((0,1,12,1), fill=P["stone_light"])
        q.line((7,0,7,5), fill=P["joint"])
        q.line((8,1,8,4), fill=P["stone_light"])
        q.line((0,15,15,15), fill=P["joint"])
    elif i == 2:  # worn darker block with a single recessed corner
        q.polygon([(0,0),(15,0),(15,12),(12,15),(0,15)], fill=P["stone_dark"])
        q.line((0,0,15,0), fill=P["joint"])
        q.line((0,1,10,1), fill=P["stone_mid"])
        q.line((12,15,15,12), fill=P["ink"])
    elif i == 3:  # cracked face, use sparingly away from actors
        q.line((0,0,15,0), fill=P["joint"])
        q.line((0,1,12,1), fill=P["stone_mid"])
        q.line([(3,4),(6,5),(7,8),(10,9),(10,12)], fill=P["joint"])
        q.line([(7,8),(5,10),(4,12)], fill=P["joint"])
        q.point((6,4), fill=P["stone_light"])
    elif i == 4:  # moonlit slab; low-frequency value patch
        q.rectangle((0,0,15,15), fill=P["stone_mid"])
        q.polygon([(0,0),(13,0),(15,3),(12,8),(0,7)], fill=P["stone_light"])
        q.line((0,0,15,0), fill=P["joint"])
        q.line((0,15,15,15), fill=P["joint"])
        q.line((2,9,8,9), fill=P["stone"])
    else:  # chipped block, restrained weathering
        q.line((0,0,15,0), fill=P["joint"])
        q.line((0,1,11,1), fill=P["stone_mid"])
        q.line((0,0,0,15), fill=P["joint"])
        q.polygon([(12,12),(15,10),(15,15),(10,15)], fill=P["stone_dark"])
        q.line((11,15,15,11), fill=P["stone_light"])
    return im

def slab(i: int) -> Image.Image:
    """A 2x2-cell metatile with larger, less repetitive stone masses."""
    im = Image.new("RGBA",(32,32),P["joint"])
    q = ImageDraw.Draw(im)
    patterns = [
        [([(1,1),(19,1),(21,3),(20,12),(17,13),(1,12)],"stone"),
         ([(23,1),(30,1),(30,15),(21,15),(22,4)],"stone_mid"),
         ([(1,15),(15,15),(17,17),(16,30),(1,30)],"stone_mid"),
         ([(19,17),(30,17),(30,30),(18,30),(18,20)],"stone")],
        [([(1,1),(11,1),(12,13),(10,15),(1,14)],"stone_mid"),
         ([(14,1),(30,1),(30,11),(28,13),(14,13)],"stone"),
         ([(1,17),(9,17),(11,19),(10,30),(1,30)],"stone"),
         ([(13,16),(30,15),(30,30),(12,30),(12,20)],"stone_dark")],
        [([(1,1),(24,1),(25,9),(22,11),(1,11)],"stone"),
         ([(27,1),(30,1),(30,21),(25,21),(24,14),(26,10)],"stone_mid"),
         ([(1,14),(12,14),(14,16),(13,30),(1,30)],"stone_dark"),
         ([(16,14),(22,14),(23,24),(30,24),(30,30),(16,30)],"stone_mid")],
        [([(1,1),(14,1),(15,15),(13,17),(1,16)],"stone_dark"),
         ([(17,1),(30,1),(30,13),(28,15),(17,15)],"stone"),
         ([(1,19),(14,19),(16,22),(14,30),(1,30)],"stone_mid"),
         ([(18,18),(30,17),(30,30),(17,30),(17,22)],"stone")],
    ]
    for n,(poly,tone) in enumerate(patterns[i]):
        q.polygon(poly,fill=P[tone])
        x,y = poly[0]
        q.line((x+2,y+2,min(x+7,30),y+2),fill=P["stone_light" if n%2==0 else "stone_mid"])
        q.line((x+3,min(y+5,29),min(x+6,30),min(y+5,29)),fill=P["stone_mid"])
    # Individually placed chips avoid a procedural noise texture.
    chips = [[(8,8),(9,8),(25,25)],[(6,23),(22,5),(26,26)],
             [(5,5),(19,22),(27,7)],[(8,6),(10,26),(24,24)]][i]
    point(q,chips,"stone_light")
    if i in (1,3): q.line([(22,22),(20,24),(20,27)],fill=P["joint"])
    return im

def slab_atlas() -> Image.Image:
    out = Image.new("RGBA",(128,32),(0,0,0,0))
    for i in range(4): out.alpha_composite(slab(i),(i*32,0))
    return out

def wall(i: int) -> Image.Image:
    im = tile(fill="stone_dark"); q = ImageDraw.Draw(im)
    top, bottom, left, right = i < 4, 4 <= i < 8, 8 <= i < 10, i >= 10
    if top or bottom:
        if top:
            q.rectangle((0,0,15,4), fill=P["stone_light"])
            q.line((0,0,15,0), fill=P["stone_edge"])
            q.line((0,5,15,5), fill=P["ink"])
            q.line((0,13,15,13), fill=P["ink"])
            q.line((0,14,15,14), fill=P["joint"])
            q.line((2,2,5,2), fill=P["stone_edge"])
            q.line((9,3,12,3), fill=P["stone_mid"])
            q.line((2,9,4,9), fill=P["stone_mid"])
        else:
            q.line((0,3,15,3), fill=P["ink"])
            q.rectangle((0,4,15,11), fill=P["stone_mid"])
            q.line((0,12,15,12), fill=P["stone_edge"])
            q.rectangle((0,13,15,15), fill=P["stone_light"])
            q.line((2,6,5,6), fill=P["stone_edge"])
            q.line((10,9,13,9), fill=P["stone_dark"])
        x = 5 if i % 2 == 0 else 10
        q.line((x,6,x,11), fill=P["joint"])
        q.line((x+2,8,min(x+5,15),8), fill=P["stone_light"])
        if i in (2,6):
            q.rectangle((0,0,3,15), fill=P["stone_light"])
            q.line((3,1,3,14), fill=P["ink"])
            q.point((1,3), fill=P["stone_edge"])
        if i in (3,7):
            q.rectangle((12,0,15,15), fill=P["stone_light"])
            q.line((12,1,12,14), fill=P["ink"])
            q.point((14,3), fill=P["stone_edge"])
    if left or right:
        if left:
            q.rectangle((0,0,4,15), fill=P["stone_light"])
            q.line((0,0,0,15), fill=P["stone_edge"])
            q.line((12,0,12,15), fill=P["ink"])
            q.line((13,0,13,15), fill=P["joint"])
            q.line((2,2,2,5), fill=P["stone_edge"])
        else:
            q.rectangle((11,0,15,15), fill=P["stone_light"])
            q.line((15,0,15,15), fill=P["stone_edge"])
            q.line((3,0,3,15), fill=P["ink"])
            q.line((2,0,2,15), fill=P["joint"])
            q.line((13,8,13,11), fill=P["stone_edge"])
        y = 5 if i % 2 == 0 else 10
        q.line((5,y,10,y), fill=P["joint"])
        q.line((6,y+2,9,y+2), fill=P["stone_mid"])
    return im

def decor(i: int) -> Image.Image:
    """Sparse transparent overlays; authored for perimeter placement."""
    im = tile(); q = ImageDraw.Draw(im)
    if i == 0:  # thin split
        q.line([(2,1),(4,3),(4,6),(7,8),(7,11),(10,13)], fill=P["joint"])
        point(q,[(3,2),(6,7),(8,10)],"stone_light")
    elif i == 1:  # branch crack
        q.line([(11,1),(9,4),(10,7),(6,9),(5,14)], fill=P["joint"])
        q.line([(10,7),(13,9),(14,11)], fill=P["joint"])
        point(q,[(10,3),(7,10),(13,8)],"stone_light")
    elif i in (2,3):  # moss seam, oriented in two corners
        coords = ([(0,0),(5,0),(7,2),(5,4),(2,4),(0,6)] if i == 2 else
                  [(15,15),(9,15),(8,13),(10,11),(13,12),(15,9)])
        q.polygon(coords, fill=P["moss_dark"])
        lights = ([(1,1),(3,2),(5,1),(2,4)] if i == 2 else
                  [(14,13),(12,14),(10,13),(14,10)])
        point(q,lights,"moss")
        point(q,[lights[0]],"moss_light")
    elif i == 4:  # paired chips
        q.polygon([(2,11),(3,9),(5,9),(7,11),(6,13),(3,13)], fill=P["stone_dark"])
        q.line((3,10,5,10), fill=P["stone_edge"])
        q.polygon([(10,3),(12,2),(14,4),(13,6),(11,6)], fill=P["stone_mid"])
        q.point((12,3), fill=P["stone_edge"])
    elif i == 5:  # partly broken pale seam
        q.line([(0,12),(4,12),(5,11),(8,11),(9,9)], fill=P["stone_edge"])
        q.line([(2,13),(6,13),(7,12)], fill=P["joint"])
    elif i == 6:  # gritty edge cluster
        point(q,[(2,1),(3,2),(5,1),(7,3),(2,5),(4,6),(8,6),(10,2)],"stone_dark")
        point(q,[(3,1),(6,3),(5,5)],"stone_light")
    elif i == 7:  # a few roots invading the paving seam
        q.line([(0,8),(3,8),(5,10),(8,10),(10,13)], fill=P["moss_dark"])
        q.line([(4,9),(5,6),(8,6)], fill=P["moss"])
        point(q,[(2,7),(8,5),(9,12)],"moss_light")
    elif i == 8:  # rough shingle, best under north wall
        for box in [(0,11,3,14),(4,13,8,15),(10,10,15,15)]:
            q.rectangle(box, fill=P["stone_dark"])
            q.line((box[0],box[1],box[2]-1,box[1]), fill=P["stone_light"])
        point(q,[(2,9),(8,11),(13,8)],"stone_mid")
    elif i == 9:  # broken paver and pale scree
        q.polygon([(1,14),(2,10),(6,8),(9,10),(8,14)], fill=P["stone_dark"])
        q.line([(2,10),(6,8),(8,9)], fill=P["stone_edge"])
        point(q,[(11,14),(13,12),(14,15)],"stone_mid")
    elif i == 10:  # ivy from west perimeter
        q.polygon([(0,1),(4,0),(6,3),(5,8),(3,10),(0,12)], fill=P["moss_dark"])
        for x,y in [(1,1),(3,3),(5,4),(2,7),(4,9),(1,11)]:
            q.rectangle((x,y,x+2,y+1), fill=P["moss"])
        point(q,[(2,2),(4,4),(1,8)],"moss_light")
    elif i == 11:  # ivy from east perimeter
        q.polygon([(15,2),(11,0),(9,3),(10,8),(13,11),(15,13)], fill=P["moss_dark"])
        for x,y in [(12,1),(10,4),(13,5),(11,8),(13,10),(14,12)]:
            q.rectangle((x,y,x+2,y+1), fill=P["moss"])
        point(q,[(13,2),(11,5),(14,10)],"moss_light")
    elif i == 12:  # wet chips / partial shoreline, non-colliding
        q.polygon([(0,12),(4,10),(6,11),(9,9),(12,10),(15,8),(15,15),(0,15)], fill=P["water_deep"])
        q.line([(0,11),(4,9),(6,10),(9,8),(12,9),(15,7)], fill=P["shore"])
        point(q,[(3,8),(6,7),(12,6)],"stone_light")
    elif i == 13:  # small puddle beads bridge pool to floor
        for x,y in [(1,8),(5,5),(8,10),(12,3)]:
            q.line((x,y,x+2,y), fill=P["water_mid"])
            q.point((x+1,y-1), fill=P["water_glint"])
    elif i == 14:  # cracked pale slab, perimeter only
        q.line([(1,3),(5,5),(7,8),(11,9),(14,13)],fill=P["joint"])
        q.line([(7,8),(6,11),(3,13)],fill=P["joint"])
        q.line((2,3,4,4),fill=P["stone_edge"])
        point(q,[(12,8),(14,10)],"stone_mid")
    elif i == 15:  # low ivy and grit at wall foot
        q.polygon([(0,14),(0,10),(3,8),(5,9),(8,12),(10,10),(15,13),(15,15)], fill=P["moss_dark"])
        for x,y in [(1,10),(3,9),(6,11),(9,12),(12,11)]: q.line((x,y,x+2,y),fill=P["moss"])
        point(q,[(1,8),(8,10),(13,9)],"stone_mid")
    return im

def water(i: int) -> Image.Image:
    """Walkable water over visible paving, not a flat blue hole."""
    im = tile(); q = ImageDraw.Draw(im)
    if i >= 9:
        # Four optional edge fingers extend the exact water/mask geometry past
        # the initial 3x3 patch, so the reflected area remains truthful.
        for y in range(S):
            for x in range(S):
                if i == 9:  # north finger: touches southern edge
                    wet = 5 <= x <= 11 and y >= 7-((x+1)%3)
                elif i == 10:  # west finger: touches eastern edge
                    wet = x >= 6-((y+1)%3) and 4 <= y <= 12
                elif i == 11:  # east finger: touches western edge
                    wet = x <= 9+((y+2)%3) and 3 <= y <= 11
                else:  # south finger: touches northern edge
                    wet = 4 <= x <= 12 and y <= 9+((x+2)%3)
                if wet:
                    face = "wet_stone" if (x//4+y//5+i)%3 else "water"
                    q.point((x,y),fill=P[face])
        for x0,x1,y in ((4,7,5),(9,12,10)):
            for x in range(x0,x1+1):
                if im.getpixel((x,y))[3] and (x+i)%2:
                    q.point((x,y),fill=P["water_glint"])
        return im
    left_cut = [7,6,5,4,4,3,3,4,3,3,4,4,5,6,6,7]
    right_cut = [8,9,10,11,11,12,12,11,12,12,11,11,10,9,9,8]
    top_cut = [7,6,5,5,4,4,3,3,4,4,5,5,5,6,7,7]
    bottom_cut = [8,9,10,10,11,11,12,12,11,11,10,10,10,9,8,8]
    for y in range(S):
        for x in range(S):
            lo_x, hi_x = left_cut[y], right_cut[y]
            lo_y, hi_y = top_cut[x], bottom_cut[x]
            finger_contact = (i == 1 and 5 <= x <= 11 and y <= lo_y or
                              i == 2 and 4 <= x <= 12 and y >= hi_y or
                              i == 3 and 4 <= y <= 12 and x <= lo_x or
                              i == 4 and 3 <= y <= 11 and x >= hi_x)
            wet = (finger_contact or i == 0 or
                   i == 1 and y >= lo_y or i == 2 and y <= hi_y or
                   i == 3 and x >= lo_x or i == 4 and x <= hi_x or
                   i == 5 and x >= lo_x and y >= lo_y or
                   i == 6 and x <= hi_x and y >= lo_y or
                   i == 7 and x >= lo_x and y <= hi_y or
                   i == 8 and x <= hi_x and y <= hi_y)
            if wet:
                edge = ((i in (1,5,6) and y == lo_y) or
                        (i in (2,7,8) and y == hi_y) or
                        (i in (3,5,7) and x == lo_x) or
                        (i in (4,6,8) and x == hi_x))
                face = "wet_stone" if (x//5+y//6+i)%4 != 0 else "water"
                q.point((x,y), fill=P["shore" if edge and (x+y)%3 == 0 else face])
    # Submerged mortar reads as paving below a thin film of water.
    for x in (3, 11):
        for y in range(2,15):
            if im.getpixel((x,y))[3]: q.point((x,y),fill=P["water_deep"])
    for y in (5, 13):
        for x in range(2,15):
            if im.getpixel((x,y))[3]: q.point((x,y),fill=P["water_deep"])
    # Broken highlights; no baked character silhouette.
    for x0,x1,y in ((2,5,3),(9,12,9),(5,7,12)):
        for x in range(x0,x1+1):
            if im.getpixel((x,y))[3] and (x+y+i)%3 != 0:
                q.point((x,y), fill=P["water_glint"])
    return im

def reflection_mask(w: Image.Image) -> Image.Image:
    im = Image.new("RGBA",w.size,(255,255,255,0))
    im.putalpha(w.getchannel("A"))
    return im

def ripple(i: int) -> Image.Image:
    im = tile(); q = ImageDraw.Draw(im)
    # Four manually placed, discrete frames for a light footfall ring.
    shapes = [
        [(7,7,8,7),(6,8,6,8),(9,8,9,8)],
        [(5,7,6,7),(9,7,10,7),(4,9,5,9),(10,9,11,9)],
        [(3,6,5,6),(10,6,12,6),(2,10,4,10),(11,10,13,10)],
        [(1,5,3,5),(12,5,14,5),(0,11,2,11),(13,11,15,11)],
    ]
    for line in shapes[i]: q.line(line, fill=P["water_glint"])
    return im

def prop(i: int) -> Image.Image:
    """16x32 edge props, two visual variations per type."""
    im = tile(32); q = ImageDraw.Draw(im)
    kind, variant = i//2, i%2
    if kind == 0:  # brazier; bottom center is the placement point
        q.polygon([(5,31),(10,31),(9,24),(6,24)], fill=P["stone_dark"])
        q.line((6,30,9,30), fill=P["stone_edge"])
        q.polygon([(2,20),(4,17),(11,17),(13,20),(11,23),(4,23)], fill=P["iron"])
        q.line((3,19,12,19), fill=P["iron_edge"])
        q.line((4,21,11,21), fill=P["iron_edge"])
        q.line((4,22,11,22), fill=P["ink"])
        # The lit flame and its hot cup are rendered from the dedicated
        # frame atlas. No baked static flame should survive underneath it.
    elif kind == 1:  # sparse wall-root plant, deliberately not a blocker
        q.line((5,31,5,22), fill=P["moss_dark"])
        q.line((9,31,9,19), fill=P["moss_dark"])
        q.line((12,31,12,25), fill=P["moss_dark"])
        leaves = [(2,25),(4,23),(6,24),(7,28),(8,20),(10,21),(12,24),(13,27)]
        for x,y in leaves:
            q.rectangle((x,y+variant,x+2,y+variant+1), fill=P["moss"])
        point(q, [(3,25),(9,20+variant),(13,25)], "moss_light")
        q.line((2,31,14,31), fill=P["moss_dark"])
    elif kind == 2:  # small floor rubble, no collision promise
        stones = [(1,27,5,31),(6,25,10,30),(11,28,15,31)]
        for n, box in enumerate(stones):
            if variant and n == 0: box = (2,28,6,31)
            q.polygon([(box[0],box[3]),(box[0],box[1]+1),(box[0]+2,box[1]),
                       (box[2]-1,box[1]),(box[2],box[1]+2),(box[2],box[3])], fill=P["stone_mid"])
            q.line((box[0]+1,box[1]+1,box[2]-1,box[1]+1), fill=P["stone_edge"])
            q.line((box[0],box[3],box[2],box[3]), fill=P["ink"])
    elif kind == 3:  # wall-hung torn banner; top center anchors to wall
        q.line((1,1,14,1), fill=P["iron_edge"])
        q.point((1,2), fill=P["ink"]); q.point((14,2), fill=P["ink"])
        q.polygon([(4,3),(12,3),(12,26+variant),(10,24),(8,29),(6,25),(4,27)], fill=P["banner_dark"])
        q.polygon([(5,4),(11,4),(11,22),(9,23),(8,26),(6,22),(5,24)], fill=P["banner"])
        q.line((6,5,6,20), fill=P["banner_light"])
        q.polygon([(8,9),(10,11),(8,13),(6,11)], fill=P["banner_light"])
        q.point((8,11), fill=P["stone_edge"])
    elif kind == 4:  # raised wall pier: cap, illuminated edge, shaded face
        q.rectangle((1,2,14,8), fill=P["stone_light"])
        q.line((1,2,14,2), fill=P["stone_edge"])
        q.line((2,8,13,8), fill=P["ink"])
        q.rectangle((3,9,12,27), fill=P["stone_dark"])
        q.line((4,10,4,26), fill=P["stone_mid"])
        q.line((11,11,11,26), fill=P["joint"])
        q.rectangle((1,28,14,31), fill=P["stone_mid"])
        q.line((2,28,13,28), fill=P["stone_edge"])
        if variant:
            q.line((7,15,8,17), fill=P["joint"])
            q.point((10,5), fill=P["stone_dark"])
    elif kind == 5:  # ivy hanging over wall, no gameplay occlusion
        q.line((5,1,5,24+variant), fill=P["moss_dark"])
        q.line((10,0,10,20+variant), fill=P["moss_dark"])
        q.line((6,10,10,14), fill=P["moss_dark"])
        for x,y in [(3,2),(6,4),(7,8),(4,12),(8,15),(9,5),(11,9),(10,19)]:
            q.rectangle((x,y+variant,x+2,y+variant+1), fill=P["moss"])
        point(q,[(4,3+variant),(9,15+variant),(11,10+variant)],"moss_light")
    elif kind == 6:  # collapsed masonry, placed at the perimeter only
        q.polygon([(0,31),(1,24),(5,22),(8,25),(11,23),(15,28),(15,31)], fill=P["ink"])
        q.polygon([(1,27),(4,23),(8,24),(10,30),(1,30)], fill=P["stone_mid"])
        q.polygon([(9,25),(12,22+variant),(15,25),(15,30),(10,30)], fill=P["stone_dark"])
        q.line([(2,26),(4,24),(7,25)],fill=P["stone_edge"])
        q.line((11,24+variant,13,24+variant),fill=P["stone_light"])
    elif kind == 7:  # wall-root / leaf mass, no collision promise
        q.line([(4,31),(5,23),(9,19),(11,11)],fill=P["moss_dark"])
        q.line([(6,23),(2,16),(2,10)],fill=P["moss_dark"])
        q.line([(8,21),(13,18),(14,14)],fill=P["moss_dark"])
        for x,y in [(1,10),(4,13),(2,18),(7,18),(10,13),(12,18),(8,22),(3,25)]:
            q.rectangle((x,y+variant,x+2,y+variant+2),fill=P["moss"])
        point(q,[(2,11),(10,14),(5,25)],"moss_light")
    elif kind == 8:  # cracked half-height stone marker, deliberately neutral
        q.polygon([(4,31),(4,20),(6,17),(11,17),(12,29),(13,31)],fill=P["ink"])
        q.polygon([(5,29),(5,20),(7,18),(10,18),(11,29)],fill=P["stone_mid"])
        q.line((6,19,9,19),fill=P["stone_edge"])
        q.line([(9,22),(8,24),(10,26+variant)],fill=P["joint"])
        q.line((2,31,14,31),fill=P["stone_dark"])
    else:  # hanging foliage over wall, avoid the playable center
        for x,y in [(2,1),(5,0),(9,1),(13,0)]:
            q.line((x,y,x,21+variant+(x%4)),fill=P["moss_dark"])
        for x,y in [(1,5),(3,9),(4,15),(7,6),(8,12),(10,20),(12,8),(13,16)]:
            q.rectangle((x,y,x+2,y+2),fill=P["moss"])
        point(q,[(2,6),(8,7),(13,9)],"moss_light")
    return im

def light_pool(kind: str) -> Image.Image:
    """Optional multiply-safe visual wash; semi-alpha is intentional here."""
    size = (128,96)
    im = Image.new("RGBA",size,(0,0,0,0))
    pix = im.load()
    rgb = (154,188,226) if kind == "moon" else (248,152,83)
    for y in range(size[1]):
        for x in range(size[0]):
            dx = (x-63.5)/63.5
            dy = (y-47.5)/47.5
            dist = (dx*dx+dy*dy)**0.5
            envelope = max(0.0,1.0-dist)
            # Quantised alpha rings preserve the pixel-scale while staying
            # softer than an opaque painted disk.
            alpha = round((envelope**1.65)*(48 if kind == "moon" else 36)/4)*4
            if alpha > 0:
                pix[x,y] = (*rgb,alpha)
    return im

def atlas(images: list[Image.Image], cols: int, height: int = S) -> Image.Image:
    rows = (len(images)+cols-1)//cols
    out = Image.new("RGBA", (S*cols,height*rows), (0,0,0,0))
    for i, im in enumerate(images):
        assert im.size == (S,height)
        out.alpha_composite(im, ((i%cols)*S,(i//cols)*height))
    return out

def save_pair(name: str, source: Image.Image, force: bool) -> None:
    a, b = ROOT/f"{name}_source.png", ROOT/f"{name}.png"
    if not force and (a.exists() or b.exists()):
        raise FileExistsError(f"Refusing to overwrite edited art: {name}; use --force")
    source.save(a)
    source.resize((source.width*2,source.height*2), Image.Resampling.NEAREST).save(b)

def save_layout_preview(force: bool) -> None:
    """Static layout QA only, never a game background or a collision source."""
    path = ROOT/"courtyard_layout_preview.png"
    if path.exists() and not force:
        raise FileExistsError(f"Refusing to overwrite layout preview: {path}")
    canvas = Image.new("RGBA",(30*S,17*S),P["ink"])
    floors, slabs, walls, decors, waters, props = (
        [floor(i) for i in range(6)], [slab(i) for i in range(4)], [wall(i) for i in range(12)],
        [decor(i) for i in range(16)], [water(i) for i in range(13)],
        [prop(i) for i in range(20)])
    layout = random.Random(20260926)
    for y in range(17):
        for x in range(30):
            roll = layout.random()
            variant = 0 if roll < 0.44 else (1 if roll < 0.67 else (2 if roll < 0.79 else (3 if roll < 0.88 else (4 if roll < 0.95 else 5))))
            canvas.alpha_composite(floors[variant],(x*S,y*S))
    for y in range(1,8):
        for x in range(1,14):
            if layout.random() < 0.27:
                canvas.alpha_composite(slabs[layout.choice([0,0,1,2,3])],(x*32,y*32))
    for y in range(17):
        for x in range(30):
            if y == 0: edge = 2 if x == 0 else 3 if x == 29 else x%2
            elif y == 16: edge = 6 if x == 0 else 7 if x == 29 else 4+x%2
            elif x == 0: edge = 8+y%2
            elif x == 29: edge = 10+y%2
            else: edge = None
            if edge is not None: canvas.alpha_composite(walls[edge],(x*S,y*S))
    for x,y,n in [(2,1,8),(3,2,10),(5,2,9),(8,1,15),(13,2,14),
                  (22,1,9),(25,2,11),(27,4,8),(1,7,10),(28,9,11),
                  (2,11,3),(4,14,8),(8,15,9),(13,14,15),(20,15,14),
                  (23,14,1),(27,13,3),(1,13,8),(5,7,12),(8,4,13)]:
        canvas.alpha_composite(decors[n],(x*S,y*S))
    shape = [[5,1,6],[3,0,4],[7,2,8]]
    for dy,row in enumerate(shape):
        for dx,n in enumerate(row):
            canvas.alpha_composite(waters[n],((3+dx)*S,(3+dy)*S))
    for x,y,n in [(4,2,9),(2,4,10),(6,4,11),(5,6,12)]:
        canvas.alpha_composite(waters[n],(x*S,y*S))
    for x,y,n in [(2,1,0),(27,1,1),(2,15,0),(27,15,1),
                  (1,9,2),(28,10,3),(6,15,4),(24,15,5),(15,0,6),
                  (7,0,8),(22,0,9),(4,0,10),(26,0,11),
                  (3,1,12),(25,1,13),(3,14,14),(26,14,15),
                  (11,0,16),(18,0,17),(6,0,18),(23,0,19)]:
        canvas.alpha_composite(props[n],(x*S,y*S if n >= 6 else y*S-16))
    canvas.alpha_composite(light_pool("moon"),(38,35))
    canvas.resize((960,544),Image.Resampling.NEAREST).crop((0,2,960,542)).save(path)

def main() -> None:
    parser = argparse.ArgumentParser(); parser.add_argument("--force", action="store_true")
    parser.add_argument("--props-only", action="store_true", help="Rebuild just the updated static brazier/prop atlas")
    args = parser.parse_args()
    if args.props_only:
        save_pair("courtyard_props", atlas([prop(i) for i in range(20)],4,32), args.force)
        return
    save_pair("courtyard_floor", atlas([floor(i) for i in range(6)],3), args.force)
    save_pair("courtyard_slab", slab_atlas(), args.force)
    save_pair("courtyard_wall", atlas([wall(i) for i in range(12)],4), args.force)
    save_pair("courtyard_decor", atlas([decor(i) for i in range(16)],4), args.force)
    waters = [water(i) for i in range(13)]
    save_pair("courtyard_water", atlas(waters,3), args.force)
    save_pair("courtyard_reflection_mask", atlas([reflection_mask(w) for w in waters],3), args.force)
    save_pair("courtyard_ripple", atlas([ripple(i) for i in range(4)],4), args.force)
    save_pair("courtyard_props", atlas([prop(i) for i in range(20)],4,32), args.force)
    save_pair("courtyard_moon_pool", light_pool("moon"), args.force)
    save_pair("courtyard_fire_pool", light_pool("fire"), args.force)
    save_layout_preview(args.force)

if __name__ == "__main__": main()
