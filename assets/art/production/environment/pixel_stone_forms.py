"""Original 3x3-cell native pixel drawing recipes for the courtyard.

Every polygon and pixel block is deliberately placed on a 48x48 native grid.
At 2x nearest export, each 16x16 source quadrant is one 32-world-pixel tile.
No image input, resizing down, filter, noise, or random placement is involved.
"""
from PIL import Image, ImageDraw

P = {
    "void": "#172332", "joint": "#202D3C", "under": "#293A4C",
    "shade": "#304254", "stone": "#384B5E", "mid": "#405468",
    "lit": "#52677A", "edge": "#687C8A", "chip": "#7B8C96",
    "moss0": "#263C3D", "moss1": "#3A5A51", "moss2": "#607A63",
    "wet0": "#263C4B", "wet1": "#355361", "wet2": "#4C6C76",
}


def img(fill="joint"):
    im = Image.new("RGBA", (48, 48), P[fill])
    return im, ImageDraw.Draw(im)


def p(d, coordinates, tone):
    d.polygon(coordinates, fill=P[tone])


def l(d, coordinates, tone, width=1):
    d.line(coordinates, fill=P[tone], width=width)


def r(d, box, tone):
    d.rectangle(box, fill=P[tone])


def floor_a():
    im, d = img()
    # Seven unequal stone masses; none follows the 16px tile lattice.
    p(d, [(0,0),(22,0),(24,3),(23,11),(19,14),(0,13)], "stone")
    p(d, [(26,0),(47,0),(47,11),(44,13),(31,12),(27,10),(25,6)], "shade")
    p(d, [(0,16),(17,16),(19,18),(17,31),(12,34),(0,32)], "under")
    p(d, [(22,16),(44,15),(47,18),(47,28),(36,29),(31,26),(20,27)], "stone")
    p(d, [(0,36),(11,35),(14,39),(13,47),(0,47)], "stone")
    p(d, [(17,32),(30,30),(33,34),(32,47),(16,47),(15,40)], "shade")
    p(d, [(36,32),(47,31),(47,47),(35,47),(34,37)], "under")
    # One diffuse moonlit patch across the top-left, not every brick top.
    p(d, [(0,0),(16,0),(21,3),(18,7),(0,7)], "mid")
    p(d, [(0,1),(12,1),(15,3),(13,4),(0,4)], "lit")
    l(d, [(0,0),(8,0)], "edge")
    r(d, (4,8,13,9), "mid")
    # Localized bevel only where edges genuinely catch light.
    l(d, [(23,17),(33,16),(41,17)], "mid", 2)
    l(d, [(2,37),(8,36)], "mid")
    # Recessed faces and two coherent impact cracks; no stochastic specks.
    l(d, [(2,12),(11,13),(17,13)], "under")
    l(d, [(29,11),(39,12),(44,12)], "under")
    l(d, [(2,31),(11,32),(14,31)], "void")
    l(d, [(23,26),(30,25),(33,27)], "under")
    l(d, [(17,23),(13,24),(12,27),(9,28)], "joint")
    l(d, [(13,24),(14,21)], "joint")
    l(d, [(39,20),(37,22),(38,25)], "under")
    l(d, [(38,25),(35,26)], "under")
    r(d, (38,4,42,5), "stone")
    r(d, (40,6,41,6), "mid")
    r(d, (20,38,25,39), "stone")
    return im


def floor_b():
    im, d = img()
    # A quieter offset composition; lower-left deliberately remains broad.
    p(d, [(0,0),(13,0),(17,2),(18,15),(14,17),(0,16)], "shade")
    p(d, [(21,0),(47,0),(47,15),(45,18),(30,16),(21,13)], "stone")
    p(d, [(0,19),(18,19),(20,22),(18,34),(0,34)], "stone")
    p(d, [(23,20),(41,19),(47,21),(47,31),(42,34),(25,34),(21,30)], "under")
    p(d, [(0,37),(19,37),(20,39),(19,47),(0,47)], "shade")
    p(d, [(23,37),(47,36),(47,47),(22,47)], "stone")
    # This metatile is mostly unlit; a short angled sliver suggests worn relief.
    p(d, [(23,1),(38,1),(43,4),(39,5),(23,4)], "mid")
    l(d, [(26,2),(34,2)], "lit")
    l(d, [(2,20),(10,20)], "mid")
    l(d, [(26,38),(36,38)], "mid")
    l(d, [(1,15),(11,16),(15,16)], "under")
    l(d, [(23,13),(32,15),(44,16)], "under")
    l(d, [(2,33),(15,33)], "under")
    l(d, [(24,33),(42,33)], "void")
    l(d, [(11,21),(12,23),(10,26),(13,29)], "under")
    l(d, [(12,23),(15,22)], "under")
    # Edge-only moss grows inside one joint, not across the combat field.
    p(d, [(0,35),(0,31),(2,29),(5,30),(7,32),(8,36),(6,39),(1,38)], "moss0")
    p(d, [(0,34),(2,31),(4,31),(6,34),(5,37),(1,36)], "moss1")
    r(d, (2,32,3,32), "moss2")
    r(d, (5,34,6,34), "moss2")
    r(d, (31,25,35,26), "shade")
    return im


