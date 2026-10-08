"""FoxKnight E: native-grid, hand-authored character color clusters.

This source draws directly in the low-resolution grid. It does not load or
downsample concept art or old character sprites. Run after reviewing changes;
outputs in this directory are rebuilt from this file.
"""

from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent
SIZE = (40, 40)
ANCHOR = (20, 35)
P = {
    "edge": "#29212b", "deep": "#4b2a32",
    "fur_dark": "#a54829", "fur": "#df6f31", "fur_lit": "#f49341", "fur_peak": "#ffae55",
    "inner_ear": "#f3ca93", "cream_dark": "#c4a17d", "cream": "#ead0a2",
    "cream_lit": "#fff0cb", "cream_white": "#fff9e7", "eye": "#231e28", "iris": "#a65c38",
    "scarf_dark": "#482536", "scarf": "#783246", "scarf_lit": "#a74e5a",
    "steel_dark": "#4b5662", "steel": "#83939d", "steel_lit": "#bdc7c5",
    "blade": "#dbe1d7", "guard": "#b89959",
}


def canvas():
    im = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Four transparent columns and two transparent rows give the same-size
    # body extra native space for the raised tail and short sword.
    def at(pts): return [(x+4,y+2) for x,y in pts]
    def poly(c, *pts): d.polygon(at(pts), fill=P[c])
    def line(c, pts, w=1): d.line(at(pts), fill=P[c], width=w)
    def pix(c, x, y): d.point((x+4,y+2), fill=P[c])
    return im, poly, line, pix


def draw_fox_front():
    im, q, l, p = canvas()
    # Plump tail, feet and armoured body behind the head.
    q("edge", (23,25),(27,21),(30,18),(34,16),(36,18),(35,23),(32,26),(27,29),(22,28))
    q("fur_dark", (24,25),(28,21),(31,18),(34,17),(35,19),(34,23),(31,25),(27,27))
    q("fur", (25,24),(29,20),(32,18),(34,18),(34,22),(30,25),(26,27))
    q("cream_dark", (32,18),(35,17),(35,21),(33,23),(31,21))
    q("cream", (33,18),(35,18),(34,21),(32,22),(31,20))
    q("cream_lit", (34,18),(34,20),(33,21))
    # Chest, split legs, boot caps and grounded orange paws.
    q("edge", (11,24),(23,24),(25,28),(24,31),(23,34),(18,34),
      (17,31),(16,34),(10,34),(9,31))
    q("steel_dark", (12,25),(22,25),(23,29),(21,31),(19,31),
      (18,29),(16,29),(15,31),(11,31),(10,29))
    q("steel", (13,25),(21,25),(22,28),(19,29),(13,29))
    q("steel_lit", (15,26),(20,26),(20,27),(15,27))
    l("deep", [(12,29),(22,29)],2)
    p("guard",18,29)
    q("steel", (10,30),(15,30),(15,32),(11,32))
    q("steel", (19,30),(23,30),(23,32),(19,32))
    q("fur_dark", (10,32),(16,32),(16,34),(9,34))
    q("fur_dark", (19,32),(24,32),(25,34),(18,34))
    q("fur_lit", (10,33),(15,33),(15,34),(10,34))
    q("fur_lit", (19,33),(23,33),(24,34),(19,34))
    # Ear tips are unequal; their warm inner planes are clear at game scale.
    q("edge", (8,11),(7,6),(8,2),(10,2),(14,8),(14,12))
    q("fur", (9,9),(9,4),(10,3),(13,8),(13,11))
    q("inner_ear", (10,8),(10,5),(11,5),(12,8))
    q("edge", (20,10),(23,4),(26,2),(27,4),(27,10),(24,13))
    q("fur", (22,9),(24,5),(26,3),(26,10),(23,12))
    q("inner_ear", (23,8),(25,5),(25,9))
    # Rounded, gently tilted forehead and cheek silhouette.
    q("edge", (12,9),(17,8),(22,9),(26,12),(27,16),(28,18),
      (26,21),(22,23),(14,23),(9,21),(6,18),(8,15),(8,12))
    q("fur_dark", (12,10),(17,9),(22,10),(25,12),(26,16),(26,19),
      (22,22),(13,22),(8,19),(8,14))
    q("fur", (12,11),(18,10),(23,11),(25,14),(25,17),(22,21),
      (13,21),(9,18),(9,14))
    q("fur_lit", (13,11),(17,10),(21,11),(24,13),(23,17),(20,18),
      (12,16),(10,14))
    q("fur_peak", (16,11),(20,11),(22,12),(16,12))
    # Cheeks are separate lobes; little orange wedges interrupt the cream.
    q("cream_dark", (7,16),(11,16),(14,18),(15,21),(12,22),(8,20),(6,18))
    q("cream", (7,17),(10,16),(13,18),(14,20),(11,21),(8,19))
    q("cream_lit", (8,17),(11,17),(12,19),(10,20))
    q("cream_dark", (22,18),(25,16),(27,17),(29,19),(25,22),(21,22),(20,20))
    q("cream", (23,18),(26,17),(28,19),(25,21),(22,21))
    q("cream_lit", (25,17),(27,19),(24,20))
    q("fur", (14,17),(16,18),(15,20)); q("fur", (22,17),(21,19),(20,18))
    q("cream", (14,19),(17,18),(21,19),(23,21),(21,22),(16,22),(14,21))
    q("cream_lit", (16,19),(18,18),(20,19),(21,21),(17,21))
    # Alert warm eyes, a tiny offset nose and modest smile.
    l("fur_dark", [(11,14),(13,13),(15,14)])
    l("fur_dark", [(21,14),(23,13),(25,15)])
    q("eye", (12,15),(13,14),(14,15),(14,17),(13,18),(12,17))
    p("iris",13,16); p("cream_lit",12,15)
    q("eye", (22,15),(23,14),(24,15),(24,17),(23,18),(22,17))
    p("iris",23,16); p("cream_lit",22,15)
    q("eye", (17,19),(19,19),(20,20),(19,21),(18,21))
    p("steel_dark",18,19)
    l("deep", [(19,21),(18,22),(16,22)])
    # Diagonal scarf, one small shoulder guard, visible orange hands.
    q("scarf_dark", (11,22),(17,23),(23,22),(25,23),(23,26),(18,27),(12,25))
    q("scarf", (11,23),(17,24),(23,23),(23,25),(18,26),(12,24))
    l("scarf_lit", [(12,23),(17,25),(22,24)])
    q("scarf_dark", (12,24),(15,26),(13,29),(9,31),(9,28))
    q("scarf", (11,26),(13,27),(11,29),(10,29))
    l("scarf_lit", [(12,26),(11,28)])
    q("edge", (8,23),(11,22),(13,24),(12,28),(8,28),(7,26))
    q("steel", (8,24),(10,23),(12,25),(11,27),(8,27))
    p("steel_lit",9,24)
    q("edge", (23,25),(27,25),(29,28),(28,30),(24,30),(22,28))
    q("fur", (24,26),(27,26),(28,28),(27,29),(24,28))
    q("fur_lit", (25,26),(27,27),(27,28))
    # Short sword held low; attack trail will remain a separate FX resource.
    l("edge", [(27,28),(29,30)],3)
    l("guard", [(27,29),(30,27)],2)
    l("edge", [(29,29),(36,34)],3)
    l("blade", [(30,29),(36,34)],1)
    return im