def floor_quiet():
    """Central combat floor: two long calm slabs, minimal value chatter."""
    im, d = img("under")
    p(d, [(0,0),(29,0),(31,2),(30,15),(26,18),(0,17)], "shade")
    p(d, [(33,0),(47,0),(47,20),(43,22),(32,21)], "stone")
    p(d, [(0,20),(26,21),(29,23),(27,47),(0,47)], "stone")
    p(d, [(31,25),(44,24),(47,27),(47,47),(30,47)], "shade")
    # One broad tonal plane, no bevel loop around every stone.
    p(d, [(0,0),(15,0),(20,2),(20,5),(0,5)], "stone")
    l(d, [(0,16),(17,17),(25,17)], "joint")
    l(d, [(3,45),(18,45)], "shade")
    l(d, [(33,20),(42,21)], "under")
    r(d, (7,9,13,10), "stone")
    r(d, (34,35,39,35), "stone")
    return im


def floor_quiet_b():
    """A second open-area composition with diagonal mass and sparse relief."""
    im, d = img("under")
    p(d, [(0,0),(15,0),(18,3),(17,27),(13,30),(0,29)], "stone")
    p(d, [(20,0),(47,0),(47,14),(42,17),(21,18),(19,15)], "shade")
    p(d, [(21,21),(41,20),(47,23),(47,47),(24,47),(20,42)], "stone")
    p(d, [(0,33),(16,32),(19,36),(19,47),(0,47)], "shade")
    # Unequal seam lengths and one low contrast interior color island.
    p(d, [(22,22),(36,22),(35,26),(23,27)], "mid")
    p(d, [(1,2),(11,1),(15,4),(14,7),(0,7)], "mid")
    l(d, [(2,28),(12,29)], "under")
    l(d, [(23,17),(40,16)], "under")
    l(d, [(23,42),(27,45),(42,45)], "under")
    r(d, (4,14,10,14), "shade")
    r(d, (29,33,35,33), "shade")
    return im


def floor_quiet_c():
    """Wide diagonal stone mass; deliberately avoids full-width grout lines."""
    im, d = img("shade")
    p(d, [(3,2),(28,2),(34,7),(36,20),(28,26),(8,26),(2,19)], "stone")
    p(d, [(17,30),(30,28),(44,32),(46,43),(38,46),(20,44)], "under")
    p(d, [(3,30),(14,29),(17,34),(15,42),(3,44)], "under")
    p(d, [(32,3),(45,5),(46,16),(39,20),(36,18)], "under")
    # Large quiet interior catches only one small moon patch.
    p(d, [(7,5),(19,5),(26,9),(22,11),(8,10)], "mid")
    l(d, [(8,6),(17,6)], "lit")
    l(d, [(35,8),(41,10),(43,14)], "joint")
    l(d, [(28,24),(31,21),(35,22)], "under")
    l(d, [(20,40),(28,42),(34,41)], "joint")
    r(d, (12,18,17,18), "mid")
    return im


def floor_quiet_d():
    """Asymmetric broad planes; opposing seam direction to quiet C."""
    im, d = img("shade")
    p(d, [(3,3),(17,3),(22,9),(20,28),(14,31),(3,28)], "under")
    p(d, [(25,4),(44,3),(45,22),(39,27),(27,24),(23,16)], "stone")
    p(d, [(3,34),(15,33),(25,30),(37,32),(45,39),(44,45),(3,45)], "stone")
    p(d, [(28,5),(37,5),(41,8),(37,9),(28,9)], "mid")
    l(d, [(27,5),(35,5)], "lit")
    l(d, [(18,27),(20,29),(24,30)], "joint")
    l(d, [(8,39),(16,38),(21,39)], "mid")
    l(d, [(38,31),(41,34),(43,35)], "under")
    r(d, (32,17,37,17), "shade")
    return im


def floor_worn():
    """Broken flagstone with grouped chips, used sparingly along the room rim."""
    im, d = img()
    p(d, [(0,0),(18,0),(19,3),(16,14),(0,15)], "stone")
    p(d, [(21,0),(47,0),(47,13),(43,17),(25,15),(19,12)], "shade")
    p(d, [(0,18),(13,17),(17,19),(15,31),(9,34),(0,32)], "under")
    p(d, [(20,19),(41,20),(47,18),(47,33),(38,34),(24,31),(19,28)], "stone")
    p(d, [(0,36),(12,35),(16,39),(14,47),(0,47)], "shade")
    p(d, [(18,36),(36,35),(47,37),(47,47),(17,47)], "under")
    # Impact removes a corner, exposing the dark joint and a pale chip rim.
    p(d, [(25,13),(30,12),(32,15),(30,18),(24,17)], "joint")
    l(d, [(23,13),(25,14),(29,13)], "lit")
    l(d, [(30,18),(34,21),(32,25)], "joint")
    l(d, [(34,21),(38,19)], "joint")
    p(d, [(8,18),(14,18),(17,20),(12,22),(5,21)], "mid")
    l(d, [(3,20),(11,19)], "lit")
    l(d, [(20,29),(27,31),(37,33)], "under")
    r(d, (4,5,9,6), "mid")
    r(d, (40,4,44,5), "stone")
    r(d, (29,42,34,42), "shade")
    return im


def floor_wet():
    """Low-contrast damp stone beside water; no reflection/interaction promise."""
    im, d = img("under")
    p(d, [(0,0),(23,0),(25,3),(24,18),(0,17)], "shade")
    p(d, [(28,0),(47,0),(47,14),(45,18),(28,19)], "stone")
    p(d, [(0,21),(16,20),(20,22),(18,47),(0,47)], "stone")
    p(d, [(23,23),(47,21),(47,47),(22,47)], "shade")
    # Dampness is a grouped cooler region that follows the bottom-left joint.
    p(d, [(0,29),(9,26),(17,28),(15,38),(21,47),(0,47)], "wet0")
    p(d, [(0,33),(7,29),(14,31),(13,37),(18,45),(0,47)], "wet1")
    p(d, [(0,34),(4,32),(11,32),(9,34),(1,36)], "wet2")
    l(d, [(2,16),(11,17),(20,17)], "under")
    l(d, [(29,18),(38,17),(45,18)], "under")
    l(d, [(24,44),(42,44)], "under")
    r(d, (32,7,39,8), "mid")
    return im


def wall(lit=True):
    im, d = img("void")
    # 0–15: physical coping slab; not a floating one-pixel outline.
    p(d, [(0,0),(47,0),(47,12),(45,14),(3,14),(0,12)], "shade")
    p(d, [(0,0),(47,0),(47,4),(42,5),(0,5)], "edge")
    if lit:
        p(d, [(1,1),(31,1),(33,3),(30,4),(1,4)], "chip")
    else:
        p(d, [(1,1),(18,1),(21,3),(20,4),(1,4)], "lit")
    p(d, [(2,6),(45,6),(46,10),(44,12),(2,12)], "stone")
    p(d, [(4,7),(19,7),(18,9),(4,9)], "mid")
    l(d, [(30,8),(41,8)], "mid")
    l(d, [(0,13),(21,14),(45,14)], "void", 2)
    # 16–31: recessed upper wall, staggered stones and light-catching corner.
    p(d, [(0,16),(47,16),(47,32),(0,32)], "under")
    p(d, [(0,16),(28,16),(30,18),(29,30),(0,30)], "stone")
    p(d, [(33,17),(47,16),(47,30),(32,31)], "shade")
    p(d, [(0,17),(21,17),(23,18),(22,19),(0,19)], "mid")
    l(d, [(32,17),(42,17)], "mid")
    l(d, [(29,18),(29,28)], "void")
    l(d, [(2,28),(17,29)], "under")
    l(d, [(36,26),(45,26)], "under")
    # 32–47: projecting plinth/base and a strong contact shadow at floor.
    p(d, [(0,33),(47,33),(47,46),(0,46)], "shade")
    p(d, [(0,33),(47,33),(47,37),(44,38),(0,38)], "mid")
    if lit:
        l(d, [(1,34),(32,34)], "lit")
    else:
        l(d, [(2,34),(13,34)], "mid")
    l(d, [(0,39),(20,39),(22,41)], "under")
    p(d, [(0,41),(19,41),(21,43),(20,46),(0,46)], "stone")
    p(d, [(24,40),(47,40),(47,46),(23,46)], "under")
    l(d, [(0,46),(47,46)], "void", 2)
    return im