def draw_fox_side():
    im, q, l, p = canvas()
    # Tail sweeps opposite the forward muzzle.
    q("edge", (13,25),(9,23),(4,21),(1,17),(-2,18),(-3,22),
      (0,26),(5,29),(11,29),(15,27))
    q("fur_dark", (12,25),(7,23),(3,21),(0,19),(-2,20),(-1,23),
      (3,26),(8,28),(12,27))
    q("fur", (11,24),(6,23),(2,21),(0,20),(0,23),(4,26),(9,27),(12,26))
    q("cream_dark", (1,18),(-2,19),(-2,23),(1,24),(3,22))
    q("cream", (0,19),(-2,20),(-1,22),(1,23),(2,21))
    q("cream_lit", (-1,20),(0,21))
    q("edge", (13,25),(23,25),(25,29),(24,34),(19,34),(18,31),
      (17,31),(16,34),(11,34),(10,30))
    q("steel_dark", (13,26),(22,26),(23,29),(20,31),(13,31),(11,29))
    q("steel", (15,26),(22,27),(21,29),(15,29))
    l("deep", [(13,29),(22,29)],2)
    p("guard",18,29)
    q("steel", (11,30),(15,30),(15,32),(11,32))
    q("steel", (19,30),(23,30),(23,32),(19,32))
    q("fur_dark", (11,32),(16,32),(16,34),(10,34))
    q("fur_dark", (19,32),(24,32),(25,34),(19,34))
    q("fur_lit", (11,33),(15,33),(15,34),(11,34))
    q("fur_lit", (19,33),(23,33),(24,34),(19,34))
    q("edge", (11,12),(10,5),(12,2),(15,5),(17,11))
    q("fur", (12,10),(12,5),(14,5),(16,10))
    q("inner_ear", (13,7),(14,6),(15,9))
    q("edge", (18,10),(20,4),(23,2),(25,4),(24,12))
    q("fur", (20,9),(22,4),(24,5),(23,11))
    q("inner_ear", (22,7),(23,5),(23,9))
    q("edge", (13,9),(19,8),(24,10),(27,13),(27,16),
      (30,17),(29,20),(25,22),(15,23),(10,20),(9,15))
    q("fur_dark", (13,10),(19,9),(24,11),(26,14),(27,18),
      (24,21),(15,22),(11,19),(10,15))
    q("fur", (14,11),(20,10),(24,12),(26,15),(26,18),
      (22,20),(14,21),(11,18),(11,14))
    q("fur_lit", (14,12),(18,10),(22,11),(25,14),(23,17),(16,18),(12,15))
    q("fur_peak", (18,11),(21,11),(22,12))
    # Prominent lobe flows toward a truly short profile muzzle.
    q("cream_dark", (11,16),(15,16),(18,18),(24,17),(29,18),
      (27,21),(22,23),(15,22),(11,20))
    q("cream", (11,17),(15,17),(18,19),(24,18),(28,18),
      (26,21),(21,22),(15,21),(12,19))
    q("cream_lit", (15,18),(19,19),(25,18),(27,19),(23,21),(17,20))
    q("fur", (16,16),(18,17),(18,19),(16,18))
    l("fur_dark", [(21,14),(23,13),(25,15)])
    q("eye", (21,15),(23,14),(24,16),(24,18),(22,18),(21,17))
    p("iris",23,16); p("cream_lit",22,15)
    q("eye", (28,18),(29,18),(30,19),(29,20),(28,19))
    l("deep", [(28,20),(26,21),(24,21)])
    q("scarf_dark", (13,22),(23,22),(26,23),(24,26),(18,27),(13,25))
    q("scarf", (14,23),(23,23),(24,25),(19,26),(14,24))
    l("scarf_lit", [(14,23),(20,24),(23,24)])
    q("scarf_dark", (12,24),(15,26),(13,29),(9,30),(10,27))
    l("scarf_lit", [(12,25),(11,28)])
    q("edge", (13,23),(16,22),(18,24),(17,28),(13,28))
    q("steel", (14,23),(16,23),(17,25),(16,27),(14,27))
    p("steel_lit",15,24)
    q("edge", (23,25),(27,25),(29,28),(28,30),(24,30),(22,28))
    q("fur", (24,26),(27,26),(28,28),(27,29),(24,28))
    l("edge", [(27,28),(29,30)],3)
    l("guard", [(27,29),(30,27)],2)
    l("edge", [(29,29),(36,34)],3)
    l("blade", [(30,29),(36,34)])
    return im