def wall_border():
    """4x3 single-cell border atlas matching the current one-cell room loop.

    Row 0: north A/B, north-west, north-east. Row 1: south A/B,
    south-west, south-east. Row 2: west A/B, east A/B. Every tile is an
    independently editable 16x16 source cell with no baked light or fire.
    """
    sheet = Image.new("RGBA", (64, 48), P["void"])

    def north(variant):
        im = Image.new("RGBA", (16, 16), P["void"])
        d = ImageDraw.Draw(im)
        # Moonlit coping, recessed block face, projecting contact plinth.
        d.polygon([(0,0),(15,0),(15,3),(14,4),(0,4)], fill=P["shade"])
        d.rectangle((0,0,15,1), fill=P["edge"])
        d.line([(1,0),(9 if variant == 0 else 5,0)], fill=P["chip"])
        d.rectangle((0,4,15,9), fill=P["stone"])
        d.rectangle((0,5,15,5), fill=P["mid"])
        joint_x = 11 if variant == 0 else 4
        d.line([(joint_x,5),(joint_x,8)], fill=P["under"])
        d.rectangle((0,10,15,12), fill=P["shade"])
        d.rectangle((0,13,15,14), fill=P["mid"])
        d.line([(0,13),(8 if variant == 0 else 4,13)], fill=P["lit"])
        d.rectangle((0,15,15,15), fill=P["void"])
        return im

    def south(variant):
        im = Image.new("RGBA", (16, 16), P["void"])
        d = ImageDraw.Draw(im)
        # Foreground parapet: in-room contact first, then its raised face.
        d.rectangle((0,0,15,1), fill=P["void"])
        d.rectangle((0,2,15,5), fill=P["edge"])
        d.line([(1,2),(10 if variant == 0 else 6,2)], fill=P["chip"])
        d.rectangle((0,6,15,12), fill=P["stone"])
        d.line([(0,6),(15,6)], fill=P["mid"])
        joint_x = 5 if variant == 0 else 12
        d.line([(joint_x,7),(joint_x,11)], fill=P["under"])
        d.rectangle((0,13,15,14), fill=P["shade"])
        d.line([(2,13),(8,13)], fill=P["mid"])
        return im

    def west(variant):
        im = Image.new("RGBA", (16, 16), P["void"])
        d = ImageDraw.Draw(im)
        # Outer spine at left, interior contact shadow at right.
        d.rectangle((0,0,3,15), fill=P["shade"])
        d.rectangle((0,0,1,15), fill=P["edge"])
        d.rectangle((4,0,10,15), fill=P["stone"])
        d.line([(5,0),(5,15)], fill=P["mid"])
        d.rectangle((11,0,13,15), fill=P["under"])
        d.rectangle((14,0,15,15), fill=P["void"])
        seam_y = 5 if variant == 0 else 11
        d.line([(4,seam_y),(10,seam_y)], fill=P["under"])
        d.line([(1,seam_y+1),(3,seam_y+1)], fill=P["lit"])
        return im

    def east(variant):
        im = west(variant).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        return im

    def corner(north_side, east_side):
        im = north(0) if north_side else south(0)
        d = ImageDraw.Draw(im)
        # A thick squared corner post conceals the stripe termination.
        if east_side:
            d.rectangle((10,0,15,15), fill=P["shade"])
            d.rectangle((11,1,14,3), fill=P["edge"])
            d.line([(11,5),(11,12)], fill=P["under"])
            d.line([(13,6),(13,10)], fill=P["mid"])
        else:
            d.rectangle((0,0,5,15), fill=P["shade"])
            d.rectangle((1,1,4,3), fill=P["edge"])
            d.line([(4,5),(4,12)], fill=P["under"])
            d.line([(2,6),(2,10)], fill=P["mid"])
        d.rectangle((1 if not east_side else 10, 14,
                     5 if not east_side else 14, 15), fill=P["void"])
        return im

    layout = (
        (north(0), north(1), corner(True, False), corner(True, True)),
        (south(0), south(1), corner(False, False), corner(False, True)),
        (west(0), west(1), east(0), east(1)),
    )
    for row, tiles in enumerate(layout):
        for col, tile in enumerate(tiles):
            sheet.alpha_composite(tile, (col * 16, row * 16))
    return sheet