def draw_fox_back():
    im, q, l, p = canvas()
    q("edge", (22,25),(27,21),(30,18),(34,16),(36,18),(35,23),
      (32,26),(27,30),(21,29))
    q("fur_dark", (23,25),(28,21),(31,18),(34,17),(35,19),
      (34,23),(31,25),(26,28))
    q("fur", (24,24),(29,20),(32,18),(34,18),(34,22),(30,25),(25,27))
    q("cream_dark", (32,18),(35,17),(35,21),(33,23),(31,21))
    q("cream", (33,18),(35,18),(34,21),(32,22),(31,20))
    q("edge", (11,25),(23,25),(25,29),(24,34),(19,34),(18,31),
      (17,31),(16,34),(10,34),(9,30))
    q("steel_dark", (12,26),(22,26),(23,29),(21,31),(12,31),(10,29))
    q("steel", (14,26),(21,26),(22,29),(14,29))
    l("deep", [(12,29),(22,29)],2)
    q("steel", (10,30),(15,30),(15,32),(10,32))
    q("steel", (19,30),(23,30),(23,32),(19,32))
    q("fur_dark", (10,32),(16,32),(16,34),(10,34))
    q("fur_dark", (19,32),(24,32),(25,34),(19,34))
    q("fur_lit", (11,33),(15,33),(15,34),(11,34))
    q("fur_lit", (19,33),(23,33),(24,34),(19,34))
    q("edge", (8,12),(7,5),(10,2),(14,9),(14,13))
    q("fur", (9,10),(9,5),(10,4),(13,10))
    q("edge", (20,11),(23,4),(26,2),(28,5),(27,12))
    q("fur", (22,10),(25,4),(26,5),(26,11))
    q("edge", (10,10),(17,8),(23,9),(27,13),(28,19),(25,23),(12,23),(8,19),(8,14))
    q("fur_dark", (11,11),(17,9),(22,10),(26,14),(27,19),(24,22),(12,22),(9,18),(9,14))
    q("fur", (12,11),(18,10),(22,11),(25,15),(25,19),(22,21),(13,21),(10,18),(10,14))
    q("fur_lit", (15,11),(18,10),(21,11),(22,13),(18,15),(13,13))
    q("cream_dark", (9,18),(12,19),(13,21),(10,20))
    q("cream", (9,18),(11,18),(12,20))
    q("cream_dark", (25,18),(27,18),(27,20),(24,21))
    q("cream", (25,18),(27,19),(25,20))
    q("scarf_dark", (11,22),(24,22),(26,24),(24,27),(14,27),(10,25))
    q("scarf", (11,23),(24,23),(25,25),(22,26),(13,26),(11,24))
    l("scarf_lit", [(14,23),(21,23),(24,25)])
    q("scarf_dark", (18,26),(22,28),(26,31),(25,32),(21,29),(17,28))
    l("scarf_lit", [(20,27),(24,30)])
    q("steel_dark", (8,23),(11,22),(13,26),(11,28),(8,27))
    q("steel", (8,24),(10,23),(12,26),(10,27),(8,26))
    q("steel_dark", (24,23),(27,23),(28,27),(25,28),(23,26))
    q("steel", (25,24),(27,24),(27,26),(25,27))
    return im


def draw_fox_left():
    # The authored side silhouette faces right; the left-facing study mirrors
    # the body and keeps the scarf/weapon visible on the near side. Weapon hand
    # consistency will be checked in animation and game motion review.
    return draw_fox_side().transpose(Image.Transpose.FLIP_LEFT_RIGHT)


def render_studies():
    frames = {
        "front": draw_fox_front(), "side": draw_fox_side(),
        "back": draw_fox_back(), "left": draw_fox_left(),
    }
    for direction, frame in frames.items():
        assert frame.size == SIZE
        assert set(frame.tobytes()[3::4]) <= {0,255}
        frame.save(ROOT / f"e_fox_{direction}_native.png")
        frame.resize((SIZE[0]*2,SIZE[1]*2), Image.Resampling.NEAREST).save(
            ROOT / f"e_fox_{direction}_world2x.png")
    contact = Image.new("RGBA", (SIZE[0]*4,SIZE[1]), (0,0,0,0))
    for i,direction in enumerate(("front","side","back","left")):
        contact.alpha_composite(frames[direction],(i*SIZE[0],0))
    contact.resize((SIZE[0]*16,SIZE[1]*4),Image.Resampling.NEAREST).save(ROOT / "e_fox_four_directions_review4x.png")
    scene_path = ROOT.parents[4] / "output" / "ui_production_level_01.png"
    if scene_path.exists():
        scene = Image.open(scene_path).convert("RGBA")
        # Native 2x sprites are placed by the same foot anchor used in Godot.
        # Original fox and enemies remain visible for a truthful size comparison.
        for direction, foot_x in zip(("front","side","back","left"), (342,410,478,546)):
            enlarged = frames[direction].resize((SIZE[0]*2,SIZE[1]*2),Image.Resampling.NEAREST)
            scene.alpha_composite(enlarged,(foot_x-ANCHOR[0]*2,264-ANCHOR[1]*2))
        scene.save(ROOT / "e_fox_level01_size_review.png")
    return frames


if __name__ == "__main__":
    render_studies()
